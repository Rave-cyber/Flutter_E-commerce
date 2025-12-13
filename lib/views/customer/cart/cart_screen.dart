// views/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/views/customer/checkout/checkout_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color primaryGreen = const Color(0xFF2C8610);
  bool _isLoading = false;
  final Map<String, bool> _selectedItems = {};
  bool _selectAll = false;

  // Stream to hold cart items, initialized once to prevent reloading on setState
  Stream<QuerySnapshot>? _cartStream;
  String? _currentUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthService>(context).currentUser;
    // Only recreate stream if user changes
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
    // Clear selection state when screen is disposed
    _selectedItems.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Please login to view your cart'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        foregroundColor: primaryGreen,
        actions: [
          // Select All button
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final cartItems = snapshot.data?.docs ?? [];

          if (cartItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/animations/Empty Cart.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.shopping_cart_outlined,
                          size: 80, color: Colors.grey[400]);
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Looks like you haven\'t added anything yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Start Shopping'),
                  ),
                ],
              ),
            );
          }

          // Use a StatefulWidget for the list to maintain selection state
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
          );
        },
      ),
    );
  }

  // Selection methods
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

  int _getSelectedCount() {
    return _selectedItems.values.where((isSelected) => isSelected).length;
  }

  List<QueryDocumentSnapshot> _getSelectedItems(
      List<QueryDocumentSnapshot> cartItems) {
    return cartItems.where((item) => _selectedItems[item.id] == true).toList();
  }

  // Cart operations
  Future<void> _updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) return;

    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null) return;

    try {
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

      // Remove from selection map
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

    // Navigate to checkout with selected items
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

    // Navigate to checkout with all items
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
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// Separate StatefulWidget for the list content to prevent rebuilds
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
  });

  @override
  __CartListContentState createState() => __CartListContentState();
}

class __CartListContentState extends State<_CartListContent> {
  // Local copy of selected items to manage independently
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

    // Only update local selection when cart items change (not when just selecting)
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
    // Initialize selection for new items
    for (final item in widget.cartItems) {
      _localSelectedItems.putIfAbsent(item.id, () => false);
    }

    // Remove items that are no longer in cart
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

    return Column(
      children: [
        // Selected items count
        if (selectedCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: widget.primaryGreen.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: widget.primaryGreen, size: 16),
                const SizedBox(width: 8),
                Text(
                  '$selectedCount item${selectedCount > 1 ? 's' : ''} selected',
                  style: TextStyle(
                    color: widget.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearSelection,
                  child: Text(
                    'Clear',
                    style: TextStyle(color: widget.primaryGreen),
                  ),
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
              );
            },
          ),
        ),
        _buildCheckoutSection(),
      ],
    );
  }

  Widget _buildCheckoutSection() {
    final selectedItems = _getSelectedItems();
    final hasSelectedItems = selectedItems.isNotEmpty;

    double subtotal = 0;
    double selectedSubtotal = 0;

    // Calculate totals
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
        hasSelectedItems ? (selectedSubtotal + shipping) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceRow('Selected Items Subtotal',
              hasSelectedItems ? selectedSubtotal : 0),
          _buildPriceRow('Shipping', hasSelectedItems ? shipping : 0),
          const Divider(),
          _buildPriceRow('Selected Total', hasSelectedItems ? selectedTotal : 0,
              isTotal: true),
          const SizedBox(height: 8),
          if (!hasSelectedItems && widget.cartItems.isNotEmpty)
            Text(
              'Select items to checkout individually',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: hasSelectedItems && !widget.isLoading
                      ? () => widget.checkoutSelected(selectedItems)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasSelectedItems
                        ? widget.primaryGreen
                        : Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          'Checkout Selected (${selectedItems.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isLoading
                      ? null
                      : () => widget.checkoutAll(widget.cartItems),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          'Checkout All',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? widget.primaryGreen : Colors.black,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? widget.primaryGreen : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// Separate StatefulWidget for each cart item to prevent rebuilds
class _CartItem extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> data;
  final bool isSelected;
  final Function(String, bool) toggleSelection;
  final Function(String, int) updateQuantity;
  final Function(String) removeFromCart;
  final Color primaryGreen;

  const _CartItem({
    required this.itemId,
    required this.data,
    required this.isSelected,
    required this.toggleSelection,
    required this.updateQuantity,
    required this.removeFromCart,
    required this.primaryGreen,
  });

  @override
  __CartItemState createState() => __CartItemState();
}

class __CartItemState extends State<_CartItem> {
  @override
  Widget build(BuildContext context) {
    final quantity = widget.data['quantity'] ?? 1;
    final price = (widget.data['price'] ?? 0.0).toDouble();
    final total = price * quantity;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                color: Colors.grey[200],
              ),
              child: widget.data['productImage'] == null ||
                      widget.data['productImage'].isEmpty
                  ? const Icon(Icons.image, color: Colors.grey, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.data['productName'] ?? 'Unknown Product',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${price.toStringAsFixed(2)} each',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                            Container(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                icon: const Icon(Icons.remove, size: 14),
                                onPressed: () => widget.updateQuantity(
                                    widget.itemId, quantity - 1),
                                color: quantity <= 1
                                    ? Colors.grey
                                    : widget.primaryGreen,
                                padding: EdgeInsets.zero,
                                iconSize: 14,
                              ),
                            ),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              constraints: const BoxConstraints(minWidth: 20),
                              child: Text(
                                quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Container(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                icon: const Icon(Icons.add, size: 14),
                                onPressed: () => widget.updateQuantity(
                                    widget.itemId, quantity + 1),
                                color: widget.primaryGreen,
                                padding: EdgeInsets.zero,
                                iconSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => widget.removeFromCart(widget.itemId),
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
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
