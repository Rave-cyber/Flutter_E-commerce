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

  Widget _build3DIcon(IconData icon, Color color, {double size = 24}) {
    return Icon(
      icon,
      color: color,
      size: size,
      shadows: [
        Shadow(
          color: Colors.black,
          offset: const Offset(1, 1),
          blurRadius: 8,
        ),
        Shadow(
          color: Colors.white,
          offset: const Offset(-2, -2),
          blurRadius: 4,
        ),
        Shadow(
          color: color.withOpacity(0.8),
          offset: const Offset(0, 0),
          blurRadius: 2,
        ),
      ],
    );
  }

  Widget _build3DFormField({
    required String labelText,
    required TextEditingController controller,
    Widget? prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 2,
            offset: const Offset(-1, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.green.shade600,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: prefixIcon,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
        validator: validator,
      ),
    );
  }

  Widget _build3DDropdown<T>({
    required String labelText,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    Widget? prefixIcon,
    String? Function(T?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 2,
            offset: const Offset(-1, -1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: Colors.green.shade600,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.8),
                offset: const Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: prefixIcon,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
        items: items,
        onChanged: onChanged,
        validator: validator,
      ),
    );
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
      child: Row(
        children: [
          // Attribute dropdown
          Expanded(
            flex: 5,
            child: _build3DDropdown<String>(
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
              prefixIcon: _build3DIcon(Icons.label, Colors.green.shade600),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Select attribute' : null,
            ),
          ),
          const SizedBox(width: 16),
          // Value dropdown
          Expanded(
            flex: 5,
            child: _build3DDropdown<String>(
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
              prefixIcon: _build3DIcon(
                  Icons.format_list_bulleted, Colors.green.shade600),
              validator: (v) => v == null || v.isEmpty ? 'Select value' : null,
            ),
          ),
          const SizedBox(width: 16),
          // Remove button
          _build3DButton(
            icon: Icons.delete,
            color: Colors.red.shade600,
            onPressed: () =>
                _removeAttributePairFromVariant(variantIndex, pairIndex),
          ),
        ],
      ),
    );
  }

  Widget _build3DButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? text,
    bool isPressed = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(2, 4),
                    spreadRadius: 0,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(4, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.8),
                    blurRadius: 2,
                    offset: const Offset(-1, -1),
                    spreadRadius: 0,
                  ),
                ],
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _build3DImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
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
        child: _imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  _imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImagePlaceholder('Failed to load image');
                  },
                ),
              )
            : _buildImagePlaceholder('Tap to add product image'),
      ),
    );
  }

  Widget _buildImagePlaceholder(String text) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[100]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _build3DIcon(Icons.add_photo_alternate, Colors.green.shade600,
              size: 40),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
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
                      _build3DButton(
                        icon: Icons.arrow_back,
                        color: Colors.white.withOpacity(0.3),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.product == null ? 'NEW' : 'EDIT',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                offset: Offset(0, 1),
                                blurRadius: 2,
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
                _build3DSection(
                  title: 'Product Image',
                  icon: Icons.image,
                  child: _build3DImagePicker(),
                ),
                const SizedBox(height: 32),

                // 3D Basic Information Section
                _build3DSection(
                  title: 'Basic Information',
                  icon: Icons.info_outline,
                  child: Column(
                    children: [
                      _build3DFormField(
                        labelText: 'Product Name',
                        controller: _nameController,
                        prefixIcon: _build3DIcon(
                            Icons.shopping_bag, Colors.green.shade600),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Product name is required'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      _build3DFormField(
                        labelText: 'Description',
                        controller: _descController,
                        prefixIcon: _build3DIcon(
                            Icons.description, Colors.green.shade600),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 20),
                      _build3DDropdown<CategoryModel>(
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
                            _build3DIcon(Icons.category, Colors.green.shade600),
                        validator: (val) =>
                            val == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 20),
                      _build3DDropdown<BrandModel>(
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
                        prefixIcon: _build3DIcon(
                            Icons.storefront, Colors.green.shade600),
                        validator: (val) =>
                            val == null ? 'Please select a brand' : null,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
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
                              blurRadius: 2,
                              offset: const Offset(-1, -1),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _build3DIcon(Icons.archive, Colors.red.shade600),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Archived',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withOpacity(0.8),
                                      offset: const Offset(0, 1),
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Switch(
                              value: _isArchived,
                              onChanged: (val) =>
                                  setState(() => _isArchived = val),
                              activeColor: Colors.red.shade600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3D Pricing Section
                _build3DSection(
                  title: 'Pricing',
                  icon: Icons.attach_money,
                  child: Row(
                    children: [
                      Expanded(
                        child: _build3DFormField(
                          labelText: 'Base Price',
                          controller: _basePriceController,
                          prefixIcon: _build3DIcon(
                              Icons.monetization_on, Colors.green.shade600),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _build3DFormField(
                          labelText: 'Sale Price',
                          controller: _salePriceController,
                          prefixIcon: _build3DIcon(
                              Icons.local_offer, Colors.green.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 3D Variants Section
                _build3DSection(
                  title: 'Product Variants',
                  icon: Icons.layers,
                  action: _build3DButton(
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
                                        color: Colors.red.shade700,
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
                                  _build3DButton(
                                    icon: Icons.delete,
                                    color: Colors.red.shade600,
                                    onPressed: () => _removeVariant(index),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Variant name
                              _build3DFormField(
                                labelText: 'Variant Name',
                                controller:
                                    TextEditingController(text: variant.name)
                                      ..addListener(() =>
                                          variant.name = _nameController.text),
                                prefixIcon: _build3DIcon(
                                    Icons.title, Colors.green.shade600),
                                validator: (val) => val == null || val.isEmpty
                                    ? 'Variant name is required'
                                    : null,
                              ),
                              const SizedBox(height: 20),

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
                                child: Container(
                                  height: 140,
                                  width: double.infinity,
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
                                        blurRadius: 2,
                                        offset: const Offset(-1, -1),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: variant.image.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          child: Image.network(
                                            variant.image,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return _buildImagePlaceholder(
                                                  'Failed to load');
                                            },
                                          ),
                                        )
                                      : _buildImagePlaceholder(
                                          'Add variant image'),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Prices
                              Row(
                                children: [
                                  Expanded(
                                    child: _build3DFormField(
                                      labelText: 'Base Price',
                                      controller: TextEditingController(
                                          text: variant.base_price.toString())
                                        ..addListener(() => variant
                                            .base_price = double.tryParse(
                                                _basePriceController.text) ??
                                            0),
                                      prefixIcon: _build3DIcon(
                                          Icons.monetization_on,
                                          Colors.green.shade600),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _build3DFormField(
                                      labelText: 'Sale Price',
                                      controller: TextEditingController(
                                          text: variant.sale_price.toString())
                                        ..addListener(() => variant
                                            .sale_price = double.tryParse(
                                                _salePriceController.text) ??
                                            0),
                                      prefixIcon: _build3DIcon(
                                          Icons.local_offer,
                                          Colors.green.shade600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Archived toggle
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 2,
                                      offset: const Offset(-1, -1),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    _build3DIcon(
                                        Icons.archive, Colors.red.shade600),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        'Variant Archived',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red.shade700,
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
                                    Switch(
                                      value: variant.is_archived,
                                      onChanged: (val) => setState(
                                          () => variant.is_archived = val),
                                      activeColor: Colors.red.shade600,
                                    ),
                                  ],
                                ),
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
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.8),
                                      blurRadius: 2,
                                      offset: const Offset(-1, -1),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _build3DIcon(Icons.settings,
                                            Colors.green.shade600,
                                            size: 20),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Attributes',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade800,
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

                                    // Attribute pairs UI
                                    ...entryData.attributes
                                        .asMap()
                                        .entries
                                        .map((pairEntry) {
                                      final pairIndex = pairEntry.key;
                                      final pair = pairEntry.value;
                                      return _build3DAttributePairUi(
                                          index, pairIndex, pair);
                                    }).toList(),

                                    // Add attribute button
                                    const SizedBox(height: 16),
                                    Center(
                                      child: _build3DButton(
                                        icon: Icons.add,
                                        color: Colors.green.shade600,
                                        onPressed: () =>
                                            _addAttributePairToVariant(index),
                                        text: 'Add Attribute',
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
                              _build3DIcon(
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
                        icon: _build3DIcon(Icons.save, Colors.white, size: 20),
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

  Widget _build3DSection({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _build3DIcon(icon, Colors.green.shade600, size: 28),
                    const SizedBox(width: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.8),
                            offset: const Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (action != null) action,
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
