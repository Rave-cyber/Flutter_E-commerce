import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/firestore_service.dart';
import 'package:firebase/views/customer/orders/order_detail_screen.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Using #2C8610 green as specified
  final Color primaryGreen = const Color(0xFF2C8610);
  final Color lightGreen = const Color(0xFFE8F5E9);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color textPrimary = const Color(0xFF1A1A1A);
  final Color textSecondary = const Color(0xFF64748B);

  String _selectedStatus = 'all';
  final List<String> _statusFilters = [
    'all',
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled'
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;

    if (user == null) {
      return _buildAuthRequiredScreen(context);
    }

    return _buildOrdersScreen(context, user);
  }

  Scaffold _buildAuthRequiredScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: TextStyle(color: textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/auth_required.json',
                height: 150,
                width: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                'Sign In Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Please sign in to view your order history',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Scaffold _buildOrdersScreen(BuildContext context, user) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Order History',
          style: TextStyle(color: textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () => _showFilterBottomSheet(context),
            icon: Icon(Icons.filter_list, color: primaryGreen),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreService.getUserOrders(user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: primaryGreen));
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error, context);
          }

          final allOrders = snapshot.data ?? [];
          final filteredOrders = _selectedStatus == 'all'
              ? allOrders
              : allOrders
                  .where((order) =>
                      (order['status'] ?? '').toString().toLowerCase() ==
                      _selectedStatus)
                  .toList();

          if (filteredOrders.isEmpty) {
            return _buildEmptyState(context, allOrders.isEmpty);
          }

          return Column(
            children: [
              _buildGreenFilterChips(),
              _buildOrdersList(filteredOrders, context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGreenFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusFilters.map((status) {
            final isSelected = _selectedStatus == status;
            final label = status == 'all' ? 'All' : _capitalize(status);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : primaryGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedStatus = selected ? status : 'all';
                  });
                },
                backgroundColor: lightGreen,
                selectedColor: primaryGreen,
                side: BorderSide(
                  color:
                      isSelected ? primaryGreen : primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Widget _buildErrorState(dynamic error, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/box_empty.json',
              height: 120,
              width: 120,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Orders',
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

  Widget _buildEmptyState(BuildContext context, bool noOrders) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              noOrders
                  ? 'assets/animations/Box empty.json'
                  : 'assets/animations/Empty Cart.json',
              height: 200,
              width: 200,
              repeat: true,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            Text(
              noOrders ? 'No Orders Yet' : 'No Matching Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noOrders
                  ? 'Your orders will appear here'
                  : 'Try changing your filter',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
            ),
            if (noOrders) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Start Shopping',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(
      List<Map<String, dynamic>> orders, BuildContext context) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: orders.length,
        itemBuilder: (context, index) =>
            _buildOrderCard(orders[index], context),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, BuildContext context) {
    final orderId = order['id'] ?? '';
    final status = order['status'] ?? 'pending';
    final total = (order['total'] ?? 0.0).toDouble();
    final items = order['items'] as List<dynamic>? ?? [];
    final createdAt = order['createdAt'] as Timestamp?;
    final dateText = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
        : '';
    final deliveredAt = order['deliveredAt'] as Timestamp?;

    final statusText = _capitalize(status);
    final isDelivered = status.toLowerCase() == 'delivered';
    final isConfirmed = status.toLowerCase() == 'confirmed';

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
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: orderId)),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order number and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${orderId.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Order items preview
              if (items.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildItemPreview(items.first),
                    if (items.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '+ ${items.length - 1} more item${items.length - 1 > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),

              // Delivery date if delivered
              if (isDelivered && deliveredAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        size: 14,
                        color: primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Delivered on ${DateFormat('MMM dd, yyyy').format(deliveredAt.toDate())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),

              // Footer with status, total, and receipt button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 12,
                          color: primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryGreen,
                        ),
                      ),
                      // Changed from isDelivered to isConfirmed
                      if (isConfirmed) ...[
                        const SizedBox(width: 12),
                        _buildReceiptButton(order),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptButton(Map<String, dynamic> order) {
    return GestureDetector(
      onTap: () => _showReceiptOptions(context, order),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: primaryGreen,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryGreen.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              'Receipt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemPreview(dynamic item) {
    final itemMap = item as Map<String, dynamic>;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            image: itemMap['productImage']?.toString().isNotEmpty == true
                ? DecorationImage(
                    image: NetworkImage(itemMap['productImage']),
                    fit: BoxFit.cover,
                  )
                : null,
            color: Colors.grey[100],
          ),
          child: itemMap['productImage'] == null
              ? Icon(Icons.image, color: Colors.grey[300], size: 16)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemMap['productName'] ?? 'Unknown Product',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Qty: ${itemMap['quantity'] ?? 1}',
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'confirmed':
        return Icons.check_circle;
      case 'processing':
        return Icons.autorenew;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  void _showReceiptOptions(BuildContext context, Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Receipt Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Order #${order['id'].toString().substring(0, 8).toUpperCase()}',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // View Receipt Option
              _buildReceiptOption(
                icon: Icons.remove_red_eye,
                title: 'View Receipt',
                subtitle: 'View detailed receipt for this order',
                onTap: () => _viewReceipt(context, order),
                color: primaryGreen,
              ),

              const SizedBox(height: 16),

              // Download Receipt Option
              _buildReceiptOption(
                icon: Icons.download,
                title: 'Download Receipt',
                subtitle: 'Save receipt as PDF file',
                onTap: () => _downloadReceipt(context, order),
                color: primaryGreen,
              ),

              const SizedBox(height: 16),

              // Share Receipt Option
              _buildReceiptOption(
                icon: Icons.share,
                title: 'Share Receipt',
                subtitle: 'Share via email or other apps',
                onTap: () => _shareReceipt(context, order),
                color: primaryGreen,
              ),

              const SizedBox(height: 24),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textPrimary,
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReceiptOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewReceipt(BuildContext context, Map<String, dynamic> order) {
    Navigator.pop(context); // Close bottom sheet

    // Navigate to a receipt view screen or show dialog
    showDialog(
      context: context,
      builder: (context) => _buildReceiptDialog(context, order),
    );
  }

  Widget _buildReceiptDialog(BuildContext context, Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final total = (order['total'] ?? 0.0).toDouble();
    final orderId = order['id'] ?? '';
    final createdAt = order['createdAt'] as Timestamp?;
    final deliveredAt = order['deliveredAt'] as Timestamp?;
    final confirmedAt =
        order['confirmedAt'] as Timestamp?; // Added confirmed timestamp

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Receipt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Receipt Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${orderId.toString().substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order Date: ${createdAt != null ? DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt.toDate()) : 'N/A'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                  if (confirmedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Confirmed: ${DateFormat('MMM dd, yyyy').format(confirmedAt.toDate())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryGreen, // Green color for confirmation
                      ),
                    ),
                  ],
                  if (deliveredAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Delivered: ${DateFormat('MMM dd, yyyy').format(deliveredAt.toDate())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Order Items
            Text(
              'Items',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            ...items.map<Widget>((item) {
              final itemMap = item as Map<String, dynamic>;
              final price = (itemMap['price'] ?? 0.0).toDouble();
              final quantity = itemMap['quantity'] ?? 1;
              final subtotal = price * quantity;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${itemMap['productName'] ?? 'Item'} x$quantity',
                        style: TextStyle(
                          fontSize: 13,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '\$${subtotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const Divider(height: 24),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: primaryGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _downloadReceipt(context, order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Download PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReceipt(
      BuildContext context, Map<String, dynamic> order) async {
    Navigator.pop(context); // Close any open dialogs

    // Show loading
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
              Text(
                'Generating receipt...',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // In a real app, you would generate a PDF here
      // For now, we'll create a simple text file
      final receiptText = _generateReceiptText(order);

      if (Platform.isAndroid || Platform.isIOS) {
        final Directory tempDir = await getTemporaryDirectory();
        final File file =
            File('${tempDir.path}/receipt_order_${order['id']}.txt');
        await file.writeAsString(receiptText);

        Navigator.pop(context); // Close loading dialog

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text:
              'Receipt for Order #${order['id'].toString().substring(0, 8).toUpperCase()}',
        );
      } else {
        Navigator.pop(context); // Close loading dialog

        // For web/desktop, copy to clipboard
        await Clipboard.setData(ClipboardData(text: receiptText));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Receipt copied to clipboard'),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download receipt: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareReceipt(
      BuildContext context, Map<String, dynamic> order) async {
    Navigator.pop(context); // Close bottom sheet

    final receiptText = _generateReceiptText(order);

    if (Platform.isAndroid || Platform.isIOS) {
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/receipt_${order['id']}.txt');
      await file.writeAsString(receiptText);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject:
            'Receipt for Order #${order['id'].toString().substring(0, 8).toUpperCase()}',
        text: 'Here is your receipt for your recent order.',
      );
    } else {
      await Clipboard.setData(ClipboardData(text: receiptText));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Receipt copied to clipboard'),
          backgroundColor: primaryGreen,
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
          '  ${quantity.toString().padLeft(2)} x \$${price.toStringAsFixed(2)} = \$${subtotal.toStringAsFixed(2)}');
    }

    sb.writeln();
    sb.writeln('-' * 40);
    sb.writeln('Total: \$${total.toStringAsFixed(2)}');
    sb.writeln('=' * 40);
    sb.writeln();
    sb.writeln('Thank you for your purchase!');
    sb.writeln(
        'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');

    return sb.toString();
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Filter Orders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select status to filter orders',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _statusFilters.map((status) {
                  final isSelected = _selectedStatus == status;
                  final label =
                      status == 'all' ? 'All Orders' : _capitalize(status);

                  return FilterChip(
                    label: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? status : 'all';
                      });
                      Navigator.pop(context);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: primaryGreen,
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? primaryGreen : Colors.grey[300]!,
                      width: 1,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = 'all';
                    });
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: lightGreen,
                  ),
                  child: Text(
                    'Clear Filter',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
