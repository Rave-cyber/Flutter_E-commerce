import 'package:firebase/services/admin/product_sevice.dart';
import 'package:firebase/services/admin/category_service.dart';
import 'package:firebase/services/admin/brand_service.dart';
import 'package:firebase/services/admin/attribute_service.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '../../../widgets/floating_action_button_widget.dart';
import '../../../models/product.dart';
import '../../../models/category_model.dart';
import '../../../models/brand_model.dart';
import '../../../models/attribute_model.dart';
import '../../../models/attribute_value_model.dart';
import '../../../models/product_variant_model.dart';
import '../../../models/product_variant_attribute_model.dart';

class AdminProductForm extends StatefulWidget {
  final ProductModel? product;
  const AdminProductForm({Key? key, this.product}) : super(key: key);

  @override
  State<AdminProductForm> createState() => _AdminProductFormState();
}

/// Helper: holds a variant + its list of attribute-value pairs in-memory for UI
class _VariantEntry {
  ProductVariantModel variant;

  /// Each map: { 'attribute_id': '..', 'attribute_value_id': '..' }
  List<Map<String, String>> attributes;

  _VariantEntry({
    required this.variant,
    List<Map<String, String>>? attributes,
  }) : attributes = attributes ?? [];
}

class _AdminProductFormState extends State<AdminProductForm> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final BrandService _brandService = BrandService();
  final AttributeService _attributeService = AttributeService();

  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _basePriceController;
  late TextEditingController _salePriceController;

  String _imageUrl = '';
  String _generatedSku = '';
  bool _isArchived = false;

  // Dropdown state
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  CategoryModel? _selectedCategory;
  BrandModel? _selectedBrand;

  // Attributes for variant selection
  List<AttributeModel> _attributes = [];
  Map<String, List<AttributeValueModel>> _attributeValues = {};

  // Product variants (wrappers)
  List<_VariantEntry> _variants = [];

  bool _loading = true;
  bool _isSaving = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descController = TextEditingController(text: product?.description ?? '');
    _basePriceController =
        TextEditingController(text: product?.base_price.toString() ?? '');
    _salePriceController =
        TextEditingController(text: product?.sale_price.toString() ?? '');
    _generatedSku = product?.sku ?? '';
    _imageUrl = product?.image ?? '';
    _isArchived = product?.is_archived ?? false;

    _initData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _basePriceController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  /// Generate SKU based on category, brand, and timestamp
  String _generateSKU(
      CategoryModel category, BrandModel brand, String productName) {
    final timestamp = DateTime.now()
        .millisecondsSinceEpoch
        .toString()
        .substring(8); // Last 6 digits
    final categoryCode =
        category.name.substring(0, 3).toUpperCase().replaceAll(' ', '');
    final brandCode =
        brand.name.substring(0, 3).toUpperCase().replaceAll(' ', '');
    final nameCode = productName.isNotEmpty
        ? productName.substring(0, 2).toUpperCase().replaceAll(' ', '')
        : 'PR';

    return '$categoryCode-$brandCode-$nameCode-$timestamp';
  }

  /// Generate variant SKU based on main product SKU and variant index
  String _generateVariantSKU(String mainSku, int variantIndex) {
    final suffix = String.fromCharCode(65 + variantIndex); // A, B, C, etc.
    return '$mainSku-$suffix';
  }

  /// Update SKU when category, brand, or name changes
  void _updateSKU() {
    if (_selectedCategory != null &&
        _selectedBrand != null &&
        _nameController.text.isNotEmpty) {
      setState(() {
        _generatedSku = _generateSKU(
            _selectedCategory!, _selectedBrand!, _nameController.text);
      });
    }
  }

  Future<void> _initData() async {
    await _loadDropdowns();
    await _loadAttributes();
    // If editing an existing product, optionally load its variants + variant attributes:
    if (widget.product != null) {
      await _loadExistingVariants(widget.product!.id);
    }
    setState(() => _loading = false);
  }

  Future<void> _loadDropdowns() async {
    final categories = await _categoryService.getCategories().first;
    final brands = await _brandService.getBrands().first;

    setState(() {
      _categories = categories;
      _brands = brands;

      if (widget.product != null) {
        _selectedCategory = categories.isNotEmpty
            ? categories.firstWhere(
                (c) => c.id == widget.product!.category_id,
                orElse: () => categories[0],
              )
            : null;

        _selectedBrand = brands.isNotEmpty
            ? brands.firstWhere(
                (b) => b.id == widget.product!.brand_id,
                orElse: () => brands[0],
              )
            : null;
      }
    });
  }

  Future<void> _loadAttributes() async {
    final attributes = await _attributeService.getAttributes();
    Map<String, List<AttributeValueModel>> valuesMap = {};

    for (var attr in attributes) {
      valuesMap[attr.id] = await _attributeService.getAttributeValues(attr.id);
    }

    setState(() {
      _attributes = attributes;
      _attributeValues = valuesMap;
    });
  }

  /// Load existing variants and their attribute pairs for editing
  Future<void> _loadExistingVariants(String productId) async {
    try {
      final variants = await _productService.fetchVariants(productId);
      final List<_VariantEntry> entries = [];

      for (var v in variants) {
        // fetch variant attributes (junction rows)
        final pairs = await _productService.fetchVariantAttributes(v.id);
        // convert to map list for UI
        final uiPairs = pairs
            .map((pa) => {
                  'id': pa['id'].toString(),
                  'attribute_id': pa['attribute_id'].toString(),
                  'attribute_value_id': pa['attribute_value_id'].toString(),
                })
            .toList();
        entries.add(_VariantEntry(variant: v, attributes: uiPairs));
      }

      setState(() {
        _variants = entries;
      });
    } catch (e) {
      // ignore or show error
      debugPrint('Failed loading existing variants: $e');
    }
  }

  Future<void> _pickImage() async {
    final picked = await _productService.pickImage();
    if (picked != null) {
      setState(() {
        _imageUrl = picked.url;
      });
    }
  }

  void _addVariant() {
    setState(() {
      final variant = ProductVariantModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product_id: widget.product?.id ?? '',
        name: '',
        image: '',
        base_price: 0,
        sale_price: 0,
        is_archived: false,
        sku: _generatedSku.isNotEmpty
            ? _generateVariantSKU(_generatedSku, _variants.length)
            : null,
        created_at: DateTime.now(),
        updated_at: DateTime.now(),
      );
      _variants.add(_VariantEntry(variant: variant, attributes: []));
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
      // Regenerate SKUs for remaining variants
      _variants.asMap().entries.forEach((entry) {
        if (_generatedSku.isNotEmpty) {
          entry.value.variant.sku =
              _generateVariantSKU(_generatedSku, entry.key);
        }
      });
    });
  }

  /// Add an empty attribute pair to the variant UI entry
  void _addAttributePairToVariant(int variantIndex) {
    final attrId = _attributes.isNotEmpty ? _attributes[0].id : '';
    final valId =
        (attrId.isNotEmpty && (_attributeValues[attrId]?.isNotEmpty ?? false))
            ? _attributeValues[attrId]![0].id
            : '';
    setState(() {
      _variants[variantIndex]
          .attributes
          .add({'attribute_id': attrId, 'attribute_value_id': valId});
    });
  }

  void _removeAttributePairFromVariant(int variantIndex, int pairIndex) {
    setState(() {
      _variants[variantIndex].attributes.removeAt(pairIndex);
    });
  }

  // Stepper navigation methods
  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 3) {
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
      case 1: // Basic Info step
        if (_nameController.text.isEmpty) {
          message = 'Product name is required';
        } else if (_selectedCategory == null) {
          message = 'Please select a category';
        } else if (_selectedBrand == null) {
          message = 'Please select a brand';
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
      case 0: // Image step
        return true; // Image is optional
      case 1: // Basic Info step
        if (_nameController.text.isEmpty) {
          return false;
        }
        if (_selectedCategory == null) {
          return false;
        }
        if (_selectedBrand == null) {
          return false;
        }
        return true;
      case 2: // Pricing step
        return true; // Pricing is optional
      case 3: // Variants step
        return true; // Variants are optional
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
          const Divider(height: 1),
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
      validator: (value) {
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
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: required ? '$labelText *' : labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
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

  Widget _buildImagePicker(
      {required String imageUrl, required VoidCallback onTap}) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
            border: Border.all(
              color: Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  )
                : _buildImagePlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[100],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_a_photo,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to select image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _build3DAttributePairUi(
      int variantIndex, int pairIndex, Map<String, String> pair) {
    final currentAttrId = pair['attribute_id'] ?? '';
    final currentValId = pair['attribute_value_id'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.shade200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Attribute dropdown
                _buildDropdown<String>(
                  labelText: 'Attribute',
                  value: currentAttrId.isNotEmpty ? currentAttrId : null,
                  items: _attributes
                      .map((a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ))
                      .toList(),
                  onChanged: (val) {
                    final newAttrId = val ?? '';
                    final newValId = (newAttrId.isNotEmpty &&
                            (_attributeValues[newAttrId]?.isNotEmpty ?? false))
                        ? _attributeValues[newAttrId]![0].id
                        : '';
                    setState(() {
                      _variants[variantIndex].attributes[pairIndex]
                          ['attribute_id'] = newAttrId;
                      _variants[variantIndex].attributes[pairIndex]
                          ['attribute_value_id'] = newValId;
                    });
                  },
                  prefixIcon: Icons.label,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Select attribute' : null,
                ),
                const SizedBox(height: 12),
                // Attribute value dropdown
                _buildDropdown<String>(
                  labelText: 'Value',
                  value: currentValId.isNotEmpty ? currentValId : null,
                  items: (_attributeValues[currentAttrId] ?? [])
                      .map((av) => DropdownMenuItem(
                            value: av.id,
                            child: Text(av.name),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _variants[variantIndex].attributes[pairIndex]
                          ['attribute_value_id'] = val ?? '';
                    });
                  },
                  prefixIcon: Icons.format_list_bulleted,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Select value' : null,
                ),
                const SizedBox(height: 12),
                // Remove button
                Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    elevation: 2,
                    shadowColor: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.red.shade50,
                    child: InkWell(
                      onTap: () => _removeAttributePairFromVariant(
                          variantIndex, pairIndex),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.shade200,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.delete,
                          size: 16,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Step 1: Product Image
  Widget _buildImageStep() {
    return _buildSectionCard(
      title: 'Product Image',
      child: _buildImagePicker(
        imageUrl: _imageUrl,
        onTap: _pickImage,
      ),
    );
  }

  // Step 2: Basic Information
  Widget _buildBasicInfoStep() {
    return _buildSectionCard(
      title: 'Basic Information',
      child: Column(
        children: [
          _buildTextField(
            _nameController,
            'Product Name',
            icon: Icons.shopping_bag,
            required: true,
            onTap: () {
              // Update SKU when name changes
              _nameController.addListener(_updateSKU);
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _descController,
            'Description',
            icon: Icons.description,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            TextEditingController(text: _generatedSku),
            'SKU (Auto-Generated)',
            icon: Icons.qr_code,
            readOnly: true,
          ),
          const SizedBox(height: 16),
          _buildDropdown<CategoryModel>(
            labelText: 'Category',
            value: _selectedCategory,
            items: _categories
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedCategory = val);
              _updateSKU();
            },
            prefixIcon: Icons.category,
            validator: (val) => val == null ? 'Please select a category' : null,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildDropdown<BrandModel>(
            labelText: 'Brand',
            value: _selectedBrand,
            items: _brands
                .map((b) => DropdownMenuItem(
                      value: b,
                      child: Text(b.name),
                    ))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedBrand = val);
              _updateSKU();
            },
            prefixIcon: Icons.storefront,
            validator: (val) => val == null ? 'Please select a brand' : null,
            required: true,
          ),
        ],
      ),
    );
  }

  // Step 3: Pricing
  Widget _buildPricingStep() {
    return _buildSectionCard(
      title: 'Pricing',
      child: Column(
        children: [
          _buildTextField(
            _basePriceController,
            'Base Price',
            icon: Icons.monetization_on,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _salePriceController,
            'Sale Price',
            icon: Icons.local_offer,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  // Step 4: Product Variants
  Widget _buildVariantsStep() {
    return _buildSectionCard(
      title: 'Product Variants',
      child: Column(
        children: [
          // Add variant button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _addVariant,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'ADD VARIANT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Variant cards
          ..._variants.asMap().entries.map((entry) {
            final int index = entry.key;
            final _VariantEntry entryData = entry.value;
            final ProductVariantModel variant = entryData.variant;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                elevation: 0,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Variant header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Variant ${index + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade700,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeVariant(index),
                              icon: Icon(
                                Icons.delete,
                                size: 16,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Variant name
                        TextFormField(
                          initialValue: variant.name,
                          decoration: InputDecoration(
                            labelText: 'Variant Name',
                            prefixIcon: const Icon(Icons.title),
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
                          onChanged: (value) {
                            variant.name = value;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Variant SKU (Auto-generated, read-only)
                        TextFormField(
                          initialValue: variant.sku ?? '',
                          decoration: InputDecoration(
                            labelText: 'Variant SKU (Auto-Generated)',
                            prefixIcon: const Icon(Icons.qr_code),
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
                            fillColor: Colors.grey.shade100,
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),

                        // Variant Image
                        _buildImagePicker(
                          imageUrl: variant.image,
                          onTap: () async {
                            final picked = await _productService.pickImage();
                            if (picked != null) {
                              setState(() {
                                variant.image = picked.url;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Prices
                        Column(
                          children: [
                            TextFormField(
                              initialValue: variant.base_price.toString(),
                              decoration: InputDecoration(
                                labelText: 'Base Price',
                                prefixIcon: const Icon(Icons.monetization_on),
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
                                  borderSide:
                                      const BorderSide(color: Colors.green),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                variant.base_price =
                                    double.tryParse(value) ?? 0;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              initialValue: variant.sale_price.toString(),
                              decoration: InputDecoration(
                                labelText: 'Sale Price',
                                prefixIcon: const Icon(Icons.local_offer),
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
                                  borderSide:
                                      const BorderSide(color: Colors.green),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                variant.sale_price =
                                    double.tryParse(value) ?? 0;
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Attributes section
                        _buildSectionCard(
                          title: 'Attributes',
                          child: Column(
                            children: [
                              // Attribute pairs UI - stacked vertically
                              ...entryData.attributes
                                  .asMap()
                                  .entries
                                  .map((pairEntry) {
                                final pairIndex = pairEntry.key;
                                final pair = pairEntry.value;

                                return _build3DAttributePairUi(
                                    index, pairIndex, pair);
                              }).toList(),

                              const SizedBox(height: 12),

                              // Add attribute button
                              Center(
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _addAttributePairToVariant(index),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Add Attribute',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
              ),
            );
          }).toList(),

          if (_variants.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                elevation: 0,
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No variants added yet',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add product variants to create different versions of your product',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select category and brand')));
      return;
    }

    setState(() => _isSaving = true);

    final id =
        widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final product = ProductModel(
      id: id,
      name: _nameController.text,
      description: _descController.text,
      sku: _generatedSku.isNotEmpty ? _generatedSku : null,
      image: _imageUrl,
      base_price: double.tryParse(_basePriceController.text) ?? 0,
      sale_price: double.tryParse(_salePriceController.text) ?? 0,
      is_archived: _isArchived,
      category_id: _selectedCategory!.id,
      brand_id: _selectedBrand!.id,
    );

    try {
      if (widget.product == null) {
        await _productService.createProduct(product);
      } else {
        await _productService.updateProduct(product);
      }

      // Save variants and their junction attributes
      for (var entry in _variants) {
        final variant = entry.variant;
        variant.product_id = id;
        if (variant.id.isEmpty) {
          variant.id = DateTime.now().millisecondsSinceEpoch.toString();
        }

        // create/update variant
        await _productService.createOrUpdateVariant(variant);

        // remove existing attributes for this variant (if editing) then re-create
        // (Assumes ProductService exposes deleteVariantAttributesForVariant)
        try {
          await _productService.deleteVariantAttributesForVariant(variant.id);
        } catch (e) {
          // ignore if method doesn't exist or nothing to delete
        }

        // create junction rows for each attribute pair
        for (var pair in entry.attributes) {
          // skip invalid pairs
          final attrId = pair['attribute_id'] ?? '';
          final valId = pair['attribute_value_id'] ?? '';
          if (attrId.isEmpty || valId.isEmpty) continue;

          final pvAttr = ProductVariantAttributeModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            product_variant_id: variant.id,
            attribute_id: attrId,
            attribute_value_id: valId,
            created_at: DateTime.now(),
            updated_at: DateTime.now(),
          );

          // Assumes ProductService exposes createVariantAttribute
          await _productService.createVariantAttribute(
            variantId: pvAttr.product_variant_id,
            attributeId: pvAttr.attribute_id,
            attributeValueId: pvAttr.attribute_value_id,
          );
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.product == null
                ? 'Product created successfully!'
                : 'Product updated successfully!'),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save product')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AdminLayout(
          child: const Center(child: CircularProgressIndicator()));
    }

    List<Step> steps = [
      Step(
        title: const Text('Image'),
        content: _buildImageStep(),
        isActive: _currentStep >= 0,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Basic Info'),
        content: _buildBasicInfoStep(),
        isActive: _currentStep >= 1,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Pricing'),
        content: _buildPricingStep(),
        isActive: _currentStep >= 2,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Variants'),
        content: _buildVariantsStep(),
        isActive: _currentStep >= 3,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
    ];

    return AdminLayout(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.product == null ? 'Create Product' : 'Edit Product',
            style: const TextStyle(
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
                  _currentStep == steps.length - 1 ? _saveProduct : _nextStep,
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
                                    ? (widget.product == null
                                        ? 'Create Product'
                                        : 'Update Product')
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
