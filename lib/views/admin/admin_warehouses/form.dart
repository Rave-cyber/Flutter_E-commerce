import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/warehouse_model.dart';
import '/services/admin/warehouse_service.dart';
import '/services/philippine_address_service.dart';

class AdminWarehouseForm extends StatefulWidget {
  final WarehouseModel? warehouse;
  const AdminWarehouseForm({Key? key, this.warehouse}) : super(key: key);

  @override
  State<AdminWarehouseForm> createState() => _AdminWarehouseFormState();
}

class _AdminWarehouseFormState extends State<AdminWarehouseForm> {
  final _formKey = GlobalKey<FormState>();
  final WarehouseService _warehouseService = WarehouseService();

  late TextEditingController _nameController;
  late TextEditingController _streetAddressController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  bool _isSaving = false;
  int _currentStep = 0;

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

  @override
  void initState() {
    super.initState();
    final warehouse = widget.warehouse;
    _nameController = TextEditingController(text: warehouse?.name ?? '');
    _streetAddressController = TextEditingController(text: '');
    _latitudeController =
        TextEditingController(text: warehouse?.latitude.toString() ?? '');
    _longitudeController =
        TextEditingController(text: warehouse?.longitude.toString() ?? '');

    _loadRegions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load regions'),
            backgroundColor: Colors.red,
          ),
        );
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
        setState(() {
          _provinces = provinces;
          _isLoadingProvinces = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingProvinces = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load provinces'),
              backgroundColor: Colors.red,
            ),
          );
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
        setState(() {
          _citiesMunicipalities = citiesMunicipalities;
          _isLoadingCities = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingCities = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load cities/municipalities'),
              backgroundColor: Colors.red,
            ),
          );
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
        setState(() {
          _barangays = barangays;
          _isLoadingBarangays = false;
        });
      } catch (e) {
        setState(() {
          _isLoadingBarangays = false;
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load barangays'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _buildWarehouseAddress() {
    List<String> parts = [];

    if (_streetAddressController.text.trim().isNotEmpty) {
      parts.add(_streetAddressController.text.trim());
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
      case 0: // Basic Info step
        if (_nameController.text.isEmpty) {
          message = 'Warehouse name is required';
        }
        break;
      case 1: // Address step
        if (_selectedRegion == null) {
          message = 'Please select a region';
        } else if (_selectedProvince == null) {
          message = 'Please select a province';
        } else if (_selectedCityMunicipality == null) {
          message = 'Please select a city/municipality';
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
      case 1: // Address step
        return _selectedRegion != null &&
            _selectedProvince != null &&
            _selectedCityMunicipality != null;
      case 2: // Coordinates step
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

  Widget _buildDropdown<T>({
    required String labelText,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
    IconData? prefixIcon,
    bool required = false,
    bool isLoading = false,
    Widget? suffixIcon,
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

  // Step 1: Basic Information
  Widget _buildBasicInfoStep() {
    return _buildSectionCard(
      title: 'Basic Information',
      child: Column(
        children: [
          _buildTextField(
            _nameController,
            'Warehouse Name',
            icon: Icons.warehouse,
            required: true,
          ),
        ],
      ),
    );
  }

  // Step 2: Address
  Widget _buildAddressStep() {
    return _buildSectionCard(
      title: 'Complete Address',
      child: Column(
        children: [
          _buildTextField(
            _streetAddressController,
            'Street Address',
            icon: Icons.home,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildDropdown<Map<String, dynamic>>(
            labelText: 'Region',
            value: _selectedRegion,
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
            suffixIcon: _isLoadingRegions
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            isLoading: _isLoadingRegions,
          ),
          const SizedBox(height: 16),
          _buildDropdown<Map<String, dynamic>>(
            labelText: 'Province',
            value: _selectedProvince,
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
            isLoading: _isLoadingProvinces,
          ),
          const SizedBox(height: 16),
          _buildDropdown<Map<String, dynamic>>(
            labelText: 'City/Municipality',
            value: _selectedCityMunicipality,
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
            isLoading: _isLoadingCities,
          ),
          const SizedBox(height: 16),
          _buildDropdown<Map<String, dynamic>>(
            labelText: 'Barangay (Optional)',
            value: _selectedBarangay,
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
            isLoading: _isLoadingBarangays,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Address Preview',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildWarehouseAddress().isEmpty
                      ? 'Complete address will appear here'
                      : _buildWarehouseAddress(),
                  style: TextStyle(
                    color: _buildWarehouseAddress().isEmpty
                        ? Colors.grey[500]
                        : Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Coordinates & Settings
  Widget _buildCoordinatesStep() {
    return _buildSectionCard(
      title: 'Coordinates & Settings',
      child: Column(
        children: [
          _buildTextField(
            _latitudeController,
            'Latitude',
            icon: Icons.my_location,
            keyboardType: TextInputType.number,
            required: true,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Required';
              }
              try {
                double.parse(val);
                return null;
              } catch (e) {
                return 'Invalid latitude';
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _longitudeController,
            'Longitude',
            icon: Icons.my_location,
            keyboardType: TextInputType.number,
            required: true,
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Required';
              }
              try {
                double.parse(val);
                return null;
              } catch (e) {
                return 'Invalid longitude';
              }
            },
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
                    'You can find coordinates using Google Maps or online coordinate tools.',
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
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
          //     subtitle: const Text('Hide this warehouse from active lists'),
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
  }

  Future<void> _saveWarehouse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRegion == null ||
        _selectedProvince == null ||
        _selectedCityMunicipality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please select region, province, and city/municipality'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final id = widget.warehouse?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final warehouse = WarehouseModel(
        id: id,
        name: _nameController.text.trim(),
        latitude: double.parse(_latitudeController.text.trim()),
        longitude: double.parse(_longitudeController.text.trim()),
        is_archived: false,
        created_at: widget.warehouse?.created_at ?? DateTime.now(),
        updated_at: DateTime.now(),
      );

      if (widget.warehouse == null) {
        await _warehouseService.createWarehouse(warehouse);
      } else {
        await _warehouseService.updateWarehouse(warehouse);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.warehouse == null
                ? 'Warehouse created successfully!'
                : 'Warehouse updated successfully!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save warehouse')),
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
        title: const Text('Basic Info'),
        content: _buildBasicInfoStep(),
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
        title: const Text('Coordinates'),
        content: _buildCoordinatesStep(),
        isActive: _currentStep >= 2,
        state: StepState.indexed,
      ),
    ];

    return AdminLayout(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.warehouse == null ? 'Create Warehouse' : 'Edit Warehouse',
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
                  _currentStep == steps.length - 1 ? _saveWarehouse : _nextStep,
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
                                    ? (widget.warehouse == null
                                        ? 'Create Warehouse'
                                        : 'Update Warehouse')
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
