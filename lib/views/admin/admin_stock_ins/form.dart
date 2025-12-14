import 'package:firebase/models/product.dart';
import 'package:firebase/services/admin/product_sevice.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '../../../widgets/product_selection_modal.dart';
import '../../../widgets/product_variant_selection_modal.dart';
import '/models/stock_in_model.dart';
import '/models/product_variant_model.dart';
import '/models/supplier_model.dart';
import '/models/warehouse_model.dart';
import '/models/stock_checker_model.dart';
import '/services/admin/supplier_service.dart';
import '/services/admin/warehouse_service.dart';
import '/services/admin/stock_checker_service.dart';
import '/services/admin/stock_in_service.dart';
import 'package:collection/collection.dart';

class AdminStockInForm extends StatefulWidget {
  final StockInModel? stockIn;
  const AdminStockInForm({Key? key, this.stockIn}) : super(key: key);

  @override
  State<AdminStockInForm> createState() => _AdminStockInFormState();
}

class _AdminStockInFormState extends State<AdminStockInForm> {
  final _formKey = GlobalKey<FormState>();
  final StockInService _stockInService = StockInService();

  ProductModel? _selectedProduct;
  ProductVariantModel? _selectedVariant;
  SupplierModel? _selectedSupplier;
  WarehouseModel? _selectedWarehouse;
  StockCheckerModel? _selectedStockChecker;

  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  bool _isArchived = false;

  List<ProductModel> _products = [];
  List<ProductVariantModel> _allVariants = [];
  List<ProductVariantModel> _productVariants =
      []; // Variants for selected product
  List<SupplierModel> _suppliers = [];
  List<WarehouseModel> _warehouses = [];
  List<StockCheckerModel> _stockCheckers = [];

  @override
  void initState() {
    super.initState();
    _loadData();

    if (widget.stockIn != null) {
      _quantityController.text = widget.stockIn!.quantity.toString();
      _priceController.text = widget.stockIn!.price.toString();
      _reasonController.text = widget.stockIn!.reason;
      _isArchived = widget.stockIn!.is_archived;
    }
  }

