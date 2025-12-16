import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../firestore_service.dart';
import '../../../layouts/admin_layout.dart';
import '../../../widgets/order_details_modal.dart';
import '../../../widgets/order_filter_widget.dart';
import '../../../widgets/order_pagination_widget.dart';
import '../../../widgets/order_search_widget.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredOrders(
      List<Map<String, dynamic>> orders) {
    // FILTER
    List<Map<String, dynamic>> filtered = orders.where((order) {
      if (_filterStatus == 'all') return true;
      return order['status'] == _filterStatus;
    }).toList();

    // SEARCH
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        final id = order['id'].toString().toLowerCase();
        final customerName =
            (order['customerName'] ?? '').toString().toLowerCase();
        final customerId = (order['customerId'] ?? '').toString().toLowerCase();
        return id.contains(query) ||
            customerName.contains(query) ||
            customerId.contains(query);
      }).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) {
      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
      return bTime.compareTo(aTime);
    });

    return filtered;
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

  void _showOrderDetailsModal(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OrderDetailsModal(order: order);
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

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedRoute: '/admin/orders',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SEARCH FIELD
            OrderSearchWidget(
              controller: _searchController,
              onChanged: () => setState(() {
                _currentPage = 1;
              }),
            ),
            const SizedBox(height: 16),

            // FILTER AND PER PAGE DROPDOWN
            OrderFilterWidget(
              filterStatus: _filterStatus,
              itemsPerPage: _itemsPerPage,
              onFilterChanged: _onFilterChanged,
              onItemsPerPageChanged: _onItemsPerPageChanged,
            ),
            const SizedBox(height: 16),

            // ORDERS LIST
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService.getAllOrders(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading orders'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

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
                              Icon(Icons.inbox_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No orders found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final start = (_currentPage - 1) * _itemsPerPage;
                  final end = start + _itemsPerPage;
                  final paginatedOrders = filteredOrders.sublist(
                      start, end > totalCount ? totalCount : end);

                  return Column(
                    children: [
                      Expanded(
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
