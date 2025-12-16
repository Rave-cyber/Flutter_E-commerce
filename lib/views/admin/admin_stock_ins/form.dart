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

  bool _isLoading = true;
  bool _isSaving = false;
  int _currentStep = 0;

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
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

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

    setState(() {
      _isLoading = false;
    });
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
      case 0: // Product Selection step
        if (_selectedProduct == null) {
          message = 'Please select a product';
        }
        break;
      case 1: // Supplier & Warehouse step
        if (_selectedSupplier == null) {
          message = 'Please select a supplier';
        } else if (_selectedWarehouse == null) {
          message = 'Please select a warehouse';
        } else if (_selectedStockChecker == null) {
          message = 'Please select a stock checker';
        }
        break;
      case 2: // Stock Details step
        if (_quantityController.text.isEmpty) {
          message = 'Quantity is required';
        } else if (_priceController.text.isEmpty) {
          message = 'Price is required';
        } else if (_reasonController.text.isEmpty) {
          message = 'Reason is required';
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
      case 0: // Product Selection step
        return _selectedProduct != null;
      case 1: // Supplier & Warehouse step
        return _selectedSupplier != null &&
            _selectedWarehouse != null &&
            _selectedStockChecker != null;
      case 2: // Stock Details step
        return _quantityController.text.isNotEmpty &&
            _priceController.text.isNotEmpty &&
            _reasonController.text.isNotEmpty;
      case 3: // Additional Options step
        return true; // All optional
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.green.shade200,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
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

  void _showProductSelectionModal() async {
    if (_isLoading) return;

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
    if (_isLoading || _productVariants.isEmpty) return;

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

  // Step 1: Product Selection
  Widget _buildProductSelectionStep() {
    return _buildSectionCard(
      title: 'Product Selection',
      child: Column(
        children: [
          // Product Selection Button
          InkWell(
            onTap: _showProductSelectionModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade50,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product *',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
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
                            fontWeight: _selectedProduct != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Product Variant Selection (conditional)
          if (_productVariants.isNotEmpty) ...[
            InkWell(
              onTap: _showProductVariantSelectionModal,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Variant',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedVariant?.name ??
                                'Select a variant (optional)',
                            style: TextStyle(
                              fontSize: 16,
                              color: _selectedVariant != null
                                  ? Colors.black
                                  : Colors.grey,
                              fontWeight: _selectedVariant != null
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Step 2: Supplier & Warehouse Selection
  Widget _buildSupplierWarehouseStep() {
    return _buildSectionCard(
      title: 'Supplier & Warehouse',
      child: Column(
        children: [
          _buildDropdown<SupplierModel>(
            labelText: 'Supplier',
            value: _selectedSupplier,
            items: _suppliers
                .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.name),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedSupplier = val),
            prefixIcon: Icons.business,
            validator: (val) => val == null ? 'Please select a supplier' : null,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildDropdown<WarehouseModel>(
            labelText: 'Warehouse',
            value: _selectedWarehouse,
            items: _warehouses
                .map((w) => DropdownMenuItem(
                      value: w,
                      child: Text(w.name),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedWarehouse = val),
            prefixIcon: Icons.warehouse,
            validator: (val) =>
                val == null ? 'Please select a warehouse' : null,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildDropdown<StockCheckerModel>(
            labelText: 'Stock Checker',
            value: _selectedStockChecker,
            items: _stockCheckers
                .map((sc) => DropdownMenuItem(
                      value: sc,
                      child: Text('${sc.firstname} ${sc.lastname}'),
                    ))
                .toList(),
            onChanged: (val) => setState(() => _selectedStockChecker = val),
            prefixIcon: Icons.person,
            validator: (val) =>
                val == null ? 'Please select a stock checker' : null,
            required: true,
          ),
        ],
      ),
    );
  }

  // Step 3: Stock Details
  Widget _buildStockDetailsStep() {
    return _buildSectionCard(
      title: 'Stock Details',
      child: Column(
        children: [
          _buildTextField(
            _quantityController,
            'Quantity',
            icon: Icons.numbers,
            keyboardType: TextInputType.number,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _priceController,
            'Price',
            icon: Icons.monetization_on,
            keyboardType: TextInputType.number,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            _reasonController,
            'Reason',
            icon: Icons.description,
            maxLines: 3,
            required: true,
          ),
        ],
      ),
    );
  }

  // Step 4: Additional Options
  Widget _buildAdditionalOptionsStep() {
    return _buildSectionCard(
      title: 'Additional Options',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.black,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Product: ${_selectedProduct?.name ?? 'Not selected'}',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                      if (_selectedVariant != null)
                        Text(
                          'Variant: ${_selectedVariant!.name}',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      Text(
                        'Quantity: ${_quantityController.text.isNotEmpty ? _quantityController.text : '0'}',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                      Text(
                        'Price: ₱${_priceController.text.isNotEmpty ? _priceController.text : '0.00'}',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveStockIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

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
      is_archived: false,
      created_at: widget.stockIn?.created_at ?? DateTime.now(),
      updated_at: DateTime.now(),
    );

    try {
      if (widget.stockIn == null) {
        await _stockInService.createStockIn(stockIn);
      } else {
        await _stockInService.updateStockIn(stockIn);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.stockIn == null
                ? 'Stock-in created successfully!'
                : 'Stock-in updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save stock-in')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AdminLayout(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    List<Step> steps = [
      Step(
        title: const Text('Product'),
        content: _buildProductSelectionStep(),
        isActive: _currentStep >= 0,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Supplier'),
        content: _buildSupplierWarehouseStep(),
        isActive: _currentStep >= 1,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Details'),
        content: _buildStockDetailsStep(),
        isActive: _currentStep >= 2,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Options'),
        content: _buildAdditionalOptionsStep(),
        isActive: _currentStep >= 3,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
    ];

    return AdminLayout(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.stockIn == null ? 'Create Stock-In' : 'Edit Stock-In',
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
                  _currentStep == steps.length - 1 ? _saveStockIn : _nextStep,
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
                                    ? (widget.stockIn == null
                                        ? 'Create Stock-In'
                                        : 'Update Stock-In')
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
