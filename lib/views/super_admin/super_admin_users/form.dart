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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRoleDropdown(),
              const SizedBox(height: 20),

              // Login Credentials
              const Text('Login Credentials',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildTextField(_emailController, 'Email',
                  icon: Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _buildTextField(_passwordController, 'Password',
                  icon: Icons.lock, obscureText: true),
              const SizedBox(height: 10),
              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 20),

              // Personal Info
              if (_selectedRole != 'admin') ...[
                const Text('Personal Information',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildTextField(_firstNameController, 'First Name',
                    icon: Icons.person),
                const SizedBox(height: 10),
                _buildTextField(_middleNameController, 'Middle Name',
                    icon: Icons.person_outline),
                const SizedBox(height: 10),
                _buildTextField(_lastNameController, 'Last Name',
                    icon: Icons.person),
                const SizedBox(height: 10),
                _buildTextField(_contactController, 'Contact Number',
                    icon: Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 10),
                _buildTextField(_addressController, 'Address',
                    icon: Icons.location_on, maxLines: 2),
                const SizedBox(height: 20),
              ],

              // Delivery Staff Specific
              if (_selectedRole == 'delivery_staff') ...[
                const Text('Delivery Staff Details',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildTextField(_vehicleTypeController, 'Vehicle Type',
                    icon: Icons.directions_car),
                const SizedBox(height: 10),
                _buildTextField(_vehicleNumberController, 'Vehicle Number',
                    icon: Icons.confirmation_number),
                const SizedBox(height: 10),
                _buildTextField(_licenseNumberController, 'License Number',
                    icon: Icons.card_membership),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create User',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: const InputDecoration(
        labelText: 'Role',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.security),
      ),
      items: const [
        DropdownMenuItem(value: 'customer', child: Text('Customer')),
        DropdownMenuItem(
            value: 'delivery_staff', child: Text('Delivery Staff')),
        DropdownMenuItem(value: 'admin', child: Text('Admin')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedRole = value);
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
        border: const OutlineInputBorder(),
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
