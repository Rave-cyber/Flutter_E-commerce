// views/cart/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/firestore_service.dart';

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
        foregroundColor: primaryGreen,
        actions: [
          // Select All button
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('cart')
                .snapshots(),
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
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .snapshots(),
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add some products to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Initialize selection state for new items
          for (final item in cartItems) {
            _selectedItems.putIfAbsent(item.id, () => false);
          }

          // Remove items that are no longer in cart
          _selectedItems.removeWhere(
              (key, value) => !cartItems.any((item) => item.id == key));

          return Column(
            children: [
              // Selected items count
              if (_getSelectedCount() > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: primaryGreen.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: primaryGreen, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${_getSelectedCount()} item${_getSelectedCount() > 1 ? 's' : ''} selected',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _clearSelection,
                        child: Text(
                          'Clear',
                          style: TextStyle(color: primaryGreen),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final data = item.data() as Map<String, dynamic>;
                    return _buildCartItem(item.id, data);
                  },
                ),
              ),
              _buildCheckoutSection(cartItems),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(String itemId, Map<String, dynamic> data) {
    final quantity = data['quantity'] ?? 1;
    final price = (data['price'] ?? 0.0).toDouble();
    final total = price * quantity;
    final isSelected = _selectedItems[itemId] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Checkbox for selection
            Checkbox(
              value: isSelected,
              onChanged: (value) =>
                  _toggleItemSelection(itemId, value ?? false),
              activeColor: primaryGreen,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),

            const SizedBox(width: 8),

            // Product Image - Made smaller
            Container(
              width: 60, // Reduced from 80
              height: 60, // Reduced from 80
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: data['productImage'] != null &&
                        data['productImage'].isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(data['productImage']),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.grey[200],
              ),
              child:
                  data['productImage'] == null || data['productImage'].isEmpty
                      ? const Icon(Icons.image, color: Colors.grey, size: 24)
                      : null,
            ),

            const SizedBox(width: 12),

            // Product Details - FIXED: More compact layout
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name and price in same row to save space
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          data['productName'] ?? 'Unknown Product',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Reduced from 16
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Unit price
                  Text(
                    '\$${price.toStringAsFixed(2)} each',
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryGreen,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Quantity Controls - FIXED: More compact design
                  Row(
                    children: [
                      // Compact quantity controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Decrease button
                            Container(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                icon: const Icon(Icons.remove, size: 14),
                                onPressed: () =>
                                    _updateQuantity(itemId, quantity - 1),
                                color:
                                    quantity <= 1 ? Colors.grey : primaryGreen,
                                padding: EdgeInsets.zero,
                                iconSize: 14,
                              ),
                            ),

                            // Quantity display
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

                            // Increase button
                            Container(
                              width: 28,
                              height: 28,
                              child: IconButton(
                                icon: const Icon(Icons.add, size: 14),
                                onPressed: () =>
                                    _updateQuantity(itemId, quantity + 1),
                                color: primaryGreen,
                                padding: EdgeInsets.zero,
                                iconSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Delete button
                      Container(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _removeFromCart(itemId),
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

  Widget _buildCheckoutSection(List<QueryDocumentSnapshot> cartItems) {
    final selectedItems = _getSelectedItems(cartItems);
    final hasSelectedItems = selectedItems.isNotEmpty;

    double subtotal = 0;
    double selectedSubtotal = 0;

    // Calculate totals correctly
    for (final item in cartItems) {
      final data = item.data() as Map<String, dynamic>;
      final price = (data['price'] ?? 0.0).toDouble();
      final quantity = data['quantity'] ?? 1;
      final itemTotal = price * quantity;

      subtotal += itemTotal;

      // Only add to selectedSubtotal if item is actually selected
      if (_selectedItems[item.id] == true) {
        selectedSubtotal += itemTotal;
      }
    }

    const shipping = 5.99;
    final total = subtotal + shipping;

    // FIXED: Only calculate selected total if there are selected items
    final selectedTotal =
        (hasSelectedItems ? (selectedSubtotal + shipping) : 0.0) as double;

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
          // FIXED: Always show selected section, but with 0 values when nothing selected
          _buildPriceRow('Selected Items Subtotal',
              hasSelectedItems ? selectedSubtotal : 0),
          _buildPriceRow('Shipping', hasSelectedItems ? shipping : 0),
          const Divider(),
          _buildPriceRow('Selected Total', hasSelectedItems ? selectedTotal : 0,
              isTotal: true),

          const SizedBox(height: 8),

          // Show hint when nothing is selected
          if (!hasSelectedItems && cartItems.isNotEmpty)
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
              // Checkout Selected Button - FIXED: Show even when 0, but disabled
              Expanded(
                child: ElevatedButton(
                  onPressed: hasSelectedItems && !_isLoading
                      ? () => _checkoutSelected(selectedItems)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        hasSelectedItems ? primaryGreen : Colors.grey[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          'Checkout Selected (${_getSelectedCount()})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // Checkout All Button
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _checkoutAll(cartItems),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              color: isTotal ? primaryGreen : Colors.black,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? primaryGreen : Colors.black,
            ),
          ),
        ],
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

    // Simulate checkout process for selected items
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    _showSnackBar(
        'Order placed for ${selectedItems.length} item${selectedItems.length > 1 ? 's' : ''}!');

    // You can add actual checkout logic here for selected items
    // - Create order document with only selected items
    // - Remove selected items from cart
    // - Process payment, etc.
  }

  Future<void> _checkoutAll(List<QueryDocumentSnapshot> cartItems) async {
    if (cartItems.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate checkout process for all items
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    _showSnackBar('Order placed for all ${cartItems.length} items!');

    // You can add actual checkout logic here for all items
    // - Create order document with all cart items
    // - Clear entire cart
    // - Process payment, etc.
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
