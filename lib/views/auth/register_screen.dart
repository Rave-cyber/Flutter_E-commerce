import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/philippine_address_service.dart';
import '../../models/customer_model.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _firstnameController = TextEditingController();
  final _middlenameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _streetController = TextEditingController();
  final _contactController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  @override
  void dispose() {
    _firstnameController.dispose();
    _middlenameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _streetController.dispose();
    _contactController.dispose();
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
      case 0: // Personal step
        if (_firstnameController.text.isEmpty ||
            _lastnameController.text.isEmpty) {
          message = 'First name and last name are required';
        }
        break;
      case 1: // Address step
        if (_streetController.text.isEmpty ||
            _selectedRegion == null ||
            _selectedProvince == null ||
            _selectedCityMunicipality == null) {
          message = 'Please complete your address information';
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
      case 0: // Personal step
        if (_firstnameController.text.isEmpty ||
            _lastnameController.text.isEmpty) {
          return false;
        }
        return true;
      case 1: // Address step
        if (_streetController.text.isEmpty ||
            _selectedRegion == null ||
            _selectedProvince == null ||
            _selectedCityMunicipality == null) {
          return false;
        }
        return true;
      case 2: // Account step
        if (_contactController.text.isEmpty ||
            _emailController.text.isEmpty ||
            _passwordController.text.isEmpty ||
            _confirmPasswordController.text.isEmpty) {
          return false;
        }
        if (_passwordController.text != _confirmPasswordController.text) {
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
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: obscureText
            ? IconButton(
                icon: Icon(
                  label.contains('Password') && label.contains('Confirm')
                      ? (_obscureConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off)
                      : (_obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off),
                ),
                onPressed: () {
                  if (label.contains('Password') && label.contains('Confirm')) {
                    setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword);
                  } else {
                    setState(() => _obscurePassword = !_obscurePassword);
                  }
                },
              )
            : null,
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

  // Step 1: Personal Information
  Widget _buildPersonalStep() {
    return _buildSectionCard(
      title: 'Personal Information',
      child: Column(
        children: [
          _buildTextField(
            _firstnameController,
            'First Name',
            icon: Icons.person,
            required: true,
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter first name'
                : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _middlenameController,
            'Middle Name (Optional)',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _lastnameController,
            'Last Name',
            icon: Icons.person,
            required: true,
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter last name'
                : null,
          ),
        ],
      ),
    );
  }

  // Step 2: Address Information
  Widget _buildAddressStep() {
    return _buildSectionCard(
      title: 'Address Information',
      child: Column(
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
            validator: (value) =>
                value == null ? 'Please select a region' : null,
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
      ),
    );
  }

  // Step 3: Account Information
  Widget _buildAccountStep() {
    return _buildSectionCard(
      title: 'Account Information',
      child: Column(
        children: [
          _buildTextField(
            _contactController,
            'Contact Number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            required: true,
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter contact number'
                : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _emailController,
            'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            required: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _passwordController,
            'Password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            required: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _confirmPasswordController,
            'Confirm Password',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            required: true,
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
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedRegion == null ||
        _selectedProvince == null ||
        _selectedCityMunicipality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select your region, province, and city/municipality'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Register user with CUSTOMER role
      final user = await authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        role: 'customer',
      );

      if (user != null) {
        // Create Firestore customer document
        final customerDoc =
            FirebaseFirestore.instance.collection('customers').doc();

        final customer = CustomerModel(
          id: customerDoc.id,
          user_id: user.id,
          firstname: _firstnameController.text.trim(),
          middlename: _middlenameController.text.trim(),
          lastname: _lastnameController.text.trim(),
          address: _buildFullAddress(),
          contact: _contactController.text.trim(),
          created_at: DateTime.now(),
        );

        await customerDoc.set(customer.toMap());

        // Navigate to home screen with data
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              user: user,
              customer: customer,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Step> steps = [
      Step(
        title: const Text('Personal'),
        content: _buildPersonalStep(),
        isActive: _currentStep >= 0,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Address'),
        content: _buildAddressStep(),
        isActive: _currentStep >= 1,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Account'),
        content: _buildAccountStep(),
        isActive: _currentStep >= 2,
        state: StepState.indexed,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(
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
                _currentStep == steps.length - 1 ? _register : _nextStep,
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
                              _currentStep == steps.length - 1
                                  ? 'Create Account'
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Already have an account?",
                style: TextStyle(color: Colors.grey[600])),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
