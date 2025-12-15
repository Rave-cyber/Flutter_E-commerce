import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/views/customer/checkout/checkout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'guest_cart_screen.dart';
import '../../../../models/product.dart';
import '../../../../models/product_variant_model.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Consistent color scheme with orders screen
  final Color primaryGreen = const Color(0xFF2C8610);
  final Color backgroundColor = const Color(0xFFF9FAFB);
  final Color textPrimary = const Color(0xFF111827);
  final Color textSecondary = const Color(0xFF6B7280);

  bool _isLoading = false;
  final Map<String, bool> _selectedItems = {};
  bool _selectAll = false;

  Stream<QuerySnapshot>? _cartStream;
  String? _currentUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthService>(context).currentUser;
    if (user != null && (_cartStream == null || user.uid != _currentUserId)) {
      _currentUserId = user.uid;
      _cartStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .snapshots();
    }
  }

  @override
  void dispose() {
    _selectedItems.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    if (user == null) {
      return const GuestCartScreen();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Cart',
          style: TextStyle(color: textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _cartStream,
            builder: (context, snapshot) {
              final cartItems = snapshot.data?.docs ?? [];
              if (cartItems.isEmpty) return const SizedBox();

              return IconButton(
                icon: Icon(
                  _selectAll ? Icons.check_box : Icons.check_box_outline_blank,
                  color: primaryGreen,
                ),
                onPressed: () => _toggleSelectAll(cartItems),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _cartStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final cartItems = snapshot.data?.docs ?? [];

          if (cartItems.isEmpty) {
            return _buildEmptyState();
          }

          return _CartListContent(
            cartItems: cartItems,
            selectedItems: _selectedItems,
            selectAll: _selectAll,
            toggleItemSelection: _toggleItemSelection,
            toggleSelectAll: (items) => _toggleSelectAll(items),
            clearSelection: _clearSelection,
            updateQuantity: _updateQuantity,
            removeFromCart: _removeFromCart,
            checkoutSelected: _checkoutSelected,
            checkoutAll: _checkoutAll,
            isLoading: _isLoading,
            user: user,
            primaryGreen: primaryGreen,
            backgroundColor: backgroundColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Cart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/Empty Cart.json',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.shopping_bag_outlined,
                  size: 80,
                  color: textSecondary.withOpacity(0.5),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Looks like you haven\'t added anything yet',
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text('Start Shopping'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleItemSelection(String itemId, bool selected) {
    setState(() {
      _selectedItems[itemId] = selected;
      _updateSelectAllState();
    });
  }

  void _toggleSelectAll(List<QueryDocumentSnapshot> cartItems) {
    setState(() {
      _selectAll = !_selectAll;
      for (final item in cartItems) {
        _selectedItems[item.id] = _selectAll;
      }
    });
  }

  void _updateSelectAllState() {
    final allSelected = _selectedItems.values.every((isSelected) => isSelected);
    setState(() {
      _selectAll = allSelected;
    });
  }

  void _clearSelection() {
    setState(() {
      for (final key in _selectedItems.keys) {
        _selectedItems[key] = false;
      }
      _selectAll = false;
    });
  }

  Future<void> _updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) return;

    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      // Get current cart item data
      final cartItemDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId)
          .get();

      if (!cartItemDoc.exists) return;

      final cartData = cartItemDoc.data() as Map<String, dynamic>;
      final productId = cartData['productId'] ?? '';
      final variantId = cartData['variantId'];

      // Check available stock
      final availableStock = await _getAvailableStock(productId, variantId);

      if (newQuantity > availableStock) {
        _showSnackBar('Cannot exceed available stock ($availableStock items)');
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId)
          .update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showSnackBar('Error updating quantity');
    }
  }

  Future<int> _getAvailableStock(String productId, String? variantId) async {
    try {
      if (variantId != null && variantId.isNotEmpty) {
        // Get variant stock
        final variantDoc = await FirebaseFirestore.instance
            .collection('product_variants')
            .doc(variantId)
            .get();

        if (variantDoc.exists) {
          final variantData = variantDoc.data() as Map<String, dynamic>;
          return variantData['stock'] ?? 0;
        }
      } else {
        // Get product stock
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        if (productDoc.exists) {
          final productData = productDoc.data() as Map<String, dynamic>;
          return productData['stock_quantity'] ?? 0;
        }
      }
      return 0;
    } catch (e) {
      print('Error fetching stock: $e');
      return 0;
    }
  }

  Future<void> _removeFromCart(String itemId) async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId)
          .delete();

      _selectedItems.remove(itemId);
      _updateSelectAllState();

      _showSnackBar('Item removed from cart');
    } catch (e) {
      _showSnackBar('Error removing item');
    }
  }

  Future<void> _checkoutSelected(
      List<QueryDocumentSnapshot> selectedItems) async {
    if (selectedItems.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final List<Map<String, dynamic>> items = selectedItems.map((item) {
      final data = item.data() as Map<String, dynamic>;
      return {
        'productId': data['productId'] ?? item.id,
        'productName': data['productName'] ?? '',
        'productImage': data['productImage'] ?? '',
        'price': (data['price'] ?? 0.0).toDouble(),
        'quantity': data['quantity'] ?? 1,
      };
    }).toList();

    setState(() {
      _isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: items,
          isSelectedItems: true,
          selectedItemIds: selectedItems.map((item) => item.id).toList(),
        ),
      ),
    );
  }

  Future<void> _checkoutAll(List<QueryDocumentSnapshot> cartItems) async {
    if (cartItems.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final List<Map<String, dynamic>> items = cartItems.map((item) {
      final data = item.data() as Map<String, dynamic>;
      return {
        'productId': data['productId'] ?? item.id,
        'productName': data['productName'] ?? '',
        'productImage': data['productImage'] ?? '',
        'price': (data['price'] ?? 0.0).toDouble(),
        'quantity': data['quantity'] ?? 1,
      };
    }).toList();

    setState(() {
      _isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(
          cartItems: items,
          isSelectedItems: false,
          selectedItemIds: cartItems.map((item) => item.id).toList(),
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _CartListContent extends StatefulWidget {
  final List<QueryDocumentSnapshot> cartItems;
  final Map<String, bool> selectedItems;
  final bool selectAll;
  final Function(String, bool) toggleItemSelection;
  final Function(List<QueryDocumentSnapshot>) toggleSelectAll;
  final VoidCallback clearSelection;
  final Function(String, int) updateQuantity;
  final Function(String) removeFromCart;
  final Function(List<QueryDocumentSnapshot>) checkoutSelected;
  final Function(List<QueryDocumentSnapshot>) checkoutAll;
  final bool isLoading;
  final User user;
  final Color primaryGreen;
  final Color backgroundColor;
  final Color textPrimary;
  final Color textSecondary;

  const _CartListContent({
    required this.cartItems,
    required this.selectedItems,
    required this.selectAll,
    required this.toggleItemSelection,
    required this.toggleSelectAll,
    required this.clearSelection,
    required this.updateQuantity,
    required this.removeFromCart,
    required this.checkoutSelected,
    required this.checkoutAll,
    required this.isLoading,
    required this.user,
    required this.primaryGreen,
    required this.backgroundColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  __CartListContentState createState() => __CartListContentState();
}

class __CartListContentState extends State<_CartListContent> {
  late Map<String, bool> _localSelectedItems;

  @override
  void initState() {
    super.initState();
    _localSelectedItems = Map.from(widget.selectedItems);
    _initializeSelection();
  }

  @override
  void didUpdateWidget(_CartListContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_listsAreEqual(oldWidget.cartItems, widget.cartItems)) {
      _initializeSelection();
    }
  }

  bool _listsAreEqual(
      List<QueryDocumentSnapshot> list1, List<QueryDocumentSnapshot> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id) return false;
    }
    return true;
  }

  void _initializeSelection() {
    for (final item in widget.cartItems) {
      _localSelectedItems.putIfAbsent(item.id, () => false);
    }

    _localSelectedItems.removeWhere(
        (key, value) => !widget.cartItems.any((item) => item.id == key));
  }

  void _toggleItemSelection(String itemId, bool selected) {
    setState(() {
      _localSelectedItems[itemId] = selected;
    });
    widget.toggleItemSelection(itemId, selected);
  }

  void _toggleSelectAll() {
    final newValue = !widget.selectAll;
    setState(() {
      for (final item in widget.cartItems) {
        _localSelectedItems[item.id] = newValue;
      }
    });
    widget.toggleSelectAll(widget.cartItems);
  }

  void _clearSelection() {
    setState(() {
      for (final key in _localSelectedItems.keys) {
        _localSelectedItems[key] = false;
      }
    });
    widget.clearSelection();
  }

  int _getSelectedCount() {
    return _localSelectedItems.values.where((isSelected) => isSelected).length;
  }

  List<QueryDocumentSnapshot> _getSelectedItems() {
    return widget.cartItems
        .where((item) => _localSelectedItems[item.id] == true)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _getSelectedCount();
    final selectedItems = _getSelectedItems();

    double subtotal = 0;
    double selectedSubtotal = 0;

    for (final item in widget.cartItems) {
      final data = item.data() as Map<String, dynamic>;
      final price = (data['price'] ?? 0.0).toDouble();
      final quantity = data['quantity'] ?? 1;
      final itemTotal = price * quantity;

      subtotal += itemTotal;

      if (_localSelectedItems[item.id] == true) {
        selectedSubtotal += itemTotal;
      }
    }

    const shipping = 5.99;
    final total = subtotal + shipping;
    final selectedTotal =
        selectedCount > 0 ? (selectedSubtotal + shipping) : 0.0;

    return Column(
      children: [
        if (selectedCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: widget.primaryGreen.withOpacity(0.08),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: widget.primaryGreen, size: 16),
                const SizedBox(width: 8),
                Text(
                  '$selectedCount item${selectedCount > 1 ? 's' : ''} selected',
                  style: TextStyle(
                    color: widget.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearSelection,
                  style: TextButton.styleFrom(
                    foregroundColor: widget.primaryGreen,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Clear'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.cartItems.length,
            itemBuilder: (context, index) {
              final item = widget.cartItems[index];
              final data = item.data() as Map<String, dynamic>;
              return _CartItem(
                itemId: item.id,
                data: data,
                isSelected: _localSelectedItems[item.id] ?? false,
                toggleSelection: _toggleItemSelection,
                updateQuantity: widget.updateQuantity,
                removeFromCart: widget.removeFromCart,
                primaryGreen: widget.primaryGreen,
                textPrimary: widget.textPrimary,
                textSecondary: widget.textSecondary,
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedCount > 0) ...[
                _buildPriceRow('Selected Items', selectedSubtotal),
                _buildPriceRow('Shipping', shipping),
                const Divider(),
                _buildPriceRow('Selected Total', selectedTotal, isTotal: true),
                const SizedBox(height: 4),
                Text(
                  'Excluding selected items from total calculation',
                  style: TextStyle(
                    color: widget.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedCount > 0 && !widget.isLoading
                        ? () => widget.checkoutSelected(selectedItems)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: widget.isLoading
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
                            'Checkout Selected ($selectedCount)',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: !widget.isLoading
                      ? () => widget.checkoutAll(widget.cartItems)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Checkout All Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? widget.primaryGreen : widget.textPrimary,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              color: isTotal ? widget.primaryGreen : widget.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItem extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> data;
  final bool isSelected;
  final Function(String, bool) toggleSelection;
  final Function(String, int) updateQuantity;
  final Function(String) removeFromCart;
  final Color primaryGreen;
  final Color textPrimary;
  final Color textSecondary;

  const _CartItem({
    required this.itemId,
    required this.data,
    required this.isSelected,
    required this.toggleSelection,
    required this.updateQuantity,
    required this.removeFromCart,
    required this.primaryGreen,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  __CartItemState createState() => __CartItemState();
}

class __CartItemState extends State<_CartItem> {
  late TextEditingController _quantityController;
  late FocusNode _quantityFocus;
  bool _isEditingQuantity = false;
  int _availableStock = 0;
  bool _isLoadingStock = true;

  @override
  void initState() {
    super.initState();
    final quantity = widget.data['quantity'] ?? 1;
    _quantityController = TextEditingController(text: quantity.toString());
    _quantityFocus = FocusNode();
    _loadStockInfo();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _quantityFocus.dispose();
    super.dispose();
  }

  Future<void> _loadStockInfo() async {
    try {
      final productId = widget.data['productId'] ?? '';
      final variantId = widget.data['variantId'];

      if (variantId != null && variantId.isNotEmpty) {
        // Get variant stock
        final variantDoc = await FirebaseFirestore.instance
            .collection('product_variants')
            .doc(variantId)
            .get();

        if (variantDoc.exists) {
          final variantData = variantDoc.data() as Map<String, dynamic>;
          setState(() {
            _availableStock = variantData['stock'] ?? 0;
            _isLoadingStock = false;
          });
        } else {
          setState(() {
            _availableStock = 0;
            _isLoadingStock = false;
          });
        }
      } else {
        // Get product stock
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();

        if (productDoc.exists) {
          final productData = productDoc.data() as Map<String, dynamic>;
          setState(() {
            _availableStock = productData['stock_quantity'] ?? 0;
            _isLoadingStock = false;
          });
        } else {
          setState(() {
            _availableStock = 0;
            _isLoadingStock = false;
          });
        }
      }
    } catch (e) {
      print('Error loading stock: $e');
      setState(() {
        _availableStock = 0;
        _isLoadingStock = false;
      });
    }
  }

  void _startEditingQuantity() {
    setState(() {
      _isEditingQuantity = true;
    });
    _quantityController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _quantityController.text.length,
    );
    _quantityFocus.requestFocus();
  }

  void _stopEditingQuantity() {
    setState(() {
      _isEditingQuantity = false;
    });
    _quantityFocus.unfocus();

    // Update quantity in database
    final newQuantity = int.tryParse(_quantityController.text) ?? 1;
    if (newQuantity >= 1 && newQuantity <= _availableStock) {
      widget.updateQuantity(widget.itemId, newQuantity);
    } else if (newQuantity > _availableStock) {
      // Show error and revert to previous quantity
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Cannot exceed available stock ($_availableStock items)'),
          backgroundColor: Colors.red,
        ),
      );
      _quantityController.text = (widget.data['quantity'] ?? 1).toString();
    } else {
      // Minimum quantity is 1
      _quantityController.text = '1';
      widget.updateQuantity(widget.itemId, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantity = widget.data['quantity'] ?? 1;
    final price = (widget.data['price'] ?? 0.0).toDouble();
    final total = price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: widget.isSelected,
            onChanged: (value) =>
                widget.toggleSelection(widget.itemId, value ?? false),
            activeColor: widget.primaryGreen,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 8),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: widget.data['productImage'] != null &&
                      widget.data['productImage'].isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.data['productImage']),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[100],
            ),
            child: widget.data['productImage'] == null ||
                    widget.data['productImage'].isEmpty
                ? Icon(
                    Icons.image,
                    color: widget.textSecondary.withOpacity(0.3),
                    size: 20,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.data['productName'] ?? 'Unknown Product',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: widget.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${price.toStringAsFixed(2)} each',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stock Information
                  if (!_isLoadingStock)
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color:
                              _availableStock > 0 ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stock: $_availableStock',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                _availableStock > 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: !_isEditingQuantity && quantity > 1
                                    ? () => widget.updateQuantity(
                                        widget.itemId, quantity - 1)
                                    : null,
                                color: quantity <= 1 || _isEditingQuantity
                                    ? widget.textSecondary
                                    : widget.primaryGreen,
                                padding: EdgeInsets.zero,
                                iconSize: 16,
                              ),
                            ),
                            GestureDetector(
                              onTap: !_isEditingQuantity
                                  ? _startEditingQuantity
                                  : null,
                              child: Container(
                                width: 50,
                                height: 32,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: _isEditingQuantity
                                    ? TextField(
                                        controller: _quantityController,
                                        focusNode: _quantityFocus,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: widget.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                        ),
                                        onSubmitted: (_) =>
                                            _stopEditingQuantity(),
                                      )
                                    : Text(
                                        quantity.toString(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: widget.textPrimary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                              ),
                            ),
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: !_isEditingQuantity &&
                                        quantity < _availableStock
                                    ? () => widget.updateQuantity(
                                        widget.itemId, quantity + 1)
                                    : null,
                                color: quantity >= _availableStock ||
                                        _isEditingQuantity
                                    ? widget.textSecondary
                                    : widget.primaryGreen,
                                padding: EdgeInsets.zero,
                                iconSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () => widget.removeFromCart(widget.itemId),
                        color: Colors.red[400],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  if (_isEditingQuantity)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Tap Done to save, Cancel to revert',
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
