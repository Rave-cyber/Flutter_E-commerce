import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/firestore_service.dart';
import 'package:firebase/models/order_model.dart';
import 'package:firebase/views/customer/checkout/order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final bool isSelectedItems;
  final List<String> selectedItemIds;

  const CheckoutScreen({
    Key? key,
    required this.cartItems,
    required this.isSelectedItems,
    required this.selectedItemIds,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final Color primaryGreen = const Color(0xFF2C8610);
  PaymentMethod _selectedPaymentMethod = PaymentMethod.gcash;
  final TextEditingController _shippingAddressController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  bool _isLoading = false;
  String? _customerId;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final customer = await authService.getCustomerData();
    if (customer != null) {
      setState(() {
        _customerId = customer.id;
        _shippingAddressController.text = customer.address;
        _contactNumberController.text = customer.contact;
      });
    }
  }

  @override
  void dispose() {
    _shippingAddressController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return widget.cartItems.fold(0.0, (sum, item) {
      return sum + ((item['price'] ?? 0.0) * (item['quantity'] ?? 1));
    });
  }

  double get _shipping => 5.99;
  double get _total => _subtotal + _shipping;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: primaryGreen,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary Section
                  _buildOrderSummarySection(),
                  const SizedBox(height: 24),
                  
                  // Shipping Information Section
                  _buildShippingSection(),
                  const SizedBox(height: 24),
                  
                  // Payment Method Section
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 24),
                  
                  // Total Summary
                  _buildTotalSummary(),
                  const SizedBox(height: 24),
                  
                  // Place Order Button
                  _buildPlaceOrderButton(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderSummarySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...widget.cartItems.map((item) => _buildOrderItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final quantity = item['quantity'] ?? 1;
    final price = (item['price'] ?? 0.0).toDouble();
    final total = price * quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: item['productImage'] != null &&
                      item['productImage'].toString().isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(item['productImage']),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[200],
            ),
            child: item['productImage'] == null ||
                    item['productImage'].toString().isEmpty
                ? const Icon(Icons.image, color: Colors.grey, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['productName'] ?? 'Unknown Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: $quantity × \$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Total Price
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _shippingAddressController,
              decoration: const InputDecoration(
                labelText: 'Shipping Address',
                hintText: 'Enter your shipping address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contactNumberController,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                hintText: 'Enter your contact number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentOption(
              PaymentMethod.gcash,
              'GCash',
              Icons.account_balance_wallet,
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              PaymentMethod.bankCard,
              'Bank Card',
              Icons.credit_card,
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              PaymentMethod.grabPay,
              'GrabPay',
              Icons.payment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    PaymentMethod method,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedPaymentMethod == method;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? primaryGreen.withOpacity(0.1) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryGreen : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryGreen : Colors.black,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: primaryGreen,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', _subtotal),
            const SizedBox(height: 8),
            _buildPriceRow('Shipping', _shipping),
            const Divider(),
            const SizedBox(height: 8),
            _buildPriceRow('Total', _total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? primaryGreen : Colors.black,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? primaryGreen : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceOrderButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _placeOrder,
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
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Place Order',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    // Validate inputs
    if (_shippingAddressController.text.trim().isEmpty) {
      _showSnackBar('Please enter shipping address');
      return;
    }

    if (_contactNumberController.text.trim().isEmpty) {
      _showSnackBar('Please enter contact number');
      return;
    }

    if (_customerId == null) {
      _showSnackBar('Customer information not found');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null) {
        _showSnackBar('User not logged in');
        return;
      }

      // Create order items list
      final List<Map<String, dynamic>> orderItems = widget.cartItems.map((item) {
        return {
          'productId': item['productId'],
          'productName': item['productName'],
          'productImage': item['productImage'],
          'price': item['price'],
          'quantity': item['quantity'],
        };
      }).toList();

      // Create order in Firestore
      final orderId = await FirestoreService.createOrder(
        userId: user.uid,
        customerId: _customerId!,
        items: orderItems,
        subtotal: _subtotal,
        shipping: _shipping,
        total: _total,
        paymentMethod: _selectedPaymentMethod.name,
        shippingAddress: _shippingAddressController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
      );

      // Remove items from cart
      await FirestoreService.removeCartItems(user.uid, widget.selectedItemIds);

      // Navigate to confirmation screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderConfirmationScreen(
              orderId: orderId,
              total: _total,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error placing order: $e');
        setState(() {
          _isLoading = false;
        });
      }
    }
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

