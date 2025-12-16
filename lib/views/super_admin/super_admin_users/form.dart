import 'package:flutter/material.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/models/customer_model.dart';
import 'package:firebase/models/delivery_staff_model.dart';
import 'package:firebase/models/user_model.dart';
import '../../../layouts/super_admin_layout.dart';
import '../../../services/philippine_address_service.dart';

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
  final TextEditingController _contactController = TextEditingController();

  // Address fields (replacing simple address controller)
  final TextEditingController _streetController = TextEditingController();

  // Address dropdown variables
  List<Map<String, dynamic>> _regions = [];
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _citiesMunicipalities = [];
  List<Map<String, dynamic>> _barangays = [];

  Map<String, dynamic>? _selectedRegion;
  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedCityMunicipality;
  Map<String, dynamic>? _selectedBarangay;

  bool _isLoadingRegions = true;
  bool _isLoadingProvinces = false;
  bool _isLoadingCities = false;
  bool _isLoadingBarangays = false;

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
    _loadRegions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _contactController.dispose();
    _streetController.dispose();
    _vehicleTypeController.dispose();
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    setState(() {
      _isLoadingRegions = true;
    });

    try {
      final regions = await PhilippineAddressService.getRegions();
      setState(() {
        _regions = regions;
        _isLoadingRegions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRegions = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load regions'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onRegionChanged(Map<String, dynamic>? region) async {
    setState(() {
      _selectedRegion = region;
      _selectedProvince = null;
      _selectedCityMunicipality = null;
      _selectedBarangay = null;
      _provinces = [];
      _citiesMunicipalities = [];
      _barangays = [];
    });

    if (region != null) {
      setState(() {
        _isLoadingProvinces = true;
      });

      try {
        final provinces =
            await PhilippineAddressService.getProvinces(region['code']);
        setState(() {
          _provinces = provinces;
          _isLoadingProvinces = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingProvinces = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load provinces'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onProvinceChanged(Map<String, dynamic>? province) async {
    setState(() {
      _selectedProvince = province;
      _selectedCityMunicipality = null;
      _selectedBarangay = null;
      _citiesMunicipalities = [];
      _barangays = [];
    });

    if (province != null) {
      setState(() {
        _isLoadingCities = true;
      });

      try {
        final citiesMunicipalities =
            await PhilippineAddressService.getCitiesMunicipalities(
                province['code']);
        setState(() {
          _citiesMunicipalities = citiesMunicipalities;
          _isLoadingCities = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingCities = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load cities/municipalities'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onCityMunicipalityChanged(
      Map<String, dynamic>? cityMunicipality) async {
    setState(() {
      _selectedCityMunicipality = cityMunicipality;
      _selectedBarangay = null;
      _barangays = [];
    });

    if (cityMunicipality != null) {
      setState(() {
        _isLoadingBarangays = true;
      });

      try {
        final barangays = await PhilippineAddressService.getBarangays(
            cityMunicipality['code']);
        setState(() {
          _barangays = barangays;
          _isLoadingBarangays = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingBarangays = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load barangays'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _buildFullAddress() {
    List<String> parts = [];

    if (_streetController.text.trim().isNotEmpty) {
      parts.add(_streetController.text.trim());
    }
    if (_selectedBarangay != null) {
      parts.add(_selectedBarangay!['name']);
    }
    if (_selectedCityMunicipality != null) {
      parts.add(_selectedCityMunicipality!['name']);
    }
    if (_selectedProvince != null) {
      parts.add(_selectedProvince!['name']);
    }
    if (_selectedRegion != null) {
      parts.add(_selectedRegion!['regionName'] ?? _selectedRegion!['name']);
    }

    return parts.join(', ');
  }

  // Stepper navigation methods
  void _nextStep() {
    if (_currentStep < 4) {
      // Max steps is 5 (0-4)
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
      return 4; // Last step is delivery details
    } else if (_selectedRole == 'customer') {
      return 3; // Last step is address info
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
            _contactController.text.isNotEmpty;
      case 3:
        if (_selectedRole == 'admin') return true; // Admin skips this step
        return _streetController.text.isNotEmpty &&
            _selectedRegion != null &&
            _selectedProvince != null &&
            _selectedCityMunicipality != null;
      case 4:
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
      case 3: // Address Info - skip for admin
        return _selectedRole != 'admin';
      case 4: // Delivery Details - only for delivery_staff
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
      final address = _buildFullAddress();
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Create User',
            style: TextStyle(
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
                Colors.green.shade50!,
                Colors.white,
                Colors.grey.shade50!,
              ],
            ),
          ),
          child: Form(
            key: _formKey,
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: _currentStep == _getLastStepForRole()
                  ? _submitForm
                  : _nextStep,
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
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
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
                  content: _buildSectionCard(
                    title: 'Personal Information',
                    child: _selectedRole != 'admin'
                        ? Column(
                            children: [
                              _buildTextField(
                                  _firstNameController, 'First Name',
                                  icon: Icons.person),
                              const SizedBox(height: 16),
                              _buildTextField(
                                  _middleNameController, 'Middle Name',
                                  icon: Icons.person_outline),
                              const SizedBox(height: 16),
                              _buildTextField(_lastNameController, 'Last Name',
                                  icon: Icons.person),
                              const SizedBox(height: 16),
                              _buildTextField(
                                  _contactController, 'Contact Number',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone),
                            ],
                          )
                        : _buildAdminPlaceholder(
                            'Personal information is not required for admin users.'),
                  ),
                  isActive: _currentStep >= 2 && _selectedRole != 'admin',
                  state: _currentStep >= 2 && _selectedRole != 'admin'
                      ? (_validateCurrentStep()
                          ? StepState.complete
                          : StepState.indexed)
                      : StepState.indexed,
                ),

                // Step 3: Address Information (hidden for admin)
                Step(
                  title: const Text('Address Information'),
                  content: _buildSectionCard(
                    title: 'Address Information',
                    child: _selectedRole != 'admin'
                        ? _buildAddressSection()
                        : _buildAdminPlaceholder(
                            'Address information is not required for admin users.'),
                  ),
                  isActive: _currentStep >= 3 && _selectedRole != 'admin',
                  state: _currentStep >= 3 && _selectedRole != 'admin'
                      ? (_validateCurrentStep()
                          ? StepState.complete
                          : StepState.indexed)
                      : StepState.indexed,
                ),

                // Step 4: Delivery Staff Details (only for delivery_staff)
                Step(
                  title: const Text('Delivery Staff Details'),
                  content: _buildSectionCard(
                    title: 'Delivery Staff Details',
                    child: _selectedRole == 'delivery_staff'
                        ? Column(
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
                          )
                        : _buildAdminPlaceholder(
                            'Delivery staff details are only required for delivery staff users.'),
                  ),
                  isActive:
                      _currentStep >= 4 && _selectedRole == 'delivery_staff',
                  state: _currentStep >= 4 && _selectedRole == 'delivery_staff'
                      ? (_validateCurrentStep()
                          ? StepState.complete
                          : StepState.indexed)
                      : StepState.indexed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminPlaceholder(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.admin_panel_settings,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
    bool required = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator ??
          (value) {
            if (required && (value == null || value.isEmpty)) {
              return 'Please enter $label';
            }
            return null;
          },
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
    );
  }

  Widget _buildAddressSection() {
    return Column(
      children: [
        _buildTextField(
          _streetController,
          'House/Street',
          icon: Icons.home_outlined,
          required: true,
          validator: (value) => value == null || value.isEmpty
              ? 'Please enter house/street'
              : null,
        ),
        const SizedBox(height: 16),
        _buildDropdown<Map<String, dynamic>>(
          labelText: 'Region',
          value: _selectedRegion,
          isLoading: _isLoadingRegions,
          items: _isLoadingRegions
              ? [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Loading regions...'),
                  ),
                ]
              : _regions
                  .map((region) => DropdownMenuItem(
                        value: region,
                        child: Text(region['regionName'] ?? region['name']),
                      ))
                  .toList(),
          onChanged: _onRegionChanged,
          prefixIcon: Icons.location_on,
          validator: (value) => value == null ? 'Please select a region' : null,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildDropdown<Map<String, dynamic>>(
          labelText: 'Province',
          value: _selectedProvince,
          isLoading: _isLoadingProvinces,
          suffixIcon: _isLoadingProvinces
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          items: _provinces.isEmpty && !_isLoadingProvinces
              ? [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Select a region first'),
                  ),
                ]
              : _provinces
                  .map((province) => DropdownMenuItem(
                        value: province,
                        child: Text(province['name']),
                      ))
                  .toList(),
          onChanged: _onProvinceChanged,
          prefixIcon: Icons.location_on,
          validator: (value) =>
              value == null ? 'Please select a province' : null,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildDropdown<Map<String, dynamic>>(
          labelText: 'City/Municipality',
          value: _selectedCityMunicipality,
          isLoading: _isLoadingCities,
          suffixIcon: _isLoadingCities
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          items: _citiesMunicipalities.isEmpty && !_isLoadingCities
              ? [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Select a province first'),
                  ),
                ]
              : _citiesMunicipalities
                  .map((cityMunicipality) => DropdownMenuItem(
                        value: cityMunicipality,
                        child: Text(cityMunicipality['name']),
                      ))
                  .toList(),
          onChanged: _onCityMunicipalityChanged,
          prefixIcon: Icons.location_on,
          validator: (value) =>
              value == null ? 'Please select a city/municipality' : null,
          required: true,
        ),
        const SizedBox(height: 16),
        _buildDropdown<Map<String, dynamic>>(
          labelText: 'Barangay (Optional)',
          value: _selectedBarangay,
          isLoading: _isLoadingBarangays,
          suffixIcon: _isLoadingBarangays
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          items: _barangays.isEmpty && !_isLoadingBarangays
              ? [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Select a city/municipality first'),
                  ),
                ]
              : _barangays
                  .map((barangay) => DropdownMenuItem(
                        value: barangay,
                        child: Text(barangay['name']),
                      ))
                  .toList(),
          onChanged: (value) {
            setState(() {
              _selectedBarangay = value;
            });
          },
          prefixIcon: Icons.location_on,
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String labelText,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    IconData? prefixIcon,
    bool required = false,
    Widget? suffixIcon,
    bool isLoading = false,
  }) {
    return DropdownButtonFormField<T>(
      isExpanded: true,
      value: value,
      items: items,
      onChanged: isLoading ? null : onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$labelText *' : labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
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
    );
  }
}
