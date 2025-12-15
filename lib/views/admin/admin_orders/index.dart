<<<<<<< HEAD
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../firestore_service.dart';
import '../../../layouts/admin_layout.dart';
import '../../../widgets/order_details_modal.dart';
import '../../../widgets/order_filter_widget.dart';
import '../../../widgets/order_pagination_widget.dart';
import '../../../widgets/order_search_widget.dart';
=======
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firestore_service.dart';
import 'package:intl/intl.dart';
import '../../../layouts/admin_layout.dart';
import '../../../widgets/product_search_widget.dart';
import '../../../widgets/product_pagination_widget.dart';
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

class AdminOrdersIndex extends StatefulWidget {
  const AdminOrdersIndex({Key? key}) : super(key: key);

  @override
  State<AdminOrdersIndex> createState() => _AdminOrdersIndexState();
}

class _AdminOrdersIndexState extends State<AdminOrdersIndex> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all';
  int _itemsPerPage = 10;
  int _currentPage = 1;

  final List<String> _statusFilters = [
    'all',
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

<<<<<<< HEAD
=======
  // Cache for customer names to avoid repeated lookups
  final Map<String, String> _customerNameCache = {};

>>>>>>> 3add35312551b90752a2c004e342857fcb126663
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

<<<<<<< HEAD
  List<Map<String, dynamic>> _getFilteredOrders(
=======
  List<Map<String, dynamic>> _applyFilterSearchPagination(
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
      List<Map<String, dynamic>> orders) {
    // FILTER
    List<Map<String, dynamic>> filtered = orders.where((order) {
      if (_filterStatus == 'all') return true;
<<<<<<< HEAD
      return order['status'] == _filterStatus;
=======
      return (order['status'] ?? '').toLowerCase() == _filterStatus;
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
    }).toList();

    // SEARCH
    if (_searchController.text.isNotEmpty) {
<<<<<<< HEAD
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        final id = order['id'].toString().toLowerCase();
        final customerName =
            (order['customerName'] ?? '').toString().toLowerCase();
        final customerId = (order['customerId'] ?? '').toString().toLowerCase();
        return id.contains(query) ||
            customerName.contains(query) ||
            customerId.contains(query);
=======
      final searchLower = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        final orderId = (order['id'] ?? '').toLowerCase();
        final customerId = (order['customerId'] ?? '').toLowerCase();
        final customerName = (order['customerName'] ?? '').toLowerCase();

        return orderId.contains(searchLower) ||
            customerId.contains(searchLower) ||
            customerName.contains(searchLower);
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
      }).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

<<<<<<< HEAD
    return filtered;
=======
    // PAGINATION
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    if (start >= filtered.length) return [];
    return filtered.sublist(
        start, end > filtered.length ? filtered.length : end);
  }

  // Method to fetch customer name with caching
  Future<String> _fetchCustomerName(String? customerId, String? existingName) async {
    // If we already have a name in the order, use it
    if (existingName != null && existingName.isNotEmpty && existingName != 'Customer') {
      return existingName;
    }

    // If no customer ID, return default
    if (customerId == null || customerId.isEmpty) {
      return 'Customer';
    }

    // Check cache first
    if (_customerNameCache.containsKey(customerId)) {
      return _customerNameCache[customerId]!;
    }

    // Fetch from FirestoreService
    final customerName = await FirestoreService.getCustomerName(customerId);
    
    // Cache the result
    _customerNameCache[customerId] = customerName;
    
    return customerName;
  }

  void _nextPage(int totalItems) {
    if (_currentPage * _itemsPerPage < totalItems) {
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
    }
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
  }

  void _onFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _filterStatus = value;
        _currentPage = 1;
      });
    }
  }

  void _onItemsPerPageChanged(int? value) {
    if (value != null) {
      setState(() {
        _itemsPerPage = value;
        _currentPage = 1;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirestoreService.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Status updated to ${newStatus.toUpperCase()}'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Error: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _showStatusDialog(String orderId, String currentStatus) {
    final statuses = [
      'pending',
      'confirmed',
      'processing',
      'shipped',
      'delivered',
      'cancelled',
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C8610).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit_rounded,
                        color: const Color(0xFF2C8610), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Update Order Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...statuses.map((status) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Radio<String>(
                    value: status,
                    groupValue: currentStatus,
                    onChanged: (value) {
                      Navigator.pop(context);
                      _updateOrderStatus(orderId, value!);
                    },
                    activeColor: Colors.blue,
                  ),
                  title: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status == currentStatus ? 'Current' : '',
                      style: TextStyle(
                        fontSize: 10,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(color: Colors.grey.shade600),
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

<<<<<<< HEAD
  void _showOrderDetailsModal(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OrderDetailsModal(order: order);
=======
  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'] ?? '';
    final status = order['status'] ?? 'pending';
    final total = (order['total'] ?? 0.0).toDouble();
    final items = order['items'] as List<dynamic>? ?? [];
    final paymentMethod = order['paymentMethod'] ?? 'gcash';
    final createdAt = order['createdAt'] as Timestamp?;
    final customerId = order['customerId'] ?? '';
    final existingCustomerName = order['customerName']?.toString();
    
    String dateText = 'Date not available';
    if (createdAt != null) {
      dateText = DateFormat('MMM dd, yyyy • HH:mm').format(createdAt.toDate());
    }

    return FutureBuilder<String>(
      future: _fetchCustomerName(customerId, existingCustomerName),
      builder: (context, snapshot) {
        final customerName = snapshot.data ?? 'Loading...';
        
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Order Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Order Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${orderId.substring(0, 8).toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              customerName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded,
                                    size: 14, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Text(
                                  dateText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
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

                // Divider
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),

                // Order Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ITEMS',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${items.length} item${items.length != 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PAYMENT',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatPaymentMethod(paymentMethod).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'TOTAL',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2C8610),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Quick Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showStatusDialog(orderId, status),
                              icon: Icon(Icons.edit_rounded,
                                  size: 18, color: const Color(0xFF2C8610)),
                              label: Text(
                                'Change Status',
                                style: TextStyle(color: const Color(0xFF2C8610)),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: const Color(0xFF2C8610)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _viewOrderDetails(order, customerName: customerName),
                              icon: Icon(Icons.visibility_rounded, size: 18),
                              label: const Text('View Details'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C8610),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                elevation: 2,
                              ),
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
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
      },
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'confirmed':
        return Icons.check_circle_outline_rounded;
      case 'processing':
        return Icons.build_circle_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.done_all_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedRoute: '/admin/orders',
=======
  void _viewOrderDetails(Map<String, dynamic> order, {String customerName = 'Customer'}) {
    final items = order['items'] as List<dynamic>? ?? [];
    final total = (order['total'] ?? 0.0).toDouble();
    final paymentMethod = order['paymentMethod'] ?? 'gcash';
    final shippingAddress = order['shippingAddress'] ?? 'Not provided';
    final contactNumber = order['contactNumber'] ?? 'Not provided';
    final createdAt = order['createdAt'] as Timestamp?;
    final customerId = order['customerId'] ?? '';
    final status = order['status'] ?? 'pending';
    
    String dateText = 'Date not available';
    if (createdAt != null) {
      dateText = DateFormat('MMM dd, yyyy • HH:mm').format(createdAt.toDate());
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.receipt_long_rounded,
                        color: Colors.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Order Summary
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ID',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                '#${order['id'].toString().substring(0, 8).toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Customer Info
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Information',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        customerName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C8610),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: $customerId',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            contactNumber,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shippingAddress,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Order Items
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Items (${items.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...items.map<Widget>((item) {
                        final itemMap = item as Map<String, dynamic>;
                        final name = itemMap['productName'] ?? 'Unknown Product';
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
                                  '$name x$quantity',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                '\$${subtotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Payment Summary
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payment Method',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            _formatPaymentMethod(paymentMethod).toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2C8610),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF2C8610),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('CLOSE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _filterStatus,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_rounded,
                color: Colors.grey.shade600),
            items: _statusFilters.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(
                  status == 'all' ? 'All Status' : status.toUpperCase(),
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: _onFilterChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildItemsPerPageDropdown() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _itemsPerPage,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down_rounded,
                color: Colors.grey.shade600),
            items: [5, 10, 20, 50].map((count) {
              return DropdownMenuItem<int>(
                value: count,
                child: Text(
                  '$count items',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
            onChanged: _onItemsPerPageChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SEARCH FIELD
<<<<<<< HEAD
            OrderSearchWidget(
=======
            ProductSearchWidget(
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
              controller: _searchController,
              onChanged: () => setState(() {
                _currentPage = 1;
              }),
            ),
            const SizedBox(height: 16),

<<<<<<< HEAD
            // FILTER AND PER PAGE DROPDOWN
            OrderFilterWidget(
              filterStatus: _filterStatus,
              itemsPerPage: _itemsPerPage,
              onFilterChanged: _onFilterChanged,
              onItemsPerPageChanged: _onItemsPerPageChanged,
=======
            // FILTER AND PER PAGE DROPDOWN ROW
            Row(
              children: [
                _buildFilterDropdown(),
                const SizedBox(width: 12),
                _buildItemsPerPageDropdown(),
              ],
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
            ),
            const SizedBox(height: 16),

            // ORDERS LIST
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService.getAllOrders(),
                builder: (context, snapshot) {
<<<<<<< HEAD
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading orders'));
                  }

=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

<<<<<<< HEAD
                  final orders = snapshot.data ?? [];
                  final filteredOrders = _getFilteredOrders(orders);
                  final totalCount = filteredOrders.length;
                  final totalPages =
                      (totalCount + _itemsPerPage - 1) ~/ _itemsPerPage;
                  final effectiveTotalPages = totalPages == 0 ? 1 : totalPages;

                  // Ensure current page is valid
                  if (_currentPage > effectiveTotalPages) {
                    _currentPage = effectiveTotalPages;
                  }

                  if (filteredOrders.isEmpty) {
=======
                  if (snapshot.hasError) {
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                    return Center(
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
<<<<<<< HEAD
                              Icon(Icons.inbox_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No orders found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
=======
                              Icon(Icons.error_outline_rounded,
                                  size: 64, color: Colors.red.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading orders',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

<<<<<<< HEAD
                  final start = (_currentPage - 1) * _itemsPerPage;
                  final end = start + _itemsPerPage;
                  final paginatedOrders = filteredOrders.sublist(
                      start, end > totalCount ? totalCount : end);
=======
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shopping_bag_outlined,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                'No orders found.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final orders = snapshot.data!;
                  final paginatedOrders = _applyFilterSearchPagination(orders);
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

                  return Column(
                    children: [
                      Expanded(
<<<<<<< HEAD
                        child: ListView.builder(
                          itemCount: paginatedOrders.length,
                          itemBuilder: (context, index) {
                            final order = paginatedOrders[index];
                            return AdminOrderCard(
                              order: order,
                              onStatusChanged: () => _showStatusDialog(
                                order['id'],
                                order['status'] ?? 'pending',
                              ),
                              onCardTap: () => _showOrderDetailsModal(order),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // BOTTOM CONTROLS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OrderPaginationWidget(
                            currentPage: _currentPage,
                            totalPages: effectiveTotalPages,
                            onPreviousPage: () {
                              if (_currentPage > 1) {
                                setState(() => _currentPage--);
                              }
                            },
                            onNextPage: () {
                              if (_currentPage < effectiveTotalPages) {
                                setState(() => _currentPage++);
                              }
                            },
                          ),
                        ],
=======
                        child: ListView.separated(
                          itemCount: paginatedOrders.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final order = paginatedOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // PAGINATION CONTROLS
                      ProductPaginationWidget(
                        currentPage: _currentPage,
                        onPreviousPage: _prevPage,
                        onNextPage: () => _nextPage(orders.length),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
}

class AdminOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onStatusChanged;
  final VoidCallback onCardTap;

  const AdminOrderCard({
    super.key,
    required this.order,
    required this.onStatusChanged,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    final totalAmount = order['total']?.toDouble() ?? 0.0;
    final createdAt = order['createdAt'] as Timestamp?;
    final paymentMethod = order['paymentMethod'] ?? 'gcash';
    final customerName = order['customerName'] ?? 'Unknown Customer';

    return GestureDetector(
      onTap: onCardTap,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order['id'].toString().substring(0, 8)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _getStatusColor(order['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (order['status'] ?? 'pending').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(order['status']),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Text(
                      '₱${NumberFormat('#,###.00').format(totalAmount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Order details
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    customerName,
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${items.length} item(s)',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.payment_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatPaymentMethod(paymentMethod),
                    style: TextStyle(color: Colors.grey[800]),
                  ),
                ],
              ),

              if (createdAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(createdAt.toDate()),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),

              // Admin action button - single green button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onStatusChanged();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Change Status',
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
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
=======
}
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
