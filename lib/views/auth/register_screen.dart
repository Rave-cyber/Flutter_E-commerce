// register_screen.dart
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
  bool _acceptedTerms = false; // NDA/Terms acceptance

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
      if (mounted) {
        setState(() {
          _regions = regions;
          _isLoadingRegions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRegions = false;
        });
        _showErrorSnackBar('Failed to load regions');
      }
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
        if (mounted) {
          setState(() {
            _provinces = provinces;
            _isLoadingProvinces = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingProvinces = false;
          });
          _showErrorSnackBar('Failed to load provinces');
        }
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
        if (mounted) {
          setState(() {
            _citiesMunicipalities = citiesMunicipalities;
            _isLoadingCities = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingCities = false;
          });
          _showErrorSnackBar('Failed to load cities/municipalities');
        }
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
        if (mounted) {
          setState(() {
            _barangays = barangays;
            _isLoadingBarangays = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingBarangays = false;
          });
          _showErrorSnackBar('Failed to load barangays');
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _buildFullAddress() {
    final parts = <String>[];
    
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
      if (_currentStep < 3) { // Changed from 2 to 3 to include Terms step
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
    if (!mounted) return;

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
      case 2: // Account step
        if (_contactController.text.isEmpty ||
            _emailController.text.isEmpty ||
            _passwordController.text.isEmpty ||
            _confirmPasswordController.text.isEmpty) {
          message = 'Please complete all account information';
        } else if (_passwordController.text != _confirmPasswordController.text) {
          message = 'Passwords do not match';
        }
        break;
      case 3: // Terms step
        if (!_acceptedTerms) {
          message = 'You must accept the terms and conditions';
        }
        break;
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Personal step
        return _firstnameController.text.isNotEmpty &&
            _lastnameController.text.isNotEmpty;
      case 1: // Address step
        return _streetController.text.isNotEmpty &&
            _selectedRegion != null &&
            _selectedProvince != null &&
            _selectedCityMunicipality != null;
      case 2: // Account step
        return _contactController.text.isNotEmpty &&
            _emailController.text.isNotEmpty &&
            _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text;
      case 3: // Terms step
        return _acceptedTerms;
      default:
        return true;
    }
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 1,
              color: Colors.grey.shade200,
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool obscureText = false,
    bool isPassword = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = false,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword ? obscureText : false,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          decoration: InputDecoration(
            labelText: required ? '$label *' : label,
            prefixIcon: icon != null ? Icon(icon) : null,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        if (label.contains('Confirm')) {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        } else {
                          _obscurePassword = !_obscurePassword;
                        }
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        if (required && label.contains('*') == false)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              '* Required',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: isLoading ? null : onChanged,
          validator: validator,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: required ? '$labelText *' : labelText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.green, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            errorMaxLines: 2,
          ),
        ),
        if (required && labelText.contains('*') == false)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              '* Required',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  // Step 1: Personal Information
  Widget _buildPersonalStep() {
    return SingleChildScrollView(
      child: _buildSectionCard(
        title: 'Personal Information',
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildTextField(
              controller: _firstnameController,
              label: 'First Name',
              icon: Icons.person,
              required: true,
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter first name'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _middlenameController,
              label: 'Middle Name (Optional)',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _lastnameController,
              label: 'Last Name',
              icon: Icons.person,
              required: true,
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter last name'
                  : null,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Step 2: Address Information
  Widget _buildAddressStep() {
    return SingleChildScrollView(
      child: _buildSectionCard(
        title: 'Address Information',
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildTextField(
              controller: _streetController,
              label: 'House/Street',
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
                  ? const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
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
                  ? const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
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
                  ? const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Step 3: Account Information
  Widget _buildAccountStep() {
    return SingleChildScrollView(
      child: _buildSectionCard(
        title: 'Account Information',
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildTextField(
              controller: _contactController,
              label: 'Contact Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              required: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter contact number';
                }
                if (value.length < 11) {
                  return 'Please enter a valid phone number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              required: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock_outline,
              isPassword: true,
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
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              isPassword: true,
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Step 4: Terms and Conditions (NDA)
  Widget _buildTermsStep() {
    return SingleChildScrollView(
      child: _buildSectionCard(
        title: 'Terms and Conditions',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agreement for AgriSoko Platform Use',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '1. Acceptance of Terms\n'
                      'By creating an account on AgriSoko, you agree to be bound by these Terms and Conditions. If you do not agree to all terms, do not use our services.',
                      style: TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '2. User Responsibilities\n'
                      'You are responsible for maintaining the confidentiality of your account information and for all activities under your account.',
                      style: TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '3. Data Privacy\n'
                      'We collect and process personal data in accordance with the Data Privacy Act of 2012. Your information will only be used for order processing and service improvement.',
                      style: TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '4. Non-Disclosure Agreement (NDA)\n'
                      'You agree not to disclose any proprietary information obtained through AgriSoko to third parties without prior written consent.',
                      style: TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '5. Account Security\n'
                      'You must immediately notify AgriSoko of any unauthorized use of your account or any other breach of security.',
                      style: TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '6. Amendments\n'
                      'AgriSoko reserves the right to modify these terms at any time. Continued use constitutes acceptance of modified terms.',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptedTerms = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _acceptedTerms = !_acceptedTerms;
                      });
                    },
                    child: const Text(
                      'I have read and agree to the Terms and Conditions, Privacy Policy, and Non-Disclosure Agreement',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'By checking this box, you acknowledge that you understand and agree to all terms.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_acceptedTerms) {
      _showErrorSnackBar('You must accept the terms and conditions');
      return;
    }

    if (!_validateCurrentStep()) {
      _showValidationMessage();
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
      _showErrorSnackBar('Registration failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Step> steps = [
      Step(
        title: const Text('Personal'),
        content: _buildPersonalStep(),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Address'),
        content: _buildAddressStep(),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Account'),
        content: _buildAccountStep(),
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Terms'),
        content: _buildTermsStep(),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.indexed,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Stepper progress bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(steps.length, (index) {
                    return Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: _currentStep >= index
                                  ? Colors.green
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            steps[index].title.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _currentStep >= index
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _currentStep >= index
                                  ? Colors.green
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              
              // Main content with SingleChildScrollView
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      // Current step content
                      steps[_currentStep].content,
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              
              // Bottom buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(color: Colors.grey.shade400),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_currentStep == steps.length - 1
                                ? _register
                                : _nextStep),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.green.shade300,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _currentStep == steps.length - 1
                                    ? 'Create Account'
                                    : 'Continue',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Already have an account?",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text(
                'Sign In',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}