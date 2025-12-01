import 'package:firebase/services/admin/product_sevice.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/product.dart';
import '/models/category_model.dart';
import '/models/brand_model.dart';
import '/models/attribute_model.dart';
import '/models/attribute_value_model.dart';
import '/models/product_variant_model.dart';
import '/models/product_variant_attribute_model.dart';
import 'form.dart';

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
    final categories = await _productService.fetchCategories();
    final brands = await _productService.fetchBrands();

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
    final attributes = await _productService.fetchAttributes();
    Map<String, List<AttributeValueModel>> valuesMap = {};

    for (var attr in attributes) {
      valuesMap[attr.id] = await _productService.fetchAttributeValues(attr.id);
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

    return Row(
      children: [
        // Attribute dropdown
        Expanded(
          flex: 5,
          child: DropdownButtonFormField<String>(
            value: currentAttrId.isNotEmpty ? currentAttrId : null,
            decoration: const InputDecoration(labelText: 'Attribute'),
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
                _variants[variantIndex].attributes[pairIndex]['attribute_id'] =
                    newAttrId;
                _variants[variantIndex].attributes[pairIndex]
                    ['attribute_value_id'] = newValId;
              });
            },
            validator: (v) =>
                v == null || v.isEmpty ? 'Select attribute' : null,
          ),
        ),
        const SizedBox(width: 8),
        // Value dropdown
        Expanded(
          flex: 5,
          child: DropdownButtonFormField<String>(
            value: currentValId.isNotEmpty ? currentValId : null,
            decoration: const InputDecoration(labelText: 'Value'),
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
        const SizedBox(width: 8),
        // Remove button
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () =>
              _removeAttributePairFromVariant(variantIndex, pairIndex),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AdminLayout(
          child: const Center(child: CircularProgressIndicator()));
    }

    return AdminLayout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back + Title
              Row(
                children: [
                  BackButton(onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 8),
                  Text(
                    widget.product == null ? 'Create Product' : 'Edit Product',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: _imageUrl.isNotEmpty
                    ? Image.network(_imageUrl, height: 150, fit: BoxFit.cover)
                    : Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.camera_alt, size: 50),
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Product fields
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),

              // Category Dropdown
              DropdownButtonFormField<CategoryModel>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val),
                validator: (val) =>
                    val == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 8),

              // Brand Dropdown
              DropdownButtonFormField<BrandModel>(
                value: _selectedBrand,
                decoration: const InputDecoration(labelText: 'Brand'),
                items: _brands
                    .map((b) => DropdownMenuItem(
                          value: b,
                          child: Text(b.name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedBrand = val),
                validator: (val) =>
                    val == null ? 'Please select a brand' : null,
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _basePriceController,
                decoration: const InputDecoration(labelText: 'Base Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _salePriceController,
                decoration: const InputDecoration(labelText: 'Sale Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Archived'),
                value: _isArchived,
                onChanged: (val) => setState(() => _isArchived = val),
              ),
              const SizedBox(height: 16),

              // Product Variants Section header + add
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Product Variants',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _addVariant,
                    icon: const Icon(Icons.add),
                    label: const Text('+ Add Product Variant'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Variant cards
              ..._variants.asMap().entries.map((entry) {
                final int index = entry.key;
                final _VariantEntry entryData = entry.value;
                final ProductVariantModel variant = entryData.variant;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // Remove variant
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeVariant(index),
                            ),
                          ],
                        ),

                        // Variant name
                        TextFormField(
                          initialValue: variant.name,
                          decoration:
                              const InputDecoration(labelText: 'Variant Name'),
                          onChanged: (val) => variant.name = val,
                          validator: (val) =>
                              val == null || val.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),

                        // Variant Image picker
                        GestureDetector(
                          onTap: () async {
                            final picked = await _productService.pickImage();
                            if (picked != null) {
                              setState(() {
                                variant.image = picked.url;
                              });
                            }
                          },
                          child: variant.image.isNotEmpty
                              ? Image.network(variant.image,
                                  height: 100, fit: BoxFit.cover)
                              : Container(
                                  height: 100,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.camera_alt, size: 40),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),

                        // Prices and Stock
                        TextFormField(
                          initialValue: variant.base_price.toString(),
                          decoration:
                              const InputDecoration(labelText: 'Base Price'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) =>
                              variant.base_price = double.tryParse(val) ?? 0,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: variant.sale_price.toString(),
                          decoration:
                              const InputDecoration(labelText: 'Sale Price'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) =>
                              variant.sale_price = double.tryParse(val) ?? 0,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Archived'),
                          value: variant.is_archived,
                          onChanged: (val) =>
                              setState(() => variant.is_archived = val),
                        ),

                        const Divider(),

                        // Attributes list for this variant
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Attributes',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Attribute pairs UI
                        ...entryData.attributes
                            .asMap()
                            .entries
                            .map((pairEntry) {
                          final pairIndex = pairEntry.key;
                          final pair = pairEntry.value;
                          return _buildAttributePairUi(index, pairIndex, pair);
                        }).toList(),

                        // Add attribute button
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Attribute'),
                            onPressed: () => _addAttributePairToVariant(index),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  child: Text(widget.product == null ? 'Create' : 'Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
