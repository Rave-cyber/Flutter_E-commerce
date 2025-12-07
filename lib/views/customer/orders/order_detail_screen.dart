import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firestore_service.dart';
import 'package:firebase/models/order_model.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2C8610);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: primaryGreen,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: FirestoreService.getOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading order details',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final order = snapshot.data;
          if (order == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Order not found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header Card
                _buildOrderHeaderCard(order, primaryGreen),
                const SizedBox(height: 16),

                // Order Items
                _buildOrderItemsCard(order, primaryGreen),
                const SizedBox(height: 16),

                // Shipping Information
                _buildShippingCard(order, primaryGreen),
                const SizedBox(height: 16),

                // Payment Information
                _buildPaymentCard(order, primaryGreen),
                const SizedBox(height: 16),

                // Order Summary
                _buildOrderSummaryCard(order, primaryGreen),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderHeaderCard(
      Map<String, dynamic> order, Color primaryGreen) {
    final status = order['status'] ?? 'pending';
    final createdAt = order['createdAt'] as Timestamp?;
    String dateText = 'Date not available';
    if (createdAt != null) {
      dateText = DateFormat('MMMM dd, yyyy • hh:mm a').format(createdAt.toDate());
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${orderId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsCard(
      Map<String, dynamic> order, Color primaryGreen) {
    final items = order['items'] as List<dynamic>? ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _buildOrderItem(
                  item as Map<String, dynamic>,
                  primaryGreen,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item, Color primaryGreen) {
    final quantity = item['quantity'] ?? 1;
    final price = (item['price'] ?? 0.0).toDouble();
    final total = price * quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
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
                ? const Icon(Icons.image, color: Colors.grey, size: 32)
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Quantity: $quantity',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Price: \$${price.toStringAsFixed(2)} each',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Total
          Text(
            '\$${total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingCard(
      Map<String, dynamic> order, Color primaryGreen) {
    final shippingAddress = order['shippingAddress'] ?? 'Not provided';
    final contactNumber = order['contactNumber'] ?? 'Not provided';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: primaryGreen),
                const SizedBox(width: 8),
                const Text(
                  'Shipping Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Address', shippingAddress),
            const SizedBox(height: 12),
            _buildInfoRow('Contact', contactNumber),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(
      Map<String, dynamic> order, Color primaryGreen) {
    final paymentMethod = order['paymentMethod'] ?? 'gcash';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getPaymentIcon(paymentMethod), color: primaryGreen),
                const SizedBox(width: 8),
                const Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Payment Method', _formatPaymentMethod(paymentMethod)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(
      Map<String, dynamic> order, Color primaryGreen) {
    final subtotal = (order['subtotal'] ?? 0.0).toDouble();
    final shipping = (order['shipping'] ?? 0.0).toDouble();
    final total = (order['total'] ?? 0.0).toDouble();

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
            _buildSummaryRow('Subtotal', subtotal),
            const SizedBox(height: 8),
            _buildSummaryRow('Shipping', shipping),
            const Divider(),
            const SizedBox(height: 8),
            _buildSummaryRow('Total', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF2C8610) : Colors.black,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF2C8610) : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange[700]!;
        statusText = 'Pending';
        break;
      case 'confirmed':
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue[700]!;
        statusText = 'Confirmed';
        break;
      case 'processing':
        backgroundColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple[700]!;
        statusText = 'Processing';
        break;
      case 'shipped':
        backgroundColor = Colors.indigo.withOpacity(0.1);
        textColor = Colors.indigo[700]!;
        statusText = 'Shipped';
        break;
      case 'delivered':
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green[700]!;
        statusText = 'Delivered';
        break;
      case 'cancelled':
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[700]!;
        statusText = 'Cancelled';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[700]!;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'gcash':
        return Icons.account_balance_wallet;
      case 'bankcard':
        return Icons.credit_card;
      case 'grabpay':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  String _formatPaymentMethod(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'gcash':
        return 'GCash';
      case 'bankcard':
        return 'Bank Card';
      case 'grabpay':
        return 'GrabPay';
      default:
        return paymentMethod;
    }
  }
}