  Future<void> _loadData() async {
    _suppliers = await SupplierService().fetchSuppliersOnce();
    _warehouses = await WarehouseService().fetchWarehousesOnce();
    _stockCheckers = await StockCheckerService().fetchStockCheckersOnce();

    _products = await ProductService().fetchProductsOnce();
    _allVariants = await ProductService().fetchAllVariants();

    if (widget.stockIn != null) {
      _selectedProduct =
          _products.firstWhereOrNull((p) => p.id == widget.stockIn!.product_id);

      _selectedVariant = _allVariants
          .firstWhereOrNull((v) => v.id == widget.stockIn!.product_variant_id);

      _selectedSupplier = _suppliers
          .firstWhereOrNull((s) => s.id == widget.stockIn!.supplier_id);

      _selectedWarehouse = _warehouses
          .firstWhereOrNull((w) => w.id == widget.stockIn!.warehouse_id);

      _selectedStockChecker = _stockCheckers
          .firstWhereOrNull((sc) => sc.id == widget.stockIn!.stock_checker_id);

      // Load variants for the selected product
      if (_selectedProduct != null) {
        _loadProductVariants(_selectedProduct!);
      }
    }

    setState(() {});
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

  Future<void> _saveStockIn() async {
    if (!_formKey.currentState!.validate()) return;

    final id =
        widget.stockIn?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final stockIn = StockInModel(
      id: id,
      product_id: _selectedProduct?.id,
      product_variant_id: _selectedVariant?.id,
      supplier_id: _selectedSupplier!.id,
      warehouse_id: _selectedWarehouse!.id,
      stock_checker_id: _selectedStockChecker!.id,
      quantity: int.tryParse(_quantityController.text) ?? 0,
      remaining_quantity: int.tryParse(_quantityController.text) ?? 0,
      price: double.tryParse(_priceController.text) ?? 0.0,
      reason: _reasonController.text.trim(),
      is_archived: _isArchived,
      created_at: widget.stockIn?.created_at ?? DateTime.now(),
      updated_at: DateTime.now(),
    );

    if (widget.stockIn == null) {
      await _stockInService.createStockIn(stockIn);
    } else {
      await _stockInService.updateStockIn(stockIn);
    }

    if (context.mounted) Navigator.pop(context);
  }

  void _showProductSelectionModal() async {
    final selectedProduct = await showDialog<ProductModel>(
      context: context,
      builder: (context) => ProductSelectionModal(
        products: _products,
        allVariants: _allVariants,
        selectedProduct: _selectedProduct,
      ),
    );

    if (selectedProduct != null) {
      setState(() {
        _selectedProduct = selectedProduct;
        if (selectedProduct != null) {
          _loadProductVariants(selectedProduct);
        } else {
          _productVariants = [];
          _selectedVariant = null;
        }
      });
    }
  }

  void _showProductVariantSelectionModal() async {
    if (_productVariants.isEmpty) return;

    final selectedVariant = await showDialog<ProductVariantModel>(
      context: context,
      builder: (context) => ProductVariantSelectionModal(
        variants: _productVariants,
        selectedVariant: _selectedVariant,
      ),
    );

    if (selectedVariant != null) {
      setState(() {
        _selectedVariant = selectedVariant;
      });
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
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  /// PRODUCT SELECTION BUTTON (Replaces dropdown)
                  InkWell(
                    onTap: _showProductSelectionModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Product',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedProduct?.name ?? 'Select a product',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedProduct != null
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// PRODUCT VARIANT SELECTION BUTTON (Replaces dropdown)
                  if (_productVariants.isNotEmpty) ...[
                    InkWell(
                      onTap: _showProductVariantSelectionModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Product Variant',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedVariant?.name ??
                                        'Select a variant',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _selectedVariant != null
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  /// SUPPLIER DROPDOWN
                  DropdownButtonFormField<SupplierModel>(
                    value: _selectedSupplier,
                    decoration: const InputDecoration(labelText: 'Supplier'),
                    items: _suppliers
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name),
                            ))
                        .toList(),
                    validator: (val) =>
                        val == null ? 'Please select a supplier' : null,
                    onChanged: (val) => setState(() => _selectedSupplier = val),
                  ),
                  const SizedBox(height: 12),

                  /// WAREHOUSE DROPDOWN
                  DropdownButtonFormField<WarehouseModel>(
                    value: _selectedWarehouse,
                    decoration: const InputDecoration(labelText: 'Warehouse'),
                    items: _warehouses
                        .map((w) => DropdownMenuItem(
                              value: w,
                              child: Text(w.name),
                            ))
                        .toList(),
                    validator: (val) =>
                        val == null ? 'Please select a warehouse' : null,
                    onChanged: (val) =>
                        setState(() => _selectedWarehouse = val),
                  ),
                  const SizedBox(height: 12),

                  /// STOCK CHECKER DROPDOWN
                  DropdownButtonFormField<StockCheckerModel>(
                    value: _selectedStockChecker,
                    decoration:
                        const InputDecoration(labelText: 'Stock Checker'),
                    items: _stockCheckers
                        .map((sc) => DropdownMenuItem(
                              value: sc,
                              child: Text('${sc.firstname} ${sc.lastname}'),
                            ))
                        .toList(),
                    validator: (val) =>
                        val == null ? 'Please select a stock checker' : null,
                    onChanged: (val) =>
                        setState(() => _selectedStockChecker = val),
                  ),

                  /// QUANTITY
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  /// PRICE
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  /// REASON
                  TextFormField(
                    controller: _reasonController,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  /// ARCHIVED SWITCH
                  SwitchListTile(
                    title: const Text('Archived'),
                    value: _isArchived,
                    onChanged: (val) => setState(() => _isArchived = val),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _saveStockIn,
                    child: Text(widget.stockIn == null ? 'Create' : 'Update'),
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
