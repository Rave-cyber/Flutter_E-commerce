import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../firestore_service.dart';
import '../../../layouts/admin_layout.dart';

class SalesReportScreen extends StatelessWidget {
  const SalesReportScreen({super.key});

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.assessment, color: Colors.blueGrey),
                SizedBox(width: 8),
                Text(
                  'Sales Report',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirestoreService.getAllOrders(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error loading orders: ${snapshot.error}'),
                    );
                  }
                  final orders = snapshot.data ?? [];
                  if (orders.isEmpty) {
                    return Center(
                      child: Text(
                        'No orders found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final o = orders[index];
                      final id = (o['id'] ?? '') as String;
                      final total = (o['total'] ?? 0.0) as num;
                      final status = (o['status'] ?? '-') as String;
                      final createdAt = o['createdAt'] as Timestamp?;
                      final items = (o['items'] as List?) ?? const [];

                      final itemCount = items.length;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey[50],
                          child: const Icon(Icons.receipt_long, color: Colors.blueGrey),
                        ),
                        title: Text('Order #$id', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text('Date: ${_formatDate(createdAt)}'),
                            Text('Status: ${status[0].toUpperCase()}${status.length > 1 ? status.substring(1) : ''}'),
                            Text('Items: $itemCount'),
                          ],
                        ),
                        trailing: Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
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
}
