import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '../../../models/attribute_model.dart';
import '../../../models/attribute_value_model.dart';
import '../../../services/admin/attribute_service.dart';

class AdminAttributeForm extends StatefulWidget {
  final AttributeModel? attribute;
  const AdminAttributeForm({Key? key, this.attribute}) : super(key: key);

  @override
  State<AdminAttributeForm> createState() => _AdminAttributeFormState();
}

class _AdminAttributeFormState extends State<AdminAttributeForm> {
  final _formKey = GlobalKey<FormState>();
  final AttributeService _attributeService = AttributeService();

  late TextEditingController _nameController;
  bool _isSaving = false;
  int _currentStep = 0;

  // List of controllers for attribute values
  List<TextEditingController> _valueControllers = [];

  @override
  void initState() {
    super.initState();
    final attribute = widget.attribute;
    _nameController = TextEditingController(text: attribute?.name ?? '');

    // If editing an attribute, load existing values
    if (attribute != null) {
      _loadAttributeValues(attribute.id);
    } else {
      _addValueController(); // start with one empty field
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (var controller in _valueControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _loadAttributeValues(String attributeId) async {
    final values = await _attributeService.getAttributeValues(attributeId);
    setState(() {
      _valueControllers =
          values.map((v) => TextEditingController(text: v.name)).toList();
    });
  }

  void _addValueController() {
    setState(() {
      _valueControllers.add(TextEditingController());
    });
  }

  void _removeValueController(int index) {
    setState(() {
      if (_valueControllers.length > 1) {
        _valueControllers[index].dispose();
        _valueControllers.removeAt(index);
      }
    });
  }

  // Stepper navigation methods
  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 1) {
        setState(() => _currentStep++);
      }
    } else {
      _showValidationMessage();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _showValidationMessage() {
    if (!context.mounted) return;

    String message = '';
    switch (_currentStep) {
      case 0: // Basic Info step
        if (_nameController.text.isEmpty) {
          message = 'Attribute name is required';
        }
        break;
      case 1: // Values step
        if (_valueControllers
            .any((controller) => controller.text.trim().isEmpty)) {
          message = 'All attribute values must be filled';
        }
        break;
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Individual step validation
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Basic Info step
        if (_nameController.text.isEmpty) {
          return false;
        }
        return true;
      case 1: // Values step
        if (_valueControllers.isEmpty) {
          return false;
        }
        // Check if any value is empty
        if (_valueControllers
            .any((controller) => controller.text.trim().isEmpty)) {
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.green.shade200,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildAttributeValueField(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _valueControllers[index],
                decoration: InputDecoration(
                  labelText: 'Value ${index + 1}',
                  labelStyle: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.tag,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.green.shade400,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _valueControllers.length > 1
                    ? () => _removeValueController(index)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: Basic Information
  Widget _buildBasicInfoStep() {
    return _buildSectionCard(
      title: 'Basic Information',
      child: Column(
        children: [
          _buildTextField(
            _nameController,
            'Attribute Name',
            icon: Icons.label,
            required: true,
          ),
        ],
      ),
    );
  }

  // Step 2: Attribute Values
  Widget _buildValuesStep() {
    return _buildSectionCard(
      title: 'Attribute Values',
      child: Column(
        children: [
          // Dynamic value fields
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _valueControllers.length,
            itemBuilder: (context, index) {
              return _buildAttributeValueField(index);
            },
          ),
          const SizedBox(height: 16),

          // Add Value Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _addValueController,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.green.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add Value'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAttribute() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final attributeId = widget.attribute?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final attribute = AttributeModel(
      id: attributeId,
      name: _nameController.text.trim(),
      is_archived: false, // Default to false since we're removing the toggle
      created_at: widget.attribute?.created_at ?? DateTime.now(),
      updated_at: DateTime.now(),
    );

    try {
      if (widget.attribute == null) {
        await _attributeService.createAttribute(attribute);
      } else {
        await _attributeService.updateAttribute(attribute);
      }

      // Save attribute values
      for (var controller in _valueControllers) {
        final valueName = controller.text.trim();
        if (valueName.isEmpty) continue;

        final valueId = DateTime.now().millisecondsSinceEpoch.toString();
        final value = AttributeValueModel(
          id: valueId,
          attribute_id: attributeId,
          name: valueName,
          is_archived: false,
          created_at: DateTime.now(),
          updated_at: DateTime.now(),
        );

        await _attributeService.createAttributeValue(value);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.attribute == null
                ? 'Attribute created successfully!'
                : 'Attribute updated successfully!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save attribute')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Step> steps = [
      Step(
        title: const Text('Basic Info'),
        content: _buildBasicInfoStep(),
        isActive: _currentStep >= 0,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Values'),
        content: _buildValuesStep(),
        isActive: _currentStep >= 1,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
    ];

    return AdminLayout(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.attribute == null ? 'Create Attribute' : 'Edit Attribute',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.green.shade50,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade50!,
                Colors.white,
                Colors.grey.shade50!,
              ],
            ),
          ),
          child: Form(
            key: _formKey,
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue:
                  _currentStep == steps.length - 1 ? _saveAttribute : _nextStep,
              onStepCancel: _previousStep,
              onStepTapped: (step) {
                setState(() {
                  _currentStep = step;
                });
              },
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        ElevatedButton(
                          onPressed: details.onStepCancel,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isSaving ? null : details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _currentStep == steps.length - 1
                                    ? (widget.attribute == null
                                        ? 'Create Attribute'
                                        : 'Update Attribute')
                                    : 'Next',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                );
              },
              steps: steps,
            ),
          ),
        ),
      ),
    );
  }
}
