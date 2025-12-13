import 'package:firebase/models/product.dart';
import 'package:firebase/services/admin/product_sevice.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../layouts/admin_layout.dart';
import '/models/stock_out_model.dart';
import '/models/product_variant_model.dart';
import '/services/admin/stock_out_service.dart';
import 'package:collection/collection.dart';

class AdminStockOutForm extends StatefulWidget {
  final StockOutModel? stockOut;
  const AdminStockOutForm({Key? key, this.stockOut}) : super(key: key);

  @override
  State<AdminStockOutForm> createState() => _AdminStockOutFormState();
}

class _AdminStockOutFormState extends State<AdminStockOutForm> {
  final _formKey = GlobalKey<FormState>();
  final StockOutService _stockOutService = StockOutService();
  bool _isLoading = false;

  ProductModel? _selectedProduct;
  ProductVariantModel? _selectedVariant;

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  List<ProductModel> _products = [];
  List<ProductVariantModel> _allVariants = [];
  List<ProductVariantModel> _productVariants = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    if (widget.stockOut != null) {
      _quantityController.text = widget.stockOut!.quantity.toString();
      _reasonController.text = widget.stockOut!.reason;
    }
  }

  Future<void> _loadData() async {
    try {
      _products = await ProductService().fetchProductsOnce();
      _allVariants = await ProductService().fetchAllVariants();

      if (widget.stockOut != null) {
        _selectedProduct = _products
            .firstWhereOrNull((p) => p.id == widget.stockOut!.product_id);

        _selectedVariant = _allVariants.firstWhereOrNull(
            (v) => v.id == widget.stockOut!.product_variant_id);

        // Load variants for the selected product
        if (_selectedProduct != null) {
          _loadProductVariants(_selectedProduct!);
        }
      }

      setState(() {});
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _loadProductVariants(ProductModel product) {
    _productVariants = _allVariants
        .where((variant) => variant.product_id == product.id)
        .toList();

    // Clear selected variant if it doesn't belong to the new product
    if (_selectedVariant != null &&
        _selectedVariant!.product_id != product.id) {
      _selectedVariant = null;
    }
  }

  Future<void> _saveStockOut() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate required selections
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final id = widget.stockOut?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Validate stock availability for new stock-outs
      if (widget.stockOut == null) {
        final availableStock = await _checkStockAvailability();
        final requestedQuantity = int.tryParse(_quantityController.text) ?? 0;

        if (availableStock < requestedQuantity) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Insufficient stock. Available: $availableStock, Requested: $requestedQuantity'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      final stockOut = StockOutModel(
        id: id,
        product_id: _selectedProduct?.id,
        product_variant_id: _selectedVariant?.id,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        reason: _reasonController.text.trim(),
        created_at: widget.stockOut?.created_at ?? DateTime.now(),
        updated_at: DateTime.now(),
      );

      if (widget.stockOut == null) {
        await _stockOutService.createStockOut(stockOut);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock-out created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _stockOutService.updateStockOut(stockOut);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock-out updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Check available stock for selected product/variant
  Future<int> _checkStockAvailability() async {
    if (_selectedProduct == null) return 0;

    try {
      final isForVariant = _selectedVariant != null;
      final targetId =
          isForVariant ? _selectedVariant!.id : _selectedProduct!.id;

      // Get current stock from the main product record
      final productsCollection =
          FirebaseFirestore.instance.collection('products');
      final productDoc =
          await productsCollection.doc(_selectedProduct!.id).get();

      if (isForVariant) {
        // For variants, we need to check the variant's stock
        final variantsCollection =
            FirebaseFirestore.instance.collection('product_variants');
        final variantDoc = await variantsCollection.doc(targetId).get();
        return (variantDoc.get('stock') ?? 0) as int;
      } else {
        // For main product, use the stock_quantity field
        return (productDoc.get('stock_quantity') ?? 0) as int;
      }
    } catch (e) {
      print('Error checking stock availability: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.stockOut == null
                      ? 'Create Stock-Out'
                      : 'Edit Stock-Out',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  /// PRODUCT DROPDOWN
                  DropdownButtonFormField<ProductModel>(
                      value: _selectedProduct,
                      decoration: const InputDecoration(
                        labelText: 'Product *',
                        border: OutlineInputBorder(),
                      ),
                      items: _products
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name),
                              ))
                          .toList(),
                      validator: (val) =>
                          val == null ? 'Please select a product' : null,
                      onChanged: (val) {
                        setState(() {
                          _selectedProduct = val;
                          if (val != null) {
                            _loadProductVariants(val);
                          } else {
                            _productVariants = [];
                            _selectedVariant = null;
                          }
                        });
                      }),
                  const SizedBox(height: 16),

                  /// PRODUCT VARIANT DROPDOWN - Only show if product has variants
                  if (_productVariants.isNotEmpty) ...[
                    DropdownButtonFormField<ProductVariantModel>(
                      value: _selectedVariant,
                      decoration: const InputDecoration(
                        labelText: 'Product Variant',
                        border: OutlineInputBorder(),
                      ),
                      items: _productVariants
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text(v.name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedVariant = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  /// QUANTITY
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantity *',
                      hintText: 'Enter quantity to deduct',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Quantity is required';
                      }
                      final quantity = int.tryParse(val);
                      if (quantity == null || quantity <= 0) {
                        return 'Enter a valid positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  /// REASON
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason *',
                      hintText: 'e.g., Sales, Damaged, Expired, etc.',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty
                        ? 'Reason is required'
                        : null,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  /// SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveStockOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.stockOut == null
                                  ? 'Create Stock-Out'
                                  : 'Update Stock-Out',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
