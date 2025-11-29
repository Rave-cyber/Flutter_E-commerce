import 'package:firebase/controllers/admin/product_controller.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/product.dart';
import 'form.dart';

import 'package:flutter/material.dart';
import '/models/product.dart';

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
  }

  Future<void> _pickImage() async {
    final picked = await _productService.pickImage();
    if (picked != null) {
      setState(() {
        _imageUrl = picked.url;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

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
    );

    if (widget.product == null) {
      await _productService.createProduct(product);
    } else {
      await _productService.updateProduct(product);
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
            children: [
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
              ElevatedButton(
                onPressed: _saveProduct,
                child: Text(widget.product == null ? 'Create' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
