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
import '../../../widgets/three_d_widgets.dart';

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
  late TextEditingController _stockController;

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
    _stockController =
        TextEditingController(text: product?.stock_quantity.toString() ?? '');
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
        stock: 0,
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
      stock_quantity: int.tryParse(_stockController.text) ?? 0,
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

  Widget _build3DAttributePairUi(
      int variantIndex, int pairIndex, Map<String, String> pair) {
    final currentAttrId = pair['attribute_id'] ?? '';
    final currentValId = pair['attribute_value_id'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 3,
            offset: const Offset(-1, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Attribute dropdown
          ThreeDDropdown<String>(
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
                _variants[variantIndex].attributes[pairIndex]['attribute_id'] =
                    newAttrId;
                _variants[variantIndex].attributes[pairIndex]
                    ['attribute_value_id'] = newValId;
              });
            },
            prefixIcon: ThreeDIcon(Icons.label, Colors.green.shade600),
            validator: (v) =>
                v == null || v.isEmpty ? 'Select attribute' : null,
          ),
          const SizedBox(height: 16),
          // Attribute value dropdown
          ThreeDDropdown<String>(
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
            prefixIcon:
                ThreeDIcon(Icons.format_list_bulleted, Colors.green.shade600),
            validator: (v) => v == null || v.isEmpty ? 'Select value' : null,
          ),
          const SizedBox(height: 16),
          // Remove button
          Align(
            alignment: Alignment.centerRight,
            child: ThreeDButton(
              icon: Icons.delete,
              color: Colors.red.shade600,
              onPressed: () =>
                  _removeAttributePairFromVariant(variantIndex, pairIndex),
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
              Colors.blueGrey[50]!,
              Colors.white,
              Colors.grey[100]!,
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
                // 3D Header Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                        Colors.green.shade700,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(-2, -2),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ThreeDButton(
                        icon: Icons.arrow_back,
                        color:
                            const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
                        onPressed: () => Navigator.pop(context),
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
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3D Image Section
                ThreeDSection(
                  title: 'Product Image',
                  icon: Icons.image,
                  child: ThreeDImagePicker(
                    imageUrl: _imageUrl,
                    onTap: _pickImage,
                  ),
                ),
                const SizedBox(height: 32),

                // 3D Basic Information Section
                ThreeDSection(
                  title: 'Basic Information',
                  icon: Icons.info_outline,
                  child: Column(
                    children: [
                      ThreeDFormField(
                        labelText: 'Product Name',
                        controller: _nameController,
                        prefixIcon: ThreeDIcon(
                            Icons.shopping_bag, Colors.green.shade600),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Product name is required'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      ThreeDFormField(
                        labelText: 'Description',
                        controller: _descController,
                        prefixIcon: ThreeDIcon(
                            Icons.description, Colors.green.shade600),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 20),
                      ThreeDDropdown<CategoryModel>(
                        labelText: 'Category',
                        value: _selectedCategory,
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.name),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val),
                        prefixIcon:
                            ThreeDIcon(Icons.category, Colors.green.shade600),
                        validator: (val) =>
                            val == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 20),
                      ThreeDDropdown<BrandModel>(
                        labelText: 'Brand',
                        value: _selectedBrand,
                        items: _brands
                            .map((b) => DropdownMenuItem(
                                  value: b,
                                  child: Text(b.name),
                                ))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => _selectedBrand = val),
                        prefixIcon:
                            ThreeDIcon(Icons.storefront, Colors.green.shade600),
                        validator: (val) =>
                            val == null ? 'Please select a brand' : null,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3D Pricing Section
                ThreeDSection(
                  title: 'Pricing',
                  icon: Icons.attach_money,
                  child: Column(
                    children: [
                      ThreeDFormField(
                        labelText: 'Base Price',
                        controller: _basePriceController,
                        prefixIcon: ThreeDIcon(
                          Icons.monetization_on,
                          Colors.green.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ThreeDFormField(
                        labelText: 'Sale Price',
                        controller: _salePriceController,
                        prefixIcon: ThreeDIcon(
                          Icons.local_offer,
                          Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 3D Variants Section
                ThreeDSection(
                  title: 'Product Variants',
                  icon: Icons.layers,
                  action: ThreeDButton(
                    icon: Icons.add,
                    color: Colors.green.shade600,
                    onPressed: _addVariant,
                    text: 'ADD VARIANT',
                  ),
                  child: Column(
                    children: [
                      // Variant cards
                      ..._variants.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final _VariantEntry entryData = entry.value;
                        final ProductVariantModel variant = entryData.variant;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 3,
                                offset: const Offset(-2, -2),
                                spreadRadius: 0,
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
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(1, 2),
                                          spreadRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Variant ${index + 1}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                        shadows: [
                                          Shadow(
                                            color:
                                                Colors.white.withOpacity(0.8),
                                            offset: const Offset(0, 1),
                                            blurRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ThreeDButton(
                                    icon: Icons.delete,
                                    color: Colors.red.shade600,
                                    onPressed: () => _removeVariant(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Variant name
                              ThreeDFormField(
                                labelText: 'Variant Name',
                                controller:
                                    TextEditingController(text: variant.name)
                                      ..addListener(() {
                                        variant.name = _nameController.text;
                                      }),
                                prefixIcon: ThreeDIcon(
                                    Icons.title, Colors.green.shade600),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Variant name is required'
                                    : null,
                              ),
                              const SizedBox(height: 20),

                              // Variant Image
                              ThreeDImagePicker(
                                imageUrl: variant.image,
                                onTap: () async {
                                  final picked =
                                      await _productService.pickImage();
                                  if (picked != null) {
                                    setState(() {
                                      variant.image = picked.url;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 20),

                              // Prices
                              Column(
                                children: [
                                  ThreeDFormField(
                                    labelText: 'Base Price',
                                    controller: TextEditingController(
                                      text: variant.base_price.toString(),
                                    )..addListener(() {
                                        variant.base_price = double.tryParse(
                                              TextEditingController(
                                                text: variant.base_price
                                                    .toString(),
                                              ).text,
                                            ) ??
                                            0;
                                      }),
                                    prefixIcon: ThreeDIcon(
                                      Icons.monetization_on,
                                      Colors.green.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ThreeDFormField(
                                    labelText: 'Sale Price',
                                    controller: TextEditingController(
                                      text: variant.sale_price.toString(),
                                    )..addListener(() {
                                        variant.sale_price = double.tryParse(
                                              TextEditingController(
                                                text: variant.sale_price
                                                    .toString(),
                                              ).text,
                                            ) ??
                                            0;
                                      }),
                                    prefixIcon: ThreeDIcon(
                                      Icons.local_offer,
                                      Colors.green.shade600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              // Attributes section
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 2,
                                      offset: const Offset(-1, -1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header
                                    Row(
                                      children: [
                                        ThreeDIcon(
                                          Icons.settings,
                                          Colors.green.shade600,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Attributes',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                            shadows: [
                                              Shadow(
                                                color: Colors.white
                                                    .withOpacity(0.8),
                                                offset: const Offset(0, 1),
                                                blurRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

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

                                    const SizedBox(height: 16),

                                    // Add attribute button
                                    Center(
                                      child: ThreeDButton(
                                        icon: Icons.add,
                                        color: Colors.green.shade600,
                                        text: 'Add Attribute',
                                        onPressed: () =>
                                            _addAttributePairToVariant(index),
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
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 3,
                                offset: const Offset(-2, -2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ThreeDIcon(
                                  Icons.layers_outlined, Colors.grey.shade400,
                                  size: 48),
                              const SizedBox(height: 20),
                              Text(
                                'No variants added yet',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withOpacity(0.8),
                                      offset: const Offset(0, 1),
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add product variants to create different versions of your product',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withOpacity(0.8),
                                      offset: const Offset(0, 1),
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 3D Save Button
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 3,
                          offset: const Offset(-2, -2),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: 250,
                      child: ElevatedButton.icon(
                        onPressed: _saveProduct,
                        icon: ThreeDIcon(Icons.save, Colors.white, size: 20),
                        label: Text(
                          widget.product == null
                              ? 'CREATE PRODUCT'
                              : 'UPDATE PRODUCT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
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
}
