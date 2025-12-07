import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/firestore_service.dart';
import 'package:firebase/models/order_model.dart';
import 'package:intl/intl.dart';
import '../../../layouts/admin_layout.dart';

class AdminOrdersIndex extends StatefulWidget {
  const AdminOrdersIndex({Key? key}) : super(key: key);

  @override
  State<AdminOrdersIndex> createState() => _AdminOrdersIndexState();
}

class _AdminOrdersIndexState extends State<AdminOrdersIndex> {
  String _selectedStatus = 'All';
  String _searchQuery = '';
  final MaterialColor primaryColor = Colors.blueGrey;

  final List<String> _statusFilters = [
    'All',
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search and Filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search by Order ID or Customer',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: _statusFilters.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status == 'All' ? 'All Status' : status.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedStatus = val!);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Orders List
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService.getAllOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final allOrders = snapshot.data ?? [];
                  
                  // Filter orders
                  final filteredOrders = allOrders.where((order) {
                    // Status filter
                    if (_selectedStatus != 'All') {
                      if (order['status'] != _selectedStatus) {
                        return false;
                      }
                    }

                    // Search filter
                    if (_searchQuery.isNotEmpty) {
                      final orderId = order['id'] ?? '';
                      final customerId = order['customerId'] ?? '';
                      final searchLower = _searchQuery.toLowerCase();
                      if (!orderId.toLowerCase().contains(searchLower) &&
                          !customerId.toLowerCase().contains(searchLower)) {
                        return false;
                      }
                    }

                    return true;
                  }).toList();

                  if (filteredOrders.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No orders found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'] ?? '';
    final status = order['status'] ?? 'pending';
    final total = (order['total'] ?? 0.0).toDouble();
    final items = order['items'] as List<dynamic>? ?? [];
    final paymentMethod = order['paymentMethod'] ?? 'gcash';
    final createdAt = order['createdAt'] as Timestamp?;
    final customerId = order['customerId'] ?? '';
    final shippingAddress = order['shippingAddress'] ?? 'Not provided';
    final contactNumber = order['contactNumber'] ?? 'Not provided';

    String dateText = 'Date not available';
    if (createdAt != null) {
      dateText = DateFormat('MMM dd, yyyy • hh:mm a').format(createdAt.toDate());
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(Icons.shopping_bag, color: primaryColor),
        title: Text(
          'Order #${orderId.substring(0, 8).toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateText),
            const SizedBox(height: 4),
            Text('Customer: $customerId'),
            Text('Items: ${items.length} • Total: \$${total.toStringAsFixed(2)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusChip(status),
            const SizedBox(height: 4),
            IconButton(
              icon: const Icon(Icons.edit),
              color: primaryColor,
              onPressed: () => _showStatusDialog(orderId, status),
              tooltip: 'Change Status',
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Items
                const Text(
                  'Order Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...items.take(3).map((item) {
                  final itemData = item as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: itemData['productImage'] != null &&
                                    itemData['productImage'].toString().isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(itemData['productImage']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Colors.grey[200],
                          ),
                          child: itemData['productImage'] == null ||
                                  itemData['productImage'].toString().isEmpty
                              ? const Icon(Icons.image, color: Colors.grey, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemData['productName'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Qty: ${itemData['quantity'] ?? 1} × \$${(itemData['price'] ?? 0.0).toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (items.length > 3)
                  Text(
                    '+ ${items.length - 3} more item${items.length - 3 > 1 ? 's' : ''}',
                    style: TextStyle(color: primaryColor, fontSize: 12),
                  ),
                const Divider(),
                const SizedBox(height: 8),
                
                // Shipping Info
                _buildInfoRow('Shipping Address', shippingAddress),
                _buildInfoRow('Contact Number', contactNumber),
                _buildInfoRow('Payment Method', _formatPaymentMethod(paymentMethod)),
                const SizedBox(height: 8),
                
                // Order Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$${(order['subtotal'] ?? 0.0).toStringAsFixed(2)}'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Shipping:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$${(order['shipping'] ?? 0.0).toStringAsFixed(2)}'),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
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
      builder: (context) => AlertDialog(
        title: const Text('Change Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: statuses.map((status) {
            return RadioListTile<String>(
              title: Text(status.toUpperCase()),
              value: status,
              groupValue: currentStatus,
              onChanged: (value) {
                Navigator.pop(context);
                _updateOrderStatus(orderId, value!);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirestoreService.updateOrderStatus(orderId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

