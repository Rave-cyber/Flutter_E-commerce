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

      // 🔐 Register user with CUSTOMER role
      final user = await authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        role: 'customer',
      );

      if (user != null) {
        // 🔥 Create Firestore customer document
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

        // 🎉 Navigate to home screen with data
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

  List<Step> _buildSteps() {
    return [
      Step(
        title: const Text('Personal', style: TextStyle(fontSize: 12)),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.editing,
        content: Column(
          children: [
            TextFormField(
              controller: _firstnameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter first name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _middlenameController,
              decoration: const InputDecoration(
                labelText: 'Middle Name (Optional)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastnameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter last name' : null,
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Address', style: TextStyle(fontSize: 12)),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.editing,
        content: Column(
          children: [
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(
                labelText: 'House/Street',
                prefixIcon: Icon(Icons.home_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter house/street' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Map<String, dynamic>>(
              isExpanded: true,
              value: _selectedRegion,
              decoration: const InputDecoration(
                labelText: 'Region',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              items: _isLoadingRegions
                  ? const [
                      DropdownMenuItem(
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
              onChanged: _isLoadingRegions ? null : _onRegionChanged,
              validator: (value) =>
                  value == null ? 'Please select a region' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Map<String, dynamic>>(
              isExpanded: true,
              value: _selectedProvince,
              decoration: InputDecoration(
                labelText: 'Province',
                prefixIcon: const Icon(Icons.location_on),
                border: const OutlineInputBorder(),
                suffixIcon: _isLoadingProvinces
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              items: _provinces.isEmpty && !_isLoadingProvinces
                  ? const [
                      DropdownMenuItem(
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
              onChanged: _isLoadingProvinces ? null : _onProvinceChanged,
              validator: (value) =>
                  value == null ? 'Please select a province' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Map<String, dynamic>>(
              isExpanded: true,
              value: _selectedCityMunicipality,
              decoration: InputDecoration(
                labelText: 'City/Municipality',
                prefixIcon: const Icon(Icons.location_on),
                border: const OutlineInputBorder(),
                suffixIcon: _isLoadingCities
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              items: _citiesMunicipalities.isEmpty && !_isLoadingCities
                  ? const [
                      DropdownMenuItem(
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
              onChanged: _isLoadingCities ? null : _onCityMunicipalityChanged,
              validator: (value) =>
                  value == null ? 'Please select a city/municipality' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Map<String, dynamic>>(
              isExpanded: true,
              value: _selectedBarangay,
              decoration: InputDecoration(
                labelText: 'Barangay (Optional)',
                prefixIcon: const Icon(Icons.location_on),
                border: const OutlineInputBorder(),
                suffixIcon: _isLoadingBarangays
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              items: _barangays.isEmpty && !_isLoadingBarangays
                  ? const [
                      DropdownMenuItem(
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
              onChanged: _isLoadingBarangays
                  ? null
                  : (value) {
                      setState(() {
                        _selectedBarangay = value;
                      });
                    },
            ),
          ],
        ),
      ),
      Step(
        title: const Text('Account', style: TextStyle(fontSize: 12)),
        isActive: _currentStep >= 2,
        state: StepState.editing,
        content: Column(
          children: [
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Enter contact number'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your email';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm your password';
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
    ];
  }

  bool _validateStep(int step) {
    switch (step) {
      case 0:
        if ((_firstnameController.text.trim().isEmpty) ||
            (_lastnameController.text.trim().isEmpty)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter your first and last name')),
          );
          return false;
        }
        return true;
      case 1:
        if (_streetController.text.trim().isEmpty ||
            _selectedRegion == null ||
            _selectedProvince == null ||
            _selectedCityMunicipality == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Complete your address: street, region, province, city/municipality')),
          );
          return false;
        }
        return true;
      case 2:
        if (_contactController.text.trim().isEmpty ||
            _emailController.text.trim().isEmpty ||
            !_emailController.text.contains('@') ||
            _passwordController.text.trim().length < 6 ||
            _confirmPasswordController.text.trim() !=
                _passwordController.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complete account details properly')),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account'),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          steps: steps,
          onStepContinue: () async {
            if (_currentStep < steps.length - 1) {
              if (_validateStep(_currentStep)) {
                setState(() => _currentStep += 1);
              }
            } else {
              if (_validateStep(_currentStep)) {
                await _register();
              }
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep -= 1);
          },
          controlsBuilder: (context, details) {
            final isLast = _currentStep == steps.length - 1;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(130, 44),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)),
                          )
                        : Text(isLast ? 'Create Account' : 'Next'),
                  ),
                ],
              ),
            );
          },
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
}
