import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/supplier_model.dart';
import '/services/admin/supplier_service.dart';

class AdminSupplierForm extends StatefulWidget {
  final SupplierModel? supplier;
  const AdminSupplierForm({Key? key, this.supplier}) : super(key: key);

  @override
  State<AdminSupplierForm> createState() => _AdminSupplierFormState();
}

class _AdminSupplierFormState extends State<AdminSupplierForm> {
  final _formKey = GlobalKey<FormState>();
  final SupplierService _supplierService = SupplierService();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  late TextEditingController _contactPersonController;

<<<<<<< HEAD
  bool _isSaving = false;
  int _currentStep = 0;
=======
  bool _isArchived = false;
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

  @override
  void initState() {
    super.initState();

    final supplier = widget.supplier;

    _nameController = TextEditingController(text: supplier?.name ?? '');
    _addressController = TextEditingController(text: supplier?.address ?? '');
    _contactController = TextEditingController(text: supplier?.contact ?? '');
    _contactPersonController =
        TextEditingController(text: supplier?.contact_person ?? '');
<<<<<<< HEAD
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _contactPersonController.dispose();
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
          message = 'Supplier name is required';
        }
        break;
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Basic Info step
        return _nameController.text.isNotEmpty;
      case 1: // Contact Details step
        return _contactController.text.isNotEmpty &&
            _contactPersonController.text.isNotEmpty;
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
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
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
        fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
      ),
      validator: validator ??
          (value) {
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
            'Supplier Name',
            icon: Icons.business,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _addressController,
            'Address',
            icon: Icons.location_on,
            maxLines: 3,
            required: true,
          ),
        ],
      ),
    );
  }

  // Step 2: Contact Details
  Widget _buildContactDetailsStep() {
    return _buildSectionCard(
      title: 'Contact Details',
      child: Column(
        children: [
          _buildTextField(
            _contactController,
            'Contact Number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _contactPersonController,
            'Contact Person',
            icon: Icons.person,
            required: true,
          ),
          const SizedBox(height: 16),
          // Container(
          //   decoration: BoxDecoration(
          //     color: Colors.grey.shade50,
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(color: Colors.grey.shade300),
          //   ),
          //   child: SwitchListTile(
          //     title: const Text('Archived'),
          //     subtitle: const Text('Hide this supplier from active lists'),
          //     value: _isArchived,
          //     onChanged: (val) => setState(() => _isArchived = val),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(12),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
=======

    _isArchived = supplier?.is_archived ?? false;
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

<<<<<<< HEAD
    setState(() => _isSaving = true);

    try {
      final id = widget.supplier?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final supplier = SupplierModel(
        id: id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        contact: _contactController.text.trim(),
        contact_person: _contactPersonController.text.trim(),
        is_archived: false,
        created_at: widget.supplier?.created_at ?? DateTime.now(),
        updated_at: DateTime.now(),
      );

      if (widget.supplier == null) {
        await _supplierService.createSupplier(supplier);
      } else {
        await _supplierService.updateSupplier(supplier);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.supplier == null
                ? 'Supplier created successfully!'
                : 'Supplier updated successfully!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save supplier')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
=======
    final id =
        widget.supplier?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final supplier = SupplierModel(
      id: id,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      contact: _contactController.text.trim(),
      contact_person: _contactPersonController.text.trim(),
      is_archived: _isArchived,
      created_at: widget.supplier?.created_at ?? DateTime.now(),
      updated_at: DateTime.now(),
    );

    if (widget.supplier == null) {
      await _supplierService.createSupplier(supplier);
    } else {
      await _supplierService.updateSupplier(supplier);
    }

    if (context.mounted) Navigator.pop(context);
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    List<Step> steps = [
      Step(
        title: const Text('Basic Info'),
        content: _buildBasicInfoStep(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Contact Details'),
        content: _buildContactDetailsStep(),
        isActive: _currentStep >= 1,
        state: StepState.indexed,
      ),
    ];

    return AdminLayout(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.supplier == null ? 'Create Supplier' : 'Edit Supplier',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.green.shade50,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade50,
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Form(
            key: _formKey,
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue:
                  _currentStep == steps.length - 1 ? _saveSupplier : _nextStep,
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
                                    ? (widget.supplier == null
                                        ? 'Create Supplier'
                                        : 'Update Supplier')
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
=======
    return AdminLayout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BACK BUTTON
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),

            const SizedBox(height: 8),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  // NAME
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Supplier Name'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // ADDRESS
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // CONTACT
                  TextFormField(
                    controller: _contactController,
                    decoration:
                        const InputDecoration(labelText: 'Contact Number'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // CONTACT PERSON
                  TextFormField(
                    controller: _contactPersonController,
                    decoration:
                        const InputDecoration(labelText: 'Contact Person'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  /// ARCHIVED SWITCH
                  SwitchListTile(
                    title: const Text('Archived'),
                    value: _isArchived,
                    onChanged: (val) => setState(() => _isArchived = val),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _saveSupplier,
                    child: Text(widget.supplier == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ),
          ],
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
        ),
      ),
    );
  }
}
