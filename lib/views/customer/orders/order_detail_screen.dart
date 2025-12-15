import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firestore_service.dart';
<<<<<<< HEAD
import 'package:firebase/models/order_model.dart';
import 'package:intl/intl.dart';
=======
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

class OrderDetailScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2C8610);
<<<<<<< HEAD
    final Color accentBlue = const Color(0xFF4A90E2);
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
    final Color backgroundColor = const Color(0xFFF8FAFC);
    final Color cardColor = Colors.white;
    final Color textPrimary = const Color(0xFF1A1A1A);
    final Color textSecondary = const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Order Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: primaryGreen,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: primaryGreen,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: FirestoreService.getOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Order Details',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Unable to Load Order',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Please check your connection and try again',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go Back',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Order Not Found',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'The order you\'re looking for doesn\'t exist',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back to Orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                _buildOrderHeader(
                    order, primaryGreen, cardColor, textPrimary, textSecondary),
                const SizedBox(height: 20),

                // Status Timeline
                _buildStatusTimeline(
                    order, primaryGreen, cardColor, textPrimary),
                const SizedBox(height: 20),

                // Order Items
                _buildOrderItems(
                    order, primaryGreen, cardColor, textPrimary, textSecondary),
                const SizedBox(height: 20),

                // Order Summary
                _buildOrderSummary(
                    order, primaryGreen, cardColor, textPrimary, textSecondary),
<<<<<<< HEAD
=======
                const SizedBox(height: 12),
                _buildReceiptActions(context, order, primaryGreen, textPrimary),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                const SizedBox(height: 20),

                // Shipping Information
                _buildShippingInfo(
                    order, primaryGreen, cardColor, textPrimary, textSecondary),
                const SizedBox(height: 20),

                // Payment Information
                _buildPaymentInfo(
                    order, primaryGreen, cardColor, textPrimary, textSecondary),
                const SizedBox(height: 20),

                // Action Buttons
                if (order['status']?.toString().toLowerCase() == 'pending')
                  _buildActionButtons(context, primaryGreen, textSecondary),
              ],
            ),
          );
        },
      ),
    );
  }

