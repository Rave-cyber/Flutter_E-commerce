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
                    Text(
                      'Status: ${delivery['status']}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
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
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '₱${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

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
              ),
            ],

            if (shippedAt != null) ...[
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
              ),
            ],

            const SizedBox(height: 16),

            // Delivered button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToDeliveryForm(context, delivery),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
