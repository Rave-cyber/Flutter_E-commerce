<<<<<<< HEAD
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
import 'form.dart';

class DeliveryStaffDeliveriesScreen extends StatefulWidget {
  const DeliveryStaffDeliveriesScreen({super.key});

  @override
  State<DeliveryStaffDeliveriesScreen> createState() =>
      _DeliveryStaffDeliveriesScreenState();
}

class _DeliveryStaffDeliveriesScreenState
    extends State<DeliveryStaffDeliveriesScreen> {
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

  List<Map<String, dynamic>> _getFilteredDeliveries(
      List<Map<String, dynamic>> deliveries) {
    // FILTER
    List<Map<String, dynamic>> filtered = deliveries.where((delivery) {
      if (_filterStatus == 'all') return true;
      return delivery['status'] == _filterStatus;
    }).toList();

    // SEARCH
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((delivery) {
        final id = delivery['id'].toString().toLowerCase();
        final address =
            (delivery['shippingAddress'] ?? '').toString().toLowerCase();
        final contact =
            (delivery['contactNumber'] ?? '').toString().toLowerCase();
        return id.contains(query) ||
            address.contains(query) ||
            contact.contains(query);
      }).toList();
    }
    return filtered;
  }

  void _showDeliveryDetailsModal(Map<String, dynamic> delivery) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return OrderDetailsModal(order: delivery);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DeliveryStaffLayout(
      title: 'Deliveries',
      selectedRoute: '/delivery-staff/deliveries',
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

            // DELIVERY LIST
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: AuthService().currentUser?.uid != null
                    ? FirestoreService.getDeliveryStaffDeliveries(
                        AuthService().currentUser!.uid)
                    : Stream.value([]),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading deliveries'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final deliveries = snapshot.data ?? [];
                  final filteredDeliveries = _getFilteredDeliveries(deliveries);
                  final totalCount = filteredDeliveries.length;
                  final totalPages =
                      (totalCount + _itemsPerPage - 1) ~/ _itemsPerPage;
                  final effectiveTotalPages = totalPages == 0 ? 1 : totalPages;

                  // Ensure current page is valid
                  if (_currentPage > effectiveTotalPages) {
                    _currentPage = effectiveTotalPages;
                  }

                  if (filteredDeliveries.isEmpty) {
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
                              Icon(Icons.local_shipping_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No deliveries found',
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
                  final paginatedDeliveries = filteredDeliveries.sublist(
                      start, end > totalCount ? totalCount : end);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedDeliveries.length,
                          itemBuilder: (context, index) {
                            final delivery = paginatedDeliveries[index];
                            return GestureDetector(
                              onTap: () => _showDeliveryDetailsModal(delivery),
                              child: DeliveryCard(delivery: delivery),
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
=======
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../layouts/delivery_staff_layout.dart';
import '../../../firestore_service.dart';
import 'form.dart';

class DeliveryStaffDeliveriesScreen extends StatelessWidget {
  const DeliveryStaffDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DeliveryStaffLayout(
      title: 'Deliveries',
      selectedRoute: '/delivery-staff/deliveries',
      child: DeliveriesList(),
    );
  }
}

class DeliveriesList extends StatelessWidget {
  const DeliveriesList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getDeliveryStaffDeliveries(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading deliveries'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final deliveries = snapshot.data ?? [];

        if (deliveries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No deliveries available',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: deliveries.length,
          itemBuilder: (context, index) {
            final delivery = deliveries[index];
            return DeliveryCard(delivery: delivery);
          },
        );
      },
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
    );
  }
}

class DeliveryCard extends StatelessWidget {
  final Map<String, dynamic> delivery;

  const DeliveryCard({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final items = (delivery['items'] as List<dynamic>?) ?? [];
    final totalAmount = delivery['total']?.toDouble() ?? 0.0;
    final createdAt = delivery['createdAt'] as Timestamp?;
    final shippedAt = delivery['shippedAt'] as Timestamp?;
    final shippingAddress =
        delivery['shippingAddress'] ?? 'No address provided';
    final contactNumber = delivery['contactNumber'] ?? 'No contact number';
    final deliveryStaffId = delivery['deliveryStaffId'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
<<<<<<< HEAD
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${delivery['id'].toString().substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
<<<<<<< HEAD
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(delivery['status'])
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (delivery['status'] ?? 'shipped').toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(delivery['status']),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
=======
                    Text(
                      'Status: ${delivery['status']}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
<<<<<<< HEAD
                  child: Text(
                    '₱${NumberFormat('#,###.00').format(totalAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
=======
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₱${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
<<<<<<< HEAD
            const Divider(),
            const SizedBox(height: 8),

            // Delivery details
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
=======

            // Delivery details
            Text(
              'Items: ${items.length} item(s)',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text('Address: $shippingAddress'),
            const SizedBox(height: 2),
            Text('Contact: $contactNumber'),

            if (createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Order Date: ${_formatDate(createdAt.toDate())}',
                style: TextStyle(color: Colors.grey.shade600),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
              ),
            ],

            if (shippedAt != null) ...[
<<<<<<< HEAD
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_shipping, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Picked Up: ${_formatDate(shippedAt.toDate())}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
=======
              const SizedBox(height: 2),
              Text(
                'Picked Up: ${_formatDate(shippedAt.toDate())}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],

            if (deliveryStaffId.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Delivery Staff: ${deliveryStaffId.substring(0, 8)}...',
                style: TextStyle(color: Colors.grey.shade600),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
              ),
            ],

            const SizedBox(height: 16),

<<<<<<< HEAD
            // Mark as delivered button
=======
            // Delivered button
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToDeliveryForm(context, delivery),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
<<<<<<< HEAD
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                ),
                child: const Text(
                  'Mark as Delivered',
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

<<<<<<< HEAD
  Color _getStatusColor(String status) {
    switch (status) {
      case 'shipped':
        return Colors.blue;
      case 'in_transit':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToDeliveryForm(
      BuildContext context, Map<String, dynamic> delivery) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryProofForm(
          delivery: delivery,
        ),
      ),
    );
  }
}