<<<<<<< HEAD
=======
  Widget _buildReceiptActions(BuildContext context, Map<String, dynamic> order,
      Color primaryGreen, Color textPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _downloadReceipt(context, order, primaryGreen),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          icon: const Icon(Icons.receipt_long, size: 18),
          label: const Text(
            'Download Receipt',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

>>>>>>> 3add35312551b90752a2c004e342857fcb126663
  Widget _buildOrderHeader(
    Map<String, dynamic> order,
    Color primaryGreen,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final createdAt = order['createdAt'] as Timestamp?;
    String dateText = 'Date not available';
    if (createdAt != null) {
      dateText =
          DateFormat('MMMM dd, yyyy • hh:mm a').format(createdAt.toDate());
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${orderId.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              dateText,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(order['status'] ?? 'pending'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[100]!,
                    Colors.grey[300]!,
                    Colors.grey[100]!,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
<<<<<<< HEAD
                      '\$${(order['total'] ?? 0.0).toStringAsFixed(2)}',
=======
                      '\₱${(order['total'] ?? 0.0).toStringAsFixed(2)}',
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: primaryGreen,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getPaymentIcon(order['paymentMethod'] ?? 'gcash'),
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatPaymentMethod(order['paymentMethod'] ?? 'gcash'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: config['backgroundColor'],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: config['borderColor'] ?? config['backgroundColor'],
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config['icon'],
            size: 16,
            color: config['color'],
          ),
          const SizedBox(width: 8),
          Text(
            config['text'],
            style: TextStyle(
              color: config['color'],
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTimeline(
    Map<String, dynamic> order,
    Color primaryGreen,
    Color cardColor,
    Color textPrimary,
  ) {
    final status = order['status']?.toString().toLowerCase() ?? 'pending';
    final timelineSteps = [
      {
        'status': 'pending',
        'icon': Icons.access_time_rounded,
        'label': 'Order Placed'
      },
      {
        'status': 'confirmed',
        'icon': Icons.check_circle_outline_rounded,
        'label': 'Confirmed'
      },
      {
        'status': 'processing',
        'icon': Icons.settings_outlined,
        'label': 'Processing'
      },
      {
        'status': 'shipped',
        'icon': Icons.local_shipping_rounded,
        'label': 'Shipped'
      },
      {
        'status': 'delivered',
        'icon': Icons.done_all_rounded,
        'label': 'Delivered'
      },
    ];

    final currentIndex =
        timelineSteps.indexWhere((step) => step['status'] == status);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ...timelineSteps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCompleted = index <= currentIndex;
              final isLast = index == timelineSteps.length - 1;

              return Column(
                children: [
                  Row(
                    children: [
                      // Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted ? primaryGreen : Colors.grey[200],
                          border: Border.all(
                            color:
                                isCompleted ? primaryGreen : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          size: 20,
                          color: isCompleted ? Colors.white : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Label and status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['label'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? textPrimary
                                    : Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isCompleted ? 'Completed' : 'Pending',
                              style: TextStyle(
                                fontSize: 13,
                                color: isCompleted
                                    ? primaryGreen
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Connector line
                  if (!isLast)
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                      child: Container(
                        width: 2,
                        height: 24,
                        color: isCompleted ? primaryGreen : Colors.grey[200],
                      ),
                    ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(
    Map<String, dynamic> order,
    Color primaryGreen,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final items = order['items'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            ...items
                .map((item) => _buildOrderItem(
                      item as Map<String, dynamic>,
                      primaryGreen,
                      textSecondary,
                    ))
                .toList(),
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[100]!,
                    Colors.grey[300]!,
                    Colors.grey[100]!,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Items',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                Text(
                  '${items.length} item${items.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(
    Map<String, dynamic> item,
    Color primaryGreen,
    Color textSecondary,
  ) {
    final quantity = item['quantity'] ?? 1;
    final price = (item['price'] ?? 0.0).toDouble();
    final total = price * quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
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
                ? Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.grey[400],
                    size: 32,
                  )
                : null,
          ),
          const SizedBox(width: 16),

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['productName'] ?? 'Unknown Product',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Qty: $quantity',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
<<<<<<< HEAD
                      '\$${price.toStringAsFixed(2)} each',
=======
                      '\₱${price.toStringAsFixed(2)} each',
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Total
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
<<<<<<< HEAD
                '\$${total.toStringAsFixed(2)}',
=======
                '\₱${total.toStringAsFixed(2)}',
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(
    Map<String, dynamic> order,
    Color primaryGreen,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final subtotal = (order['subtotal'] ?? 0.0).toDouble();
    final shipping = (order['shipping'] ?? 0.0).toDouble();
    final total = (order['total'] ?? 0.0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildSummaryRow('Subtotal', subtotal, textPrimary, textSecondary),
            const SizedBox(height: 12),
            _buildSummaryRow('Shipping', shipping, textPrimary, textSecondary),
            const SizedBox(height: 16),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey[100]!,
                    Colors.grey[300]!,
                    Colors.grey[100]!,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                Text(
<<<<<<< HEAD
                  '\$${total.toStringAsFixed(2)}',
=======
                  '\₱${total.toStringAsFixed(2)}',
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: primaryGreen,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfo(
    Map<String, dynamic> order,
    Color primaryGreen,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final shippingAddress = order['shippingAddress'] ?? 'Not provided';
    final contactNumber = order['contactNumber'] ?? 'Not provided';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Shipping Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoItem(
              icon: Icons.home_rounded,
              label: 'Delivery Address',
              value: shippingAddress,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.phone_rounded,
              label: 'Contact Number',
              value: contactNumber,
              textSecondary: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo(
    Map<String, dynamic> order,
    Color primaryGreen,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final paymentMethod = order['paymentMethod'] ?? 'gcash';

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getPaymentIcon(paymentMethod),
                    size: 20,
                    color: primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoItem(
              icon: Icons.payment_rounded,
              label: 'Payment Method',
              value: _formatPaymentMethod(paymentMethod),
              textSecondary: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color textSecondary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[400],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      BuildContext context, Color primaryGreen, Color textSecondary) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Handle cancel order
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
<<<<<<< HEAD
                borderRadius: BorderRadius.circular(16),
=======
                borderRadius: BorderRadius.circular(8),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
              ),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: Text(
              'Cancel Order',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Handle track order
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
<<<<<<< HEAD
                borderRadius: BorderRadius.circular(16),
=======
                borderRadius: BorderRadius.circular(8),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
              ),
            ),
            child: const Text(
              'Track Order',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
      String label, double amount, Color textPrimary, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: textSecondary,
          ),
        ),
        Text(
<<<<<<< HEAD
          '\$${amount.toStringAsFixed(2)}',
=======
          '\₱${amount.toStringAsFixed(2)}',
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {
          'backgroundColor': Colors.orange.withOpacity(0.1),
          'color': Colors.orange[700]!,
          'borderColor': Colors.orange.withOpacity(0.3),
          'icon': Icons.access_time_rounded,
          'text': 'Pending',
        };
      case 'confirmed':
        return {
          'backgroundColor': Colors.blue.withOpacity(0.1),
          'color': Colors.blue[700]!,
          'borderColor': Colors.blue.withOpacity(0.3),
          'icon': Icons.check_circle_outline_rounded,
          'text': 'Confirmed',
        };
      case 'processing':
        return {
          'backgroundColor': Colors.purple.withOpacity(0.1),
          'color': Colors.purple[700]!,
          'borderColor': Colors.purple.withOpacity(0.3),
          'icon': Icons.settings_outlined,
          'text': 'Processing',
        };
      case 'shipped':
        return {
          'backgroundColor': Colors.indigo.withOpacity(0.1),
          'color': Colors.indigo[700]!,
          'borderColor': Colors.indigo.withOpacity(0.3),
          'icon': Icons.local_shipping_rounded,
          'text': 'Shipped',
        };
      case 'delivered':
        return {
          'backgroundColor': Colors.green.withOpacity(0.1),
          'color': Colors.green[700]!,
          'borderColor': Colors.green.withOpacity(0.3),
          'icon': Icons.done_all_rounded,
          'text': 'Delivered',
        };
      case 'cancelled':
        return {
          'backgroundColor': Colors.red.withOpacity(0.1),
          'color': Colors.red[700]!,
          'borderColor': Colors.red.withOpacity(0.3),
          'icon': Icons.cancel_outlined,
          'text': 'Cancelled',
        };
      default:
        return {
          'backgroundColor': Colors.grey.withOpacity(0.1),
          'color': Colors.grey[700]!,
          'borderColor': Colors.grey.withOpacity(0.3),
          'icon': Icons.help_outline_rounded,
          'text': status,
        };
    }
  }

  IconData _getPaymentIcon(String paymentMethod) {
    switch (paymentMethod.toLowerCase()) {
      case 'gcash':
        return Icons.account_balance_wallet_rounded;
      case 'bankcard':
        return Icons.credit_card_rounded;
      case 'grabpay':
        return Icons.payment_rounded;
      default:
        return Icons.payment_rounded;
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
<<<<<<< HEAD
=======

  Future<void> _downloadReceipt(BuildContext context,
      Map<String, dynamic> order, Color primaryGreen) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryGreen),
              const SizedBox(height: 16),
              const Text('Generating receipt...'),
            ],
          ),
        ),
      ),
    );

    try {
      final receiptText = _generateReceiptText(order);

      if (Platform.isAndroid || Platform.isIOS) {
        final Directory tempDir = await getTemporaryDirectory();
        final File file =
            File('${tempDir.path}/receipt_order_${order['id']}.txt');
        await file.writeAsString(receiptText);

        Navigator.pop(context); // close loading

        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'Receipt for Order #${order['id'].toString().substring(0, 8).toUpperCase()}',
        );
      } else {
        Navigator.pop(context); // close loading

        await Clipboard.setData(ClipboardData(text: receiptText));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Receipt copied to clipboard'),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download receipt: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _generateReceiptText(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final total = (order['total'] ?? 0.0).toDouble();
    final orderId = order['id'] ?? '';
    final createdAt = order['createdAt'] as Timestamp?;
    final deliveredAt = order['deliveredAt'] as Timestamp?;
    final confirmedAt = order['confirmedAt'] as Timestamp?;

    StringBuffer sb = StringBuffer();

    sb.writeln('=' * 40);
    sb.writeln('            ORDER RECEIPT');
    sb.writeln('=' * 40);
    sb.writeln();
    sb.writeln(
        'Order ID: #${orderId.toString().substring(0, 8).toUpperCase()}');
    sb.writeln(
        'Date: ${createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate()) : 'N/A'}');
    if (confirmedAt != null) {
      sb.writeln(
          'Confirmed: ${DateFormat('yyyy-MM-dd').format(confirmedAt.toDate())}');
    }
    if (deliveredAt != null) {
      sb.writeln(
          'Delivered: ${DateFormat('yyyy-MM-dd').format(deliveredAt.toDate())}');
    }
    sb.writeln();
    sb.writeln('-' * 40);
    sb.writeln('Items');
    sb.writeln('-' * 40);

    for (var item in items) {
      final itemMap = item as Map<String, dynamic>;
      final price = (itemMap['price'] ?? 0.0).toDouble();
      final quantity = itemMap['quantity'] ?? 1;
      final subtotal = price * quantity;

      sb.writeln('${itemMap['productName']}');
      sb.writeln(
          '  ${quantity.toString().padLeft(2)} x \₱${price.toStringAsFixed(2)} = \₱${subtotal.toStringAsFixed(2)}');
    }

    sb.writeln();
    sb.writeln('-' * 40);
    sb.writeln('Total: \₱${total.toStringAsFixed(2)}');
    sb.writeln('=' * 40);
    sb.writeln();
    sb.writeln('Thank you for your purchase!');
    sb.writeln(
        'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');

    return sb.toString();
  }
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
}
