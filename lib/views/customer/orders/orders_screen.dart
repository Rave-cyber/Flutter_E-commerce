import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/firestore_service.dart';
import 'package:firebase/views/customer/orders/order_detail_screen.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // Using #2C8610 green as specified
  final Color primaryGreen = const Color(0xFF2C8610);
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
              Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: primaryGreen.withOpacity(0.7),
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
              _buildFilterChips(),
              _buildOrdersList(filteredOrders, context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _statusFilters.length,
        itemBuilder: (context, index) {
          final status = _statusFilters[index];
          final isSelected = _selectedStatus == status;
          final config = _getStatusConfig(status == 'all' ? 'all' : status);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                status == 'all' ? 'All' : config['text'],
                style: TextStyle(
                  color: isSelected ? Colors.white : textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedStatus = selected ? status : 'all';
                });
              },
              backgroundColor: Colors.white,
              selectedColor: config['backgroundColor'],
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(dynamic error, BuildContext context) {
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
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: primaryGreen.withOpacity(0.5),
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

    final statusConfig = _getStatusConfig(status);

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

              // Footer with status and total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusConfig['backgroundColor'],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 12,
                          color: statusConfig['color'],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusConfig['text'],
                          style: TextStyle(
                            color: statusConfig['color'],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
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

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return {
          'backgroundColor': const Color(0xFFF1F5F9),
          'color': const Color(0xFF64748B),
          'text': 'All',
        };
      case 'pending':
        return {
          'backgroundColor': const Color(0xFFFFF7ED),
          'color': const Color(0xFF9A3412),
          'text': 'Pending',
        };
      case 'confirmed':
        return {
          'backgroundColor': const Color(0xFFE0F2FE),
          'color': const Color(0xFF0369A1),
          'text': 'Confirmed',
        };
      case 'processing':
        return {
          'backgroundColor': const Color(0xFFF3E8FF),
          'color': const Color(0xFF7C3AED),
          'text': 'Processing',
        };
      case 'shipped':
        return {
          'backgroundColor': const Color(0xFFE0E7FF),
          'color': const Color(0xFF4338CA),
          'text': 'Shipped',
        };
      case 'delivered':
        return {
          'backgroundColor': const Color(0xFFDCFCE7),
          'color': const Color(0xFF166534),
          'text': 'Delivered',
        };
      case 'cancelled':
        return {
          'backgroundColor': const Color(0xFFFEE2E2),
          'color': const Color(0xFFB91C1C),
          'text': 'Cancelled',
        };
      default:
        return {
          'backgroundColor': Colors.grey[100]!,
          'color': Colors.grey[800]!,
          'text': status,
        };
    }
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
                  final config =
                      _getStatusConfig(status == 'all' ? 'all' : status);
                  final isSelected = _selectedStatus == status;
                  return FilterChip(
                    label: Text(
                      status == 'all' ? 'All Orders' : config['text'],
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
                    selectedColor: config['backgroundColor'],
                    checkmarkColor: isSelected ? config['color'] : null,
                    side: BorderSide(
                      color: isSelected
                          ? config['backgroundColor']!
                          : Colors.grey[300]!,
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
                    backgroundColor: Colors.grey[50],
                  ),
                  child: Text(
                    'Clear Filter',
                    style: TextStyle(
                      color: textPrimary,
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
