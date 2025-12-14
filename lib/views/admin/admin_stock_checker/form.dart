import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/stock_checker_model.dart';
import '/services/admin/stock_checker_service.dart';

class AdminStockCheckerForm extends StatefulWidget {
  final StockCheckerModel? checker;
  const AdminStockCheckerForm({Key? key, this.checker}) : super(key: key);

  @override
  State<AdminStockCheckerForm> createState() => _AdminStockCheckerFormState();
}

class _AdminStockCheckerFormState extends State<AdminStockCheckerForm> {
  final _formKey = GlobalKey<FormState>();
  final StockCheckerService _checkerService = StockCheckerService();

  late TextEditingController _firstnameController;
  late TextEditingController _middlenameController;
  late TextEditingController _lastnameController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;

  bool _isArchived = false;
  bool _isSaving = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    final checker = widget.checker;

    _firstnameController =
        TextEditingController(text: checker?.firstname ?? '');
    _middlenameController =
        TextEditingController(text: checker?.middlename ?? '');
    _lastnameController = TextEditingController(text: checker?.lastname ?? '');
    _addressController = TextEditingController(text: checker?.address ?? '');
    _contactController = TextEditingController(text: checker?.contact ?? '');

    _isArchived = checker?.is_archived ?? false;
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _middlenameController.dispose();
    _lastnameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // Stepper navigation methods
  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 2) {
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
      case 0: // Personal Info step
        if (_firstnameController.text.isEmpty) {
          message = 'First name is required';
        } else if (_lastnameController.text.isEmpty) {
          message = 'Last name is required';
        }
        break;
      case 1: // Contact Details step
        if (_contactController.text.isEmpty) {
          message = 'Contact number is required';
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
      case 0: // Personal Info step
        return _firstnameController.text.isNotEmpty &&
            _lastnameController.text.isNotEmpty;
      case 1: // Contact Details step
        return _contactController.text.isNotEmpty;
      case 2: // Settings step
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

  // Step 1: Personal Information
  Widget _buildPersonalInfoStep() {
    return _buildSectionCard(
      title: 'Personal Information',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  _firstnameController,
                  'First Name',
                  icon: Icons.person,
                  required: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildTextField(
                  _lastnameController,
                  'Last Name',
                  icon: Icons.person,
                  required: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _middlenameController,
            'Middle Name (Optional)',
            icon: Icons.person_outline,
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ensure the contact number is reachable for stock verification purposes.',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Settings
  Widget _buildSettingsStep() {
    return _buildSectionCard(
      title: 'Settings',
      child: Column(
        children: [
          // Container(
          //   decoration: BoxDecoration(
          //     color: Colors.grey.shade50,
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(color: Colors.grey.shade300),
          //   ),
          //   child: SwitchListTile(
          //     title: const Text('Archived'),
          //     subtitle: const Text('Hide this stock checker from active lists'),
          //     value: _isArchived,
          //     onChanged: (val) => setState(() => _isArchived = val),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(12),
          //     ),
          //   ),
          // ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Stock checkers can perform inventory verification and stock status updates.',
                    style: TextStyle(
                      color: Colors.green[800],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChecker() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final id = widget.checker?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final checker = StockCheckerModel(
        id: id,
        firstname: _firstnameController.text.trim(),
        middlename: _middlenameController.text.trim(),
        lastname: _lastnameController.text.trim(),
        address: _addressController.text.trim(),
        contact: _contactController.text.trim(),
        is_archived: _isArchived,
        created_at: widget.checker?.created_at ?? DateTime.now(),
        updated_at: DateTime.now(),
      );

      if (widget.checker == null) {
        await _checkerService.createStockChecker(checker);
      } else {
        await _checkerService.updateStockChecker(checker);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.checker == null
                ? 'Stock checker created successfully!'
                : 'Stock checker updated successfully!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save stock checker')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Step> steps = [
      Step(
        title: const Text('Personal Info'),
        content: _buildPersonalInfoStep(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Contact Details'),
        content: _buildContactDetailsStep(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Settings'),
        content: _buildSettingsStep(),
        isActive: _currentStep >= 2,
        state: StepState.indexed,
      ),
    ];

    return AdminLayout(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.checker == null
                ? 'Create Stock Checker'
                : 'Edit Stock Checker',
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
                  _currentStep == steps.length - 1 ? _saveChecker : _nextStep,
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
                                    ? (widget.checker == null
                                        ? 'Create Stock Checker'
                                        : 'Update Stock Checker')
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
