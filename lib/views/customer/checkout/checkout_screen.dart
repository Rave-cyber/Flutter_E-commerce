import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/firestore_service.dart';
import 'package:firebase/models/order_model.dart';
import 'package:firebase/services/shipping_service.dart';
import 'package:firebase/services/philippine_address_service.dart';
import 'order_confirmation_screen.dart';

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
  final Color secondaryGreen = const Color(0xFF4CAF50);
  final Color lightGreen = const Color(0xFFE8F5E9);
  final Color darkGreen = const Color(0xFF1B5E20);

  PaymentMethod _selectedPaymentMethod = PaymentMethod.gcash;
  final TextEditingController _shippingAddressController =
      TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  bool _isLoading = false;
  String? _customerId;
  String? _customerName;

// Shipping calculation variables
  double _shippingFee = 0.0;
  double _distance = 0.0;
  int _estimatedDays = 3;
  bool _isCalculatingShipping = false;
  final ShippingService _shippingService = ShippingService();

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
        _customerName =
            '${customer.firstname} ${customer.lastname}'.trim(); // ADD THIS
        _shippingAddressController.text = customer.address;
        _contactNumberController.text = customer.contact;
      });

      // Calculate shipping fee based on customer address
      _calculateShippingFee(customer.address, _subtotal);
    }
  }

  Future<void> _calculateShippingFee(String address, double orderTotal) async {
    if (address.isEmpty) return;

    setState(() {
      _isCalculatingShipping = true;
    });

    try {
      final calculation = await _shippingService.calculateShipping(
        fullAddress: address,
        orderTotal: orderTotal,
      );

      setState(() {
        _shippingFee = calculation.shippingFee;
        _distance = calculation.distance;
        _estimatedDays = calculation.estimatedDays;
      });
    } catch (e) {
      // Fallback to default shipping fee
      setState(() {
        _shippingFee = 5.99;
        _distance = 0.0;
        _estimatedDays = 3;
      });
    } finally {
      setState(() {
        _isCalculatingShipping = false;
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

  double get _total => _subtotal + _shippingFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: primaryGreen),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2C8610)),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),

                        // Shipping Address Card
                        _buildAddressCard(),

                        const SizedBox(height: 12),

                        // Items List
                        _buildItemsCard(),

                        const SizedBox(height: 12),

                        // Payment Method Card
                        _buildPaymentCard(),

                        const SizedBox(height: 12),

                        // Order Summary Card
                        _buildOrderSummaryCard(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Bottom Order Button
                _buildBottomOrderButton(),
              ],
            ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: primaryGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Shipping Address',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _showEditAddressSheet,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: primaryGreen.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _shippingAddressController.text.isEmpty
                          ? 'Add your shipping address'
                          : _shippingAddressController.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: _shippingAddressController.text.isEmpty
                            ? Colors.grey[400]
                            : Colors.grey[800],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_contactNumberController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _contactNumberController.text,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Items',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.cartItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == widget.cartItems.length - 1;

            return Column(
              children: [
                _buildItemRow(item),
                if (!isLast) const Divider(height: 24),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItemRow(Map<String, dynamic> item) {
    final quantity = item['quantity'] ?? 1;
    final price = (item['price'] ?? 0.0).toDouble();
    final total = price * quantity;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: item['productImage'] != null &&
                    item['productImage'].toString().isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(item['productImage']),
                    fit: BoxFit.cover,
                  )
                : null,
            color: Colors.grey[100],
          ),
          child: item['productImage'] == null ||
                  item['productImage'].toString().isEmpty
              ? Icon(Icons.shopping_bag, color: Colors.grey[400], size: 24)
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Qty: $quantity',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\₱${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
        ),

        // Total Price
        Text(
          '\₱${total.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // GCash Option
          _buildPaymentMethodTile(
            'GCash',
            'Pay with GCash',
            Icons.account_balance_wallet,
            PaymentMethod.gcash,
            'assets/gcash.png', // Add your asset
          ),

          const SizedBox(height: 12),

          // Bank Card Option
          _buildPaymentMethodTile(
            'Bank Card',
            'Credit/Debit Card',
            Icons.credit_card,
            PaymentMethod.bankCard,
            'assets/card.png', // Add your asset
          ),

          const SizedBox(height: 12),

          // GrabPay Option
          _buildPaymentMethodTile(
            'GrabPay',
            'Pay with GrabPay',
            Icons.payment,
            PaymentMethod.grabPay,
            'assets/grabpay.png', // Add your asset
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    String title,
    String subtitle,
    IconData icon,
    PaymentMethod method,
    String assetImage,
  ) {
    final isSelected = _selectedPaymentMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey[200]!,
            width: 1.5,
          ),
          color: isSelected ? lightGreen : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryGreen.withOpacity(0.1)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryGreen : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? primaryGreen : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? primaryGreen : Colors.grey[400]!,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Price Breakdown
          _buildSummaryRow('Item Total', '\₱${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildSummaryRow(
              'Shipping Fee',
              _isCalculatingShipping
                  ? 'Calculating...'
                  : '\₱${_shippingFee.toStringAsFixed(2)}'),
          if (_distance > 0) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'Distance: ${_distance.toStringAsFixed(1)}km',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),

          const Divider(),
          const SizedBox(height: 12),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\₱${_total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Estimated Delivery
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  color: primaryGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isCalculatingShipping
                        ? 'Calculating delivery...'
                        : 'Estimated delivery: $_estimatedDays business day${_estimatedDays > 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
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

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomOrderButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\₱${_total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Total Payment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
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
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Place Order',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
          ],
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
      final List<Map<String, dynamic>> orderItems =
          widget.cartItems.map((item) {
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
        shipping: _shippingFee,
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
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

 void _showEditAddressSheet() {
  final TextEditingController houseController = TextEditingController();
  final TextEditingController contactController = TextEditingController(
    text: _contactNumberController.text,
  );

  bool saving = false;

  List<Map<String, dynamic>> regions = [];
  List<Map<String, dynamic>> provinces = [];
  List<Map<String, dynamic>> cities = [];
  List<Map<String, dynamic>> barangays = [];

  Map<String, dynamic>? selectedRegion;
  Map<String, dynamic>? selectedProvince;
  Map<String, dynamic>? selectedCity;
  Map<String, dynamic>? selectedBarangay;

  bool loadingRegions = true;
  bool loadingProvinces = false;
  bool loadingCities = false;
  bool loadingBarangays = false;
  bool initialized = false;

  // Helper function to safely update modal state
  void safeModalSetState(VoidCallback fn) {
    if (mounted) {
      setState(() {});
    }
  }

  // Parse existing address
  void parseExistingAddress() {
    final currentAddress = _shippingAddressController.text;
    if (currentAddress.isNotEmpty) {
      final parts = currentAddress.split(', ');
      if (parts.isNotEmpty) {
        houseController.text = parts[0];
      }
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setModalState) {
        // Helper function to safely update modal state
        void safeModalSetState(VoidCallback fn) {
          if (mounted) {
            setModalState(fn);
          }
        }

        if (!initialized) {
          initialized = true;
          parseExistingAddress();
          Future.microtask(() async {
            try {
              final r = await PhilippineAddressService.getRegions();
              if (mounted) {
                safeModalSetState(() {
                  regions = r;
                  loadingRegions = false;
                });
              }
            } catch (e) {
              if (mounted) {
                safeModalSetState(() => loadingRegions = false);
              }
              if (mounted) {
                _showSnackBar('Failed to load regions');
              }
            }
          });
        }

        return GestureDetector(
          onTap: () => FocusScope.of(ctx).unfocus(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Shipping Address',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: primaryGreen,
                              ),
                            ),
                            Text(
                              'Update your delivery location',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Current Address Preview
                    if (_shippingAddressController.text.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: primaryGreen.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Current Address',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _shippingAddressController.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[800],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 20),
                    ],

                    // Form Title
                    Text(
                      'New Shipping Address',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fill in your complete address details',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Contact Number
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Number',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: contactController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'e.g., 09123456789',
                              hintStyle: TextStyle(
                                  color: Colors.grey[600]!.withOpacity(0.6)),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.phone_rounded,
                                color: primaryGreen,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // House/Unit and Street
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'House/Unit and Street',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: houseController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Unit 3B, 123 Sample Street',
                              hintStyle: TextStyle(
                                  color: Colors.grey[600]!.withOpacity(0.6)),
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.home_rounded,
                                color: primaryGreen,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Region Dropdown
                    _buildCheckoutDropdownFormField(
                      value: selectedRegion,
                      label: 'Region',
                      hint: 'Select region',
                      icon: Icons.map_rounded,
                      isLoading: loadingRegions,
                      items: regions
                          .map((region) => DropdownMenuItem(
                                value: region,
                                child: Text(
                                    region['regionName'] ?? region['name']),
                              ))
                          .toList(),
                      onChanged: (value) async {
                        if (!mounted) return;
                        
                        safeModalSetState(() {
                          selectedRegion = value;
                          selectedProvince = null;
                          selectedCity = null;
                          selectedBarangay = null;
                          provinces = [];
                          cities = [];
                          barangays = [];
                          loadingProvinces = true;
                        });
                        
                        if (value != null) {
                          try {
                            final p =
                                await PhilippineAddressService.getProvinces(
                                    value['code']);
                            if (mounted) {
                              safeModalSetState(() {
                                provinces = p;
                                loadingProvinces = false;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              safeModalSetState(() => loadingProvinces = false);
                              _showSnackBar('Failed to load provinces');
                            }
                          }
                        } else {
                          if (mounted) {
                            safeModalSetState(() => loadingProvinces = false);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Province Dropdown
                    _buildCheckoutDropdownFormField(
                      value: selectedProvince,
                      label: 'Province',
                      hint: 'Select province',
                      icon: Icons.place_rounded,
                      isLoading: loadingProvinces,
                      items: provinces
                          .map((province) => DropdownMenuItem(
                                value: province,
                                child: Text(province['name']),
                              ))
                          .toList(),
                      onChanged: (value) async {
                        if (!mounted) return;
                        
                        safeModalSetState(() {
                          selectedProvince = value;
                          selectedCity = null;
                          selectedBarangay = null;
                          cities = [];
                          barangays = [];
                          loadingCities = true;
                        });
                        
                        if (value != null) {
                          try {
                            final c = await PhilippineAddressService
                                .getCitiesMunicipalities(value['code']);
                            if (mounted) {
                              safeModalSetState(() {
                                cities = c;
                                loadingCities = false;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              safeModalSetState(() => loadingCities = false);
                              _showSnackBar('Failed to load cities');
                            }
                          }
                        } else {
                          if (mounted) {
                            safeModalSetState(() => loadingCities = false);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // City/Municipality Dropdown
                    _buildCheckoutDropdownFormField(
                      value: selectedCity,
                      label: 'City/Municipality',
                      hint: 'Select city or municipality',
                      icon: Icons.location_city_rounded,
                      isLoading: loadingCities,
                      items: cities
                          .map((city) => DropdownMenuItem(
                                value: city,
                                child: Text(city['name']),
                              ))
                          .toList(),
                      onChanged: (value) async {
                        if (!mounted) return;
                        
                        safeModalSetState(() {
                          selectedCity = value;
                          selectedBarangay = null;
                          barangays = [];
                          loadingBarangays = true;
                        });
                        
                        if (value != null) {
                          try {
                            final b =
                                await PhilippineAddressService.getBarangays(
                                    value['code']);
                            if (mounted) {
                              safeModalSetState(() {
                                barangays = b;
                                loadingBarangays = false;
                              });
                            }
                          } catch (e) {
                            if (mounted) {
                              safeModalSetState(() => loadingBarangays = false);
                              _showSnackBar('Failed to load barangays');
                            }
                          }
                        } else {
                          if (mounted) {
                            safeModalSetState(() => loadingBarangays = false);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Barangay Dropdown
                    _buildCheckoutDropdownFormField(
                      value: selectedBarangay,
                      label: 'Barangay',
                      hint: 'Select barangay',
                      icon: Icons.home_work_rounded,
                      isLoading: loadingBarangays,
                      items: barangays
                          .map((brgy) => DropdownMenuItem(
                                value: brgy,
                                child: Text(brgy['name']),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (mounted) {
                          safeModalSetState(() {
                            selectedBarangay = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    final house = houseController.text.trim();
                                    final contact = contactController.text.trim();

                                    // Validation
                                    if (contact.isEmpty) {
                                      if (mounted) {
                                        _showSnackBar('Please enter contact number');
                                      }
                                      return;
                                    }
                                    if (selectedRegion == null ||
                                        selectedProvince == null ||
                                        selectedCity == null ||
                                        selectedBarangay == null) {
                                      if (mounted) {
                                        _showSnackBar(
                                            'Please select all address fields');
                                      }
                                      return;
                                    }
                                    if (house.isEmpty) {
                                      if (mounted) {
                                        _showSnackBar(
                                            'Please enter house/unit and street');
                                      }
                                      return;
                                    }

                                    if (mounted) {
                                      safeModalSetState(() => saving = true);
                                    }
                                    
                                    try {
                                      final parts = <String>[];
                                      parts.add(house);

                                      if (selectedBarangay != null) {
                                        parts.add(
                                            'Brgy. ${selectedBarangay!['name']}');
                                      }

                                      parts.add(selectedCity!['name']);
                                      parts.add(selectedProvince!['name']);
                                      parts.add(
                                          selectedRegion!['regionName'] ??
                                              selectedRegion!['name']);

                                      final finalAddress = parts.join(', ');

                                      final auth = Provider.of<AuthService>(
                                          context,
                                          listen: false);
                                      final user = auth.currentUser;
                                      if (user == null) throw 'Not logged in';

                                      final fs = FirebaseFirestore.instance;
                                      final query = await fs
                                          .collection('customers')
                                          .where('user_id',
                                              isEqualTo: user.uid)
                                          .limit(1)
                                          .get();

                                      if (query.docs.isNotEmpty) {
                                        await fs
                                            .collection('customers')
                                            .doc(query.docs.first.id)
                                            .update({
                                          'address': finalAddress,
                                          'contact': contact,
                                          'updated_at':
                                              FieldValue.serverTimestamp(),
                                        });
                                      } else {
                                        await fs.collection('customers').add({
                                          'user_id': user.uid,
                                          'firstname': '',
                                          'middlename': '',
                                          'lastname': '',
                                          'address': finalAddress,
                                          'contact': contact,
                                          'created_at':
                                              FieldValue.serverTimestamp(),
                                          'updated_at':
                                              FieldValue.serverTimestamp(),
                                        });
                                      }

                                      // Update local state
                                      if (mounted) {
                                        setState(() {
                                          _shippingAddressController.text =
                                              finalAddress;
                                          _contactNumberController.text =
                                              contact;
                                        });
                                        await _calculateShippingFee(
                                            finalAddress, _subtotal);
                                      }

                                      if (mounted) {
                                        Navigator.pop(ctx);
                                        _showSnackBar(
                                            '✅ Address updated successfully!');
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        _showSnackBar(
                                            '❌ Failed to update address: ${e.toString()}');
                                        safeModalSetState(() => saving = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: saving
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_rounded, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Save Address',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      });
    },
  );
}
Widget _buildCheckoutDropdownFormField({
  required Map<String, dynamic>? value,
  required String label,
  required String hint,
  required IconData icon,
  required bool isLoading,
  required List<DropdownMenuItem<Map<String, dynamic>>> items,
  required Function(Map<String, dynamic>?) onChanged,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonFormField<Map<String, dynamic>>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(primaryGreen),
                      ),
                    )
                  : Icon(icon, color: primaryGreen),
            ),
            hint: Text(
              isLoading ? 'Loading...' : hint,
              style: TextStyle(
                color: isLoading ? primaryGreen : Colors.grey[600]!.withOpacity(0.6),
              ),
            ),
            items: items,
            onChanged: onChanged,
            dropdownColor: Colors.white,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[800],
            ),
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              color: primaryGreen,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ],
  );
}
}