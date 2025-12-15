import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../firestore_service.dart';
import '../../../layouts/delivery_staff_layout.dart';
import '../../../widgets/order_details_modal.dart';
import '../../../widgets/order_filter_widget.dart';
import '../../../widgets/order_pagination_widget.dart';
import '../../../widgets/order_search_widget.dart';
import '../../../services/auth_service.dart';

class DeliveryStaffOrderHistoryScreen extends StatefulWidget {
  const DeliveryStaffOrderHistoryScreen({super.key});

  @override
  State<DeliveryStaffOrderHistoryScreen> createState() =>
      _DeliveryStaffOrderHistoryScreenState();
}

class _DeliveryStaffOrderHistoryScreenState
    extends State<DeliveryStaffOrderHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all';
  String _archiveFilter = 'active'; // 'active' or 'archived'
  int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _filterStatus = value;
        _currentPage = 1;
      });
    }
  }

  void _onArchiveFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _archiveFilter = value;
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

  List<Map<String, dynamic>> _getFilteredOrders(
      List<Map<String, dynamic>> orders) {
    // FILTER BY ARCHIVE STATUS
    List<Map<String, dynamic>> filtered = orders.where((order) {
      if (_archiveFilter == 'active') {
        return order['isArchived'] != true;
      } else {
        return order['isArchived'] == true;
      }
    }).toList();

    // FILTER BY STATUS
    if (_filterStatus != 'all') {
      filtered = filtered.where((order) {
        return order['status'] == _filterStatus;
      }).toList();
    }

    // SEARCH
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        final id = order['id'].toString().toLowerCase();
        final address =
            (order['shippingAddress'] ?? '').toString().toLowerCase();
        final contact = (order['contactNumber'] ?? '').toString().toLowerCase();
        return id.contains(query) ||
            address.contains(query) ||
            contact.contains(query);
      }).toList();
    }
    return filtered;
  }

  void _showOrderDetailsModal(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OrderDetailsModal(order: order);
      },
    );
  }

  Future<void> _archiveOrder(String orderId) async {
    try {
      await FirestoreService.archiveOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order archived successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error archiving order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unarchiveOrder(String orderId) async {
    try {
      await FirestoreService.unarchiveOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order unarchived successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error unarchiving order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showArchiveDialog(Map<String, dynamic> order) {
    final bool isArchived = order['isArchived'] == true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isArchived ? Icons.unarchive : Icons.archive,
                color: isArchived ? Colors.orange : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text(isArchived ? 'Unarchive Order' : 'Archive Order'),
            ],
          ),
          content: Text(
              'Are you sure you want to ${isArchived ? 'unarchive' : 'archive'} order #${order['id'].toString().substring(0, 8)}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (isArchived) {
                  _unarchiveOrder(order['id']);
                } else {
                  _archiveOrder(order['id']);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isArchived ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(isArchived ? 'Unarchive' : 'Archive'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DeliveryStaffLayout(
      title: 'Order History',
      selectedRoute: '/delivery-staff/order-history',
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

            // HORIZONTALLY SCROLLABLE FILTER ROW
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Archive Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButton<String>(
                      value: _archiveFilter,
                      onChanged: _onArchiveFilterChanged,
                      items: const [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Active Orders'),
                        ),
                        DropdownMenuItem(
                          value: 'archived',
                          child: Text('Archived Orders'),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(8),
                      underline: const SizedBox(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Status Filter
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      onChanged: _onFilterChanged,
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Status'),
                        ),
                        DropdownMenuItem(
                          value: 'delivered',
                          child: Text('Delivered'),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(8),
                      underline: const SizedBox(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Items Per Page
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButton<int>(
                      value: _itemsPerPage,
                      onChanged: _onItemsPerPageChanged,
                      items: const [
                        DropdownMenuItem(
                          value: 5,
                          child: Text('5 per page'),
                        ),
                        DropdownMenuItem(
                          value: 10,
                          child: Text('10 per page'),
                        ),
                        DropdownMenuItem(
                          value: 20,
                          child: Text('20 per page'),
                        ),
                        DropdownMenuItem(
                          value: 50,
                          child: Text('50 per page'),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(8),
                      underline: const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ORDER LIST
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: AuthService().currentUser?.uid != null
                    ? FirestoreService.getDeliveryStaffOrderHistory(
                        AuthService().currentUser!.uid)
                    : Stream.value([]),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading order history'));
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
                              Icon(
                                _archiveFilter == 'archived'
                                    ? Icons.archive_outlined
                                    : Icons.history,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _archiveFilter == 'archived'
                                    ? 'No archived orders found'
                                    : 'No order history found',
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
                            return GestureDetector(
                              onTap: () => _showOrderDetailsModal(order),
                              child: OrderHistoryCard(
                                order: order,
                                onArchiveTap: () => _showArchiveDialog(order),
                              ),
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

class OrderHistoryCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onArchiveTap;

  const OrderHistoryCard({
    super.key,
    required this.order,
    required this.onArchiveTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    final totalAmount = order['total']?.toDouble() ?? 0.0;
    final createdAt = order['createdAt'] as Timestamp?;
    final deliveredAt = order['deliveredAt'] as Timestamp?;
    final shippingAddress = order['shippingAddress'] ?? 'No address provided';
    final contactNumber = order['contactNumber'] ?? 'No contact number';
    final deliveryStaffId = order['deliveryStaffId'] ?? '';
    final isArchived = order['isArchived'] == true;
    final deliveryProofImage = order['deliveryProofImage'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isArchived ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isArchived
            ? BorderSide(color: Colors.grey.shade300, width: 1)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isArchived
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade50,
                    Colors.grey.shade100,
                  ],
                )
              : null,
        ),
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
                      Row(
                        children: [
                          Text(
                            'Order #${order['id'].toString().substring(0, 8)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isArchived) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ARCHIVED',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                          (order['status'] ?? 'delivered').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(order['status']),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
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
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'archive' || value == 'unarchive') {
                            onArchiveTap();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            value: isArchived ? 'unarchive' : 'archive',
                            child: Row(
                              children: [
                                Icon(
                                  isArchived ? Icons.unarchive : Icons.archive,
                                  size: 18,
                                  color:
                                      isArchived ? Colors.orange : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(isArchived ? 'Unarchive' : 'Archive'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),

              // Order details
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
                  Icon(Icons.location_on_outlined,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shippingAddress,
                      style: TextStyle(color: Colors.grey[800]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    contactNumber,
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
                      'Ordered: ${_formatDate(createdAt.toDate())}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],

              if (deliveredAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Delivered: ${_formatDate(deliveredAt.toDate())}',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              if (deliveryProofImage != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.photo, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Proof Available',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              if (order['deliveryNotes'] != null &&
                  order['deliveryNotes'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notes: ${order['deliveryNotes']}',
                        style: TextStyle(color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered':
        return Colors.green;
      case 'shipped':
        return Colors.blue;
      case 'in_transit':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
