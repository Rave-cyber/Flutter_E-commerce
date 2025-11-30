import 'package:firebase/services/admin/product_sevice.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/product.dart';
import '/models/category_model.dart';
import '/models/brand_model.dart';
import '/models/attribute_model.dart';
import '/models/attribute_value_model.dart';
import '/models/product_variant_model.dart';
import 'form.dart';

class AdminProductForm extends StatefulWidget {
  final ProductModel? product;
  const AdminProductForm({Key? key, this.product}) : super(key: key);

  @override
  State<AdminProductForm> createState() => _AdminProductFormState();
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

  // Product variants
  List<ProductVariantModel> _variants = [];

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

    _loadDropdowns();
    _loadAttributes();
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
      _variants.add(ProductVariantModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product_id: widget.product?.id ?? '',
        name: '',
        attribute_id: _attributes.isNotEmpty ? _attributes[0].id : '',
        attribute_value_id: _attributes.isNotEmpty &&
                _attributeValues[_attributes[0].id]!.isNotEmpty
            ? _attributeValues[_attributes[0].id]![0].id
            : '',
        image: '',
        base_price: 0,
        sale_price: 0,
        stock: 0,
        is_archived: false,
        created_at: DateTime.now(),
        updated_at: DateTime.now(),
      ));
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
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

    if (widget.product == null) {
      await _productService.createProduct(product);
    } else {
      await _productService.updateProduct(product);
    }

    // Save variants
    for (var variant in _variants) {
      variant.product_id = id; // Ensure correct product ID
      if (variant.id.isEmpty) {
        variant.id = DateTime.now().millisecondsSinceEpoch.toString();
      }
      await _productService.createOrUpdateVariant(variant);
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button row
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
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Archived'),
                value: _isArchived,
                onChanged: (val) => setState(() => _isArchived = val),
              ),
              const SizedBox(height: 16),

              // Product Variants Section
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
              ..._variants.asMap().entries.map((entry) {
                int index = entry.key;
                ProductVariantModel variant = entry.value;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        // Remove variant button
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
                        // Attribute Dropdown
                        DropdownButtonFormField<String>(
                          value: variant.attribute_id.isNotEmpty
                              ? variant.attribute_id
                              : (_attributes.isNotEmpty
                                  ? _attributes[0].id
                                  : null),
                          decoration:
                              const InputDecoration(labelText: 'Attribute'),
                          items: _attributes
                              .map((attr) => DropdownMenuItem(
                                    value: attr.id,
                                    child: Text(attr.name),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setState(() {
                              variant.attribute_id = val ?? '';
                              // Reset attribute value
                              if (_attributeValues[val]?.isNotEmpty ?? false) {
                                variant.attribute_value_id =
                                    _attributeValues[val]![0].id;
                              } else {
                                variant.attribute_value_id = '';
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        // Attribute Value Dropdown
                        DropdownButtonFormField<String>(
                          value: variant.attribute_value_id.isNotEmpty
                              ? variant.attribute_value_id
                              : (_attributeValues[variant.attribute_id]
                                          ?.isNotEmpty ??
                                      false
                                  ? _attributeValues[variant.attribute_id]![0]
                                      .id
                                  : null),
                          decoration: const InputDecoration(
                              labelText: 'Attribute Value'),
                          items: (_attributeValues[variant.attribute_id] ?? [])
                              .map((val) => DropdownMenuItem(
                                    value: val.id,
                                    child: Text(val.name),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => variant.attribute_value_id = val!),
                        ),
                        const SizedBox(height: 8),
                        // Variant Image Picker
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
                        TextFormField(
                          initialValue: variant.stock.toString(),
                          decoration: const InputDecoration(
                              labelText: 'Stock Quantity'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) =>
                              variant.stock = int.tryParse(val) ?? 0,
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Archived'),
                          value: variant.is_archived,
                          onChanged: (val) =>
                              setState(() => variant.is_archived = val),
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
