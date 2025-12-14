import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '../../../models/brand_model.dart';
import '../../../services/admin/brand_service.dart';

class AdminBrandForm extends StatefulWidget {
  final BrandModel? brand;
  const AdminBrandForm({Key? key, this.brand}) : super(key: key);

  @override
  State<AdminBrandForm> createState() => _AdminBrandFormState();
}

class _AdminBrandFormState extends State<AdminBrandForm> {
  final _formKey = GlobalKey<FormState>();
  final BrandService _brandService = BrandService();

  late TextEditingController _nameController;
  bool _isArchived = false;
  bool _isSaving = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    final brand = widget.brand;
    _nameController = TextEditingController(text: brand?.name ?? '');
    _isArchived = brand?.is_archived ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
          message = 'Brand name is required';
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
      case 1: // Settings step
        return true; // Settings are optional
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

  // Step 1: Basic Information
  Widget _buildBasicInfoStep() {
    return _buildSectionCard(
      title: 'Basic Information',
      child: Column(
        children: [
          _buildTextField(
            _nameController,
            'Brand Name',
            icon: Icons.storefront,
            required: true,
          ),
        ],
      ),
    );
  }

  // Step 2: Settings
  Widget _buildSettingsStep() {
    return _buildSectionCard(
      title: 'Settings',
      child: Column(
        children: [
          // Archived Switch
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SwitchListTile(
              title: Row(
                children: [
                  Icon(
                    _isArchived ? Icons.unarchive : Icons.archive,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Archived',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              value: _isArchived,
              onChanged: (val) => setState(() => _isArchived = val),
              activeColor: Colors.orange.shade600,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBrand() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final id =
        widget.brand?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final brand = BrandModel(
      id: id,
      name: _nameController.text.trim(),
      is_archived: _isArchived,
      created_at: widget.brand?.created_at ?? DateTime.now(),
      updated_at: DateTime.now(),
    );

    try {
      if (widget.brand == null) {
        await _brandService.createBrand(brand);
      } else {
        await _brandService.updateBrand(brand);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.brand == null
                ? 'Brand created successfully!'
                : 'Brand updated successfully!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save brand')));
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
        title: const Text('Settings'),
        content: _buildSettingsStep(),
        isActive: _currentStep >= 1,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
    ];

    return AdminLayout(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.brand == null ? 'Create Brand' : 'Edit Brand',
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
                  _currentStep == steps.length - 1 ? _saveBrand : _nextStep,
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
                                    ? (widget.brand == null
                                        ? 'Create Brand'
                                        : 'Update Brand')
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
