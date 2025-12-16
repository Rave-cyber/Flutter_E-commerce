import 'package:firebase/models/product.dart';
import 'package:firebase/services/admin/product_sevice.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../layouts/admin_layout.dart';
import '../../../widgets/product_selection_modal.dart';
import '../../../widgets/product_variant_selection_modal.dart';
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
  bool _isLoading = true;
  bool _isSaving = false;
  int _currentStep = 0;

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

    // Add listener to quantity controller for real-time validation
    _quantityController.addListener(_onQuantityChanged);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _onQuantityChanged() {
    // Trigger real-time validation when quantity changes
    setState(() {
      // This will trigger form validation
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

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
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
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
      if (_currentStep < 2) {
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
      case 1: // Stock Details step
        if (_quantityController.text.isEmpty) {
          message = 'Quantity is required';
        } else if (_reasonController.text.isEmpty) {
          message = 'Reason is required';
        } else {
          // Check stock availability
          _validateStockAvailability().then((isValid) {
            if (!isValid) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Insufficient stock for the requested quantity'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
          return; // Don't show message yet, async validation
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
      case 1: // Stock Details step
        if (_quantityController.text.isEmpty ||
            _reasonController.text.isEmpty) {
          return false;
        }
        // Async validation will be handled separately
        return true;
      case 2: // Review step
        return true; // Always valid
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

  /// Validate stock availability
  Future<bool> _validateStockAvailability() async {
    final requestedQuantity = int.tryParse(_quantityController.text) ?? 0;
    if (requestedQuantity <= 0) return false;

    final availableStock = await _checkStockAvailability();
    int maxAllowedQuantity = availableStock;

    if (widget.stockOut != null) {
      maxAllowedQuantity += widget.stockOut!.quantity;
    }

    return requestedQuantity <= maxAllowedQuantity;
  }

  /// Show detailed stock information dialog
  void _showStockDetails(
      int availableStock, int requestedQuantity, int maxAllowedQuantity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${_selectedProduct?.name ?? 'N/A'}'),
            if (_selectedVariant != null)
              Text('Variant: ${_selectedVariant!.name}'),
            const SizedBox(height: 8),
            Text('Available Stock: $availableStock'),
            Text('Current Stock-Out: ${widget.stockOut?.quantity ?? 0}'),
            Text('Max Allowed Quantity: $maxAllowedQuantity'),
            Text('Requested Quantity: $requestedQuantity'),
            const SizedBox(height: 8),
            if (requestedQuantity > maxAllowedQuantity)
              Text(
                'Cannot proceed: Requested quantity exceeds available stock.',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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

  // Step 2: Stock Details
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
            _reasonController,
            'Reason',
            icon: Icons.description,
            maxLines: 3,
            required: true,
          ),
          const SizedBox(height: 16),
          // Stock availability info
          FutureBuilder<int>(
            future: _checkStockAvailability(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final availableStock = snapshot.data!;
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Available Stock: $availableStock',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // Step 3: Review & Confirm
  Widget _buildReviewStep() {
    return _buildSectionCard(
      title: 'Review & Confirm',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stock-Out Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Product: ${_selectedProduct?.name ?? 'Not selected'}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                if (_selectedVariant != null)
                  Text(
                    'Variant: ${_selectedVariant!.name}',
                    style: TextStyle(color: Colors.black),
                  ),
                Text(
                  'Quantity: ${_quantityController.text.isNotEmpty ? _quantityController.text : '0'}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                Text(
                  'Reason: ${_reasonController.text.isNotEmpty ? _reasonController.text : 'Not specified'}',
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 8),
                FutureBuilder<int>(
                  future: _checkStockAvailability(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final availableStock = snapshot.data!;
                      return Text(
                        'Available Stock After: ${availableStock - (int.tryParse(_quantityController.text) ?? 0)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Warning message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber,
                  color: Colors.black,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action will deduct the specified quantity from your inventory.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      _isSaving = true;
    });

    try {
      final id = widget.stockOut?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Validate stock availability
      final availableStock = await _checkStockAvailability();
      final requestedQuantity = int.tryParse(_quantityController.text) ?? 0;

      // For updates, calculate remaining stock after accounting for current stock-out
      int maxAllowedQuantity = availableStock;
      if (widget.stockOut != null) {
        maxAllowedQuantity +=
            widget.stockOut!.quantity; // Add back current stock-out quantity
      }

      if (requestedQuantity > maxAllowedQuantity) {
        if (context.mounted) {
          String errorMessage;
          if (widget.stockOut != null) {
            errorMessage =
                'Quantity exceeds available stock. Maximum allowed: $maxAllowedQuantity, Requested: $requestedQuantity';
          } else {
            errorMessage =
                'Insufficient stock. Available: $availableStock, Requested: $requestedQuantity';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'View Stock Details',
                textColor: Colors.white,
                onPressed: () {
                  _showStockDetails(
                      availableStock, requestedQuantity, maxAllowedQuantity);
                },
              ),
            ),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final stockOut = StockOutModel(
        id: id,
        product_id: _selectedProduct?.id,
        product_variant_id: _selectedVariant?.id,
        quantity: requestedQuantity,
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
            content: Text('Error saving stock-out: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AdminLayout(
        child: const Center(
          child: CircularProgressIndicator(),
        ),
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
        title: const Text('Details'),
        content: _buildStockDetailsStep(),
        isActive: _currentStep >= 1,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
      Step(
        title: const Text('Review'),
        content: _buildReviewStep(),
        isActive: _currentStep >= 2,
        state: _validateCurrentStep() ? StepState.complete : StepState.indexed,
      ),
    ];

    return AdminLayout(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.stockOut == null ? 'Create Stock-Out' : 'Edit Stock-Out',
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
                  _currentStep == steps.length - 1 ? _saveStockOut : _nextStep,
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
                            backgroundColor: Colors.grey.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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
                                    ? (widget.stockOut == null
                                        ? 'Create Stock-Out'
                                        : 'Update Stock-Out')
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
