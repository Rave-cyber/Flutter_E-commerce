import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../firestore_service.dart';
import '../../../layouts/delivery_staff_layout.dart';
import '../../../widgets/order_details_modal.dart';
import '../../../widgets/order_filter_widget.dart';
import '../../../widgets/order_pagination_widget.dart';
import '../../../widgets/order_search_widget.dart';

class DeliveryStaffOrdersScreen extends StatefulWidget {
  const DeliveryStaffOrdersScreen({super.key});

  @override
  State<DeliveryStaffOrdersScreen> createState() =>
      _DeliveryStaffOrdersScreenState();
}

class _DeliveryStaffOrdersScreenState extends State<DeliveryStaffOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all';
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

  @override
  Widget build(BuildContext context) {
    return DeliveryStaffLayout(
      title: 'Orders',
      selectedRoute: '/delivery-staff/orders',
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

            // ORDER LIST
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService.getDeliveryStaffOrders(),
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
                            return GestureDetector(
                              onTap: () => _showOrderDetailsModal(order),
                              child: OrderCard(order: order),
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

class OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    final totalAmount = order['total']?.toDouble() ?? 0.0;
    final createdAt = order['createdAt'] as Timestamp?;
    final shippingAddress = order['shippingAddress'] ?? 'No address provided';
    final contactNumber = order['contactNumber'] ?? 'No contact number';

    return Card(
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
                  // decoration: BoxDecoration(
                  //   color: Colors.green.shade100,
                  //   borderRadius: BorderRadius.circular(20),
                  // ),
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
                    _formatDate(createdAt.toDate()),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Pick up button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showPickupConfirmation(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Pick Up Order',
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
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showPickupConfirmation(
      BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Pickup'),
          content: Text(
              'Are you sure you want to pick up order #${order['id'].toString().substring(0, 8)}?\n\n'
              'This will change the order status to "shipped" and move it to your deliveries list.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                await _pickupOrder(context, order);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Confirm Pickup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickupOrder(
      BuildContext context, Map<String, dynamic> order) async {
    try {
      // Get current delivery staff ID (you'll need to implement user authentication)
      // For now, using a placeholder - replace with actual user ID
      const deliveryStaffId = 'current_delivery_staff_id';

      await FirestoreService.markOrderAsShipped(order['id'], deliveryStaffId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order picked up successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking up order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
