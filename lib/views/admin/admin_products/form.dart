import 'package:firebase/services/admin/product_sevice.dart';
import 'package:firebase/services/admin/category_service.dart';
import 'package:firebase/services/admin/brand_service.dart';
import 'package:firebase/services/admin/attribute_service.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
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
    _imageUrl = product?.image ?? '';
    _isArchived = product?.is_archived ?? false;

    _initData();
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
        created_at: DateTime.now(),
        updated_at: DateTime.now(),
      );
      _variants.add(_VariantEntry(variant: variant, attributes: []));
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
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

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select category and brand')));
      return;
    }

    final id =
        widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final product = ProductModel(
      id: id,
      name: _nameController.text,
      description: _descController.text,
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

      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Save error: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to save')));
    }
  }

  Widget _buildAttributePairUi(
      int variantIndex, int pairIndex, Map<String, String> pair) {
    final currentAttrId = pair['attribute_id'] ?? '';
    final currentValId = pair['attribute_value_id'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Attribute dropdown
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: DropdownButtonFormField<String>(
              value: currentAttrId.isNotEmpty ? currentAttrId : null,
              decoration: InputDecoration(
                labelText: 'Attribute',
                prefixIcon: const Icon(Icons.label, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
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
              validator: (v) =>
                  v == null || v.isEmpty ? 'Select attribute' : null,
            ),
          ),
          const SizedBox(height: 12),
          // Attribute value dropdown
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: DropdownButtonFormField<String>(
              value: currentValId.isNotEmpty ? currentValId : null,
              decoration: InputDecoration(
                labelText: 'Value',
                prefixIcon:
                    const Icon(Icons.format_list_bulleted, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
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
              validator: (v) => v == null || v.isEmpty ? 'Select value' : null,
            ),
          ),
          const SizedBox(height: 12),
          // Remove button
          Align(
            alignment: Alignment.centerRight,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: IconButton(
                onPressed: () =>
                    _removeAttributePairFromVariant(variantIndex, pairIndex),
                icon: const Icon(Icons.delete, color: Colors.red),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red[50],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AdminLayout(
          child: const Center(child: CircularProgressIndicator()));
    }

    return AdminLayout(
      child: Container(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section - Elevated
                Material(
                  elevation: 4,
                  shadowColor: Colors.green.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.shade500,
                          Colors.green.shade600,
                          Colors.green.shade700,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(8),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            widget.product == null
                                ? 'Create Product'
                                : 'Edit Product',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Image Section - Elevated
                Material(
                  elevation: 3,
                  shadowColor: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.image,
                                color: Colors.green[600], size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Product Image',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey[100],
                              ),
                              child: _imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return _buildImagePlaceholder();
                                        },
                                      ),
                                    )
                                  : _buildImagePlaceholder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Basic Information Section - Elevated
                Material(
                  elevation: 3,
                  shadowColor: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.green[600], size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Basic Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Product Name
                        Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(8),
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Product Name',
                              prefixIcon: const Icon(Icons.shopping_bag,
                                  color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Product name is required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Description
                        Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(8),
                          child: TextFormField(
                            controller: _descController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              prefixIcon: const Icon(Icons.description,
                                  color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Category
                        Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(8),
                          child: DropdownButtonFormField<CategoryModel>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              prefixIcon: const Icon(Icons.category,
                                  color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: _categories
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.name),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedCategory = val),
                            validator: (val) =>
                                val == null ? 'Please select a category' : null,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Brand
                        Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(8),
                          child: DropdownButtonFormField<BrandModel>(
                            value: _selectedBrand,
                            decoration: InputDecoration(
                              labelText: 'Brand',
                              prefixIcon: const Icon(Icons.storefront,
                                  color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            items: _brands
                                .map((b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(b.name),
                                    ))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedBrand = val),
                            validator: (val) =>
                                val == null ? 'Please select a brand' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Pricing Section - Elevated
                Material(
                  elevation: 3,
                  shadowColor: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.attach_money,
                                color: Colors.green[600], size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Pricing',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Base Price
                        Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(8),
                          child: TextFormField(
                            controller: _basePriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Base Price',
                              prefixIcon: const Icon(Icons.monetization_on,
                                  color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Sale Price
                        Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(8),
                          child: TextFormField(
                            controller: _salePriceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Sale Price',
                              prefixIcon: const Icon(Icons.local_offer,
                                  color: Colors.green),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Variants Section - Elevated
                Material(
                  elevation: 3,
                  shadowColor: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.layers,
                                    color: Colors.green[600], size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  'Product Variants',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                            Material(
                              elevation: 3,
                              shadowColor: Colors.green.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              child: ElevatedButton.icon(
                                onPressed: _addVariant,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('ADD VARIANT'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Variant cards
                        ..._variants.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final _VariantEntry entryData = entry.value;
                          final ProductVariantModel variant = entryData.variant;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Variant header
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Variant ${index + 1}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ),
                                    Material(
                                      elevation: 2,
                                      borderRadius: BorderRadius.circular(8),
                                      child: IconButton(
                                        onPressed: () => _removeVariant(index),
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.red[50],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Variant name
                                Material(
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(8),
                                  child: TextFormField(
                                    controller: TextEditingController(
                                        text: variant.name)
                                      ..addListener(() {
                                        variant.name = _nameController.text;
                                      }),
                                    decoration: InputDecoration(
                                      labelText: 'Variant Name',
                                      prefixIcon: const Icon(Icons.title,
                                          color: Colors.green),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[50],
                                    ),
                                    validator: (val) =>
                                        val == null || val.isEmpty
                                            ? 'Variant name is required'
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Variant Image
                                GestureDetector(
                                  onTap: () async {
                                    final picked =
                                        await _productService.pickImage();
                                    if (picked != null) {
                                      setState(() {
                                        variant.image = picked.url;
                                      });
                                    }
                                  },
                                  child: Material(
                                    elevation: 2,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      height: 120,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey[100],
                                      ),
                                      child: variant.image.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                variant.image,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return _buildImagePlaceholder();
                                                },
                                              ),
                                            )
                                          : _buildImagePlaceholder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Prices
                                Column(
                                  children: [
                                    Material(
                                      elevation: 2,
                                      borderRadius: BorderRadius.circular(8),
                                      child: TextFormField(
                                        controller: TextEditingController(
                                          text: variant.base_price.toString(),
                                        )..addListener(() {
                                            variant.base_price =
                                                double.tryParse(
                                                      TextEditingController(
                                                        text: variant.base_price
                                                            .toString(),
                                                      ).text,
                                                    ) ??
                                                    0;
                                          }),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Base Price',
                                          prefixIcon: const Icon(
                                              Icons.monetization_on,
                                              color: Colors.green),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Material(
                                      elevation: 2,
                                      borderRadius: BorderRadius.circular(8),
                                      child: TextFormField(
                                        controller: TextEditingController(
                                          text: variant.sale_price.toString(),
                                        )..addListener(() {
                                            variant.sale_price =
                                                double.tryParse(
                                                      TextEditingController(
                                                        text: variant.sale_price
                                                            .toString(),
                                                      ).text,
                                                    ) ??
                                                    0;
                                          }),
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Sale Price',
                                          prefixIcon: const Icon(
                                              Icons.local_offer,
                                              color: Colors.green),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Attributes section
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.settings,
                                            color: Colors.green[600],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Attributes',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Attribute pairs UI
                                      ...entryData.attributes
                                          .asMap()
                                          .entries
                                          .map((pairEntry) {
                                        final pairIndex = pairEntry.key;
                                        final pair = pairEntry.value;

                                        return _buildAttributePairUi(
                                            index, pairIndex, pair);
                                      }).toList(),

                                      const SizedBox(height: 12),

                                      // Add attribute button
                                      Center(
                                        child: Material(
                                          elevation: 2,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: ElevatedButton.icon(
                                            onPressed: () =>
                                                _addAttributePairToVariant(
                                                    index),
                                            icon:
                                                const Icon(Icons.add, size: 16),
                                            label: const Text('Add Attribute'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        if (_variants.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.layers_outlined,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No variants added yet',
                                  style: TextStyle(
                                    color: Colors.grey[600],
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button - Elevated
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: 250,
                      child: ElevatedButton.icon(
                        onPressed: _saveProduct,
                        icon: const Icon(Icons.save, size: 20),
                        label: Text(
                          widget.product == null
                              ? 'CREATE PRODUCT'
                              : 'UPDATE PRODUCT',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
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

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[200],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Tap to add image',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
