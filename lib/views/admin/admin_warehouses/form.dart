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
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  bool _isArchived = false;

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
    _latitudeController =
        TextEditingController(text: warehouse?.latitude.toString() ?? '');
    _longitudeController =
        TextEditingController(text: warehouse?.longitude.toString() ?? '');
    _isArchived = warehouse?.is_archived ?? false;
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

  String _buildWarehouseAddress() {
    List<String> parts = [];
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

    final id = widget.warehouse?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final warehouse = WarehouseModel(
      id: id,
      name: _nameController.text.trim(),
      latitude: double.parse(_latitudeController.text.trim()),
      longitude: double.parse(_longitudeController.text.trim()),
      is_archived: _isArchived,
      created_at: widget.warehouse?.created_at ?? DateTime.now(),
      updated_at: DateTime.now(),
    );

    if (widget.warehouse == null) {
      await _warehouseService.createWarehouse(warehouse);
    } else {
      await _warehouseService.updateWarehouse(warehouse);
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Warehouse Name'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 20),

                  // ADDRESS SECTION
                  const Text(
                    'Warehouse Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // REGION DROPDOWN
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedRegion,
                    decoration: const InputDecoration(
                      labelText: 'Region',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                    items: _isLoadingRegions
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Loading regions...'),
                            ),
                          ]
                        : _regions.map((region) {
                            return DropdownMenuItem(
                              value: region,
                              child:
                                  Text(region['regionName'] ?? region['name']),
                            );
                          }).toList(),
                    onChanged: _isLoadingRegions ? null : _onRegionChanged,
                    validator: (value) =>
                        value == null ? 'Please select a region' : null,
                  ),

                  const SizedBox(height: 16),

                  // PROVINCE DROPDOWN
                  DropdownButtonFormField<Map<String, dynamic>>(
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
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select a region first'),
                            ),
                          ]
                        : _provinces.map((province) {
                            return DropdownMenuItem(
                              value: province,
                              child: Text(province['name']),
                            );
                          }).toList(),
                    onChanged: _isLoadingProvinces ? null : _onProvinceChanged,
                    validator: (value) =>
                        value == null ? 'Please select a province' : null,
                  ),

                  const SizedBox(height: 16),

                  // CITY/MUNICIPALITY DROPDOWN
                  DropdownButtonFormField<Map<String, dynamic>>(
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
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select a province first'),
                            ),
                          ]
                        : _citiesMunicipalities.map((cityMunicipality) {
                            return DropdownMenuItem(
                              value: cityMunicipality,
                              child: Text(cityMunicipality['name']),
                            );
                          }).toList(),
                    onChanged:
                        _isLoadingCities ? null : _onCityMunicipalityChanged,
                    validator: (value) => value == null
                        ? 'Please select a city/municipality'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // BARANGAY DROPDOWN
                  DropdownButtonFormField<Map<String, dynamic>>(
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
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Select a city/municipality first'),
                            ),
                          ]
                        : _barangays.map((barangay) {
                            return DropdownMenuItem(
                              value: barangay,
                              child: Text(barangay['name']),
                            );
                          }).toList(),
                    onChanged: _isLoadingBarangays
                        ? null
                        : (value) {
                            setState(() {
                              _selectedBarangay = value;
                            });
                          },
                  ),

                  const SizedBox(height: 16),

                  // DISPLAY SELECTED ADDRESS
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      _buildWarehouseAddress().isEmpty
                          ? 'Complete address will appear here'
                          : _buildWarehouseAddress(),
                      style: TextStyle(
                        color: _buildWarehouseAddress().isEmpty
                            ? Colors.grey[600]
                            : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // COORDINATES SECTION
                  const Text(
                    'Coordinates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      prefixIcon: Icon(Icons.my_location),
                    ),
                    keyboardType: TextInputType.number,
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

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      prefixIcon: Icon(Icons.my_location),
                    ),
                    keyboardType: TextInputType.number,
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

                  const SizedBox(height: 12),

                  // INFO CARD
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
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
                            'You can find coordinates using Google Maps or online coordinate tools. The address above helps identify the correct location.',
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ARCHIVE SWITCH
                  SwitchListTile(
                    title: const Text('Archived'),
                    value: _isArchived,
                    onChanged: (val) => setState(() => _isArchived = val),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _saveWarehouse,
                    child: Text(widget.warehouse == null
                        ? 'Create Warehouse'
                        : 'Update Warehouse'),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
