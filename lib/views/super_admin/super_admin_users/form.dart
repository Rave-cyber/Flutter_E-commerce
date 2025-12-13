import 'package:flutter/material.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/models/customer_model.dart';
import 'package:firebase/models/delivery_staff_model.dart';
import 'package:firebase/models/user_model.dart';
import '../../../layouts/super_admin_layout.dart';

class SuperAdminUsersForm extends StatefulWidget {
  final String? userId; // For editing if needed in future
  final String initialRole;

  const SuperAdminUsersForm({
    super.key,
    this.userId,
    this.initialRole = 'customer',
  });

  @override
  State<SuperAdminUsersForm> createState() => _SuperAdminUsersFormState();
}

class _SuperAdminUsersFormState extends State<SuperAdminUsersForm> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Stepper
  int _currentStep = 0;

  // Selected Role
  late String _selectedRole;

  // Common Fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  // Delivery Staff Specific Fields
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _licenseNumberController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  // Stepper navigation methods
  void _nextStep() {
    if (_currentStep < 3) {
      // Max steps is 4 (0-3)
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // Calculate which step is the last for current role
  int _getLastStepForRole() {
    if (_selectedRole == 'delivery_staff') {
      return 3; // Last step is delivery details
    } else if (_selectedRole == 'customer') {
      return 2; // Last step is personal info
    } else {
      return 1; // Last step is credentials (admin)
    }
  }

  // Individual step validation
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _selectedRole.isNotEmpty;
      case 1:
        return _emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text &&
            _emailController.text.contains('@') &&
            _passwordController.text.length >= 6;
      case 2:
        if (_selectedRole == 'admin') return true; // Admin skips this step
        return _firstNameController.text.isNotEmpty &&
            _lastNameController.text.isNotEmpty &&
            _contactController.text.isNotEmpty &&
            _addressController.text.isNotEmpty;
      case 3:
        if (_selectedRole != 'delivery_staff')
          return true; // Only delivery staff needs this
        return _vehicleTypeController.text.isNotEmpty &&
            _vehicleNumberController.text.isNotEmpty &&
            _licenseNumberController.text.isNotEmpty;
      default:
        return false;
    }
  }

  // Check if current step should be shown for the selected role
  bool _shouldShowStep(int stepIndex) {
    switch (stepIndex) {
      case 0: // Role selection - always show
        return true;
      case 1: // Credentials - always show
        return true;
      case 2: // Personal Info - skip for admin
        return _selectedRole != 'admin';
      case 3: // Delivery Details - only for delivery_staff
        return _selectedRole == 'delivery_staff';
      default:
        return false;
    }
  }

  // Get the actual step index considering hidden steps
  int _getVisibleStepIndex(int stepIndex) {
    int visibleIndex = -1;
    for (int i = 0; i <= stepIndex; i++) {
      if (_shouldShowStep(i)) {
        visibleIndex++;
      }
    }
    return visibleIndex;
  }

  Future<void> _submitForm() async {
    if (!_validateCurrentStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final firstName = _firstNameController.text.trim();
      final middleName = _middleNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final address = _addressController.text.trim();
      final contact = _contactController.text.trim();

      // Create User with Auth Service
      final newUser = await _authService.registerWithEmailAndPassword(
        email,
        password,
        role: _selectedRole,
        display_name: '$firstName $lastName',
      );

      if (newUser != null) {
        // 2. Create Role Specific Profile
        if (_selectedRole == 'customer') {
          final customer = CustomerModel(
            id: '', // Firestore generates ID, or we use doc(uid)
            user_id: newUser.id,
            firstname: firstName,
            middlename: middleName,
            lastname: lastName,
            address: address,
            contact: contact,
            created_at: DateTime.now(),
          );

          await _authService.firestore
              .collection('customers')
              .add(customer.toMap());
        } else if (_selectedRole == 'delivery_staff') {
          final staff = DeliveryStaffModel(
            id: '',
            user_id: newUser.id,
            firstname: firstName,
            middlename: middleName,
            lastname: lastName,
            address: address,
            contact: contact,
            vehicle_type: _vehicleTypeController.text.trim(),
            vehicle_number: _vehicleNumberController.text.trim(),
            license_number: _licenseNumberController.text.trim(),
            created_at: DateTime.now(),
            updated_at: DateTime.now(),
          );
          await _authService.firestore
              .collection('delivery_staff')
              .add(staff.toMap());
        }
        // Admin role just needs the User Model, which is handled by registerWithEmailAndPassword

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'User created successfully. You may need to re-login.')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SuperAdminLayout(
      title: 'Create User',
      child: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue:
              _currentStep == _getLastStepForRole() ? _submitForm : _nextStep,
          onStepCancel: _previousStep,
          onStepTapped: (step) {
            // Only allow tapping on visible steps
            if (_shouldShowStep(step)) {
              setState(() => _currentStep = step);
            }
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
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _currentStep == _getLastStepForRole()
                                ? 'Create User'
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
          steps: [
            // Step 0: Account Role (always visible)
            Step(
              title: const Text('Account Role'),
              content: _buildSectionCard(
                title: 'Account Role',
                child: _buildRoleDropdown(),
              ),
              isActive: _currentStep >= 0,
              state: _currentStep >= 0
                  ? (_validateCurrentStep()
                      ? StepState.complete
                      : StepState.indexed)
                  : StepState.indexed,
            ),

            // Step 1: Login Credentials (always visible)
            Step(
              title: const Text('Login Credentials'),
              content: _buildSectionCard(
                title: 'Login Credentials',
                child: Column(
                  children: [
                    _buildTextField(_emailController, 'Email',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildTextField(_passwordController, 'Password',
                        icon: Icons.lock, obscureText: true),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
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
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              isActive: _currentStep >= 1,
              state: _currentStep >= 1
                  ? (_validateCurrentStep()
                      ? StepState.complete
                      : StepState.indexed)
                  : StepState.indexed,
            ),

            // Step 2: Personal Information (hidden for admin)
            Step(
              title: const Text('Personal Information'),
              content: _selectedRole != 'admin'
                  ? _buildSectionCard(
                      title: 'Personal Information',
                      child: Column(
                        children: [
                          _buildTextField(_firstNameController, 'First Name',
                              icon: Icons.person),
                          const SizedBox(height: 16),
                          _buildTextField(_middleNameController, 'Middle Name',
                              icon: Icons.person_outline),
                          const SizedBox(height: 16),
                          _buildTextField(_lastNameController, 'Last Name',
                              icon: Icons.person),
                          const SizedBox(height: 16),
                          _buildTextField(_contactController, 'Contact Number',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone),
                          const SizedBox(height: 16),
                          _buildTextField(_addressController, 'Address',
                              icon: Icons.location_on, maxLines: 2),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(), // Empty content for admin
              isActive: _currentStep >= 2 && _selectedRole != 'admin',
              state: _currentStep >= 2 && _selectedRole != 'admin'
                  ? (_validateCurrentStep()
                      ? StepState.complete
                      : StepState.indexed)
                  : StepState.indexed,
            ),

            // Step 3: Delivery Staff Details (only for delivery_staff)
            Step(
              title: const Text('Delivery Staff Details'),
              content: _selectedRole == 'delivery_staff'
                  ? _buildSectionCard(
                      title: 'Delivery Staff Details',
                      child: Column(
                        children: [
                          _buildTextField(
                              _vehicleTypeController, 'Vehicle Type',
                              icon: Icons.directions_car),
                          const SizedBox(height: 16),
                          _buildTextField(
                              _vehicleNumberController, 'Vehicle Number',
                              icon: Icons.confirmation_number),
                          const SizedBox(height: 16),
                          _buildTextField(
                              _licenseNumberController, 'License Number',
                              icon: Icons.card_membership),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(), // Empty content for others
              isActive: _currentStep >= 3 && _selectedRole == 'delivery_staff',
              state: _currentStep >= 3 && _selectedRole == 'delivery_staff'
                  ? (_validateCurrentStep()
                      ? StepState.complete
                      : StepState.indexed)
                  : StepState.indexed,
            ),
          ],
        ),
      ),
    );
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
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Role',
        prefixIcon: const Icon(Icons.security),
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
      items: const [
        DropdownMenuItem(value: 'customer', child: Text('Customer')),
        DropdownMenuItem(
            value: 'delivery_staff', child: Text('Delivery Staff')),
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedRole = value;
            // Adjust current step if it goes beyond the new last step
            if (_currentStep > _getLastStepForRole()) {
              _currentStep = _getLastStepForRole();
            }
          });
        }
      },
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
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
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        if (label == 'Email' && !value.contains('@')) {
          return 'Please enter a valid email';
        }
        if (label == 'Password' && value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }
}
