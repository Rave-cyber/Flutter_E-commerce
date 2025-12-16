import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/order_model.dart';

class OrderService {
  final CollectionReference _orderCollection =
      FirebaseFirestore.instance.collection('orders');

  /// CREATE order
  Future<void> createOrder(OrderModel order) async {
    try {
      await _orderCollection.doc(order.id).set(order.toMap());
      print('Order created successfully!');
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  /// READ orders (stream for UI)
  Stream<List<OrderModel>> getOrders() {
    return _orderCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// FETCH all orders once
  Future<List<OrderModel>> fetchAllOrders() async {
    try {
      final snapshot =
          await _orderCollection.orderBy('createdAt', descending: true).get();
      return snapshot.docs
          .map((doc) =>
              OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  /// FETCH orders within date range
  Future<List<OrderModel>> fetchOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _orderCollection
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(endDate.add(const Duration(days: 1))))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by date range: $e');
    }
  }

  /// FETCH orders by status
  Future<List<OrderModel>> fetchOrdersByStatus(OrderStatus status) async {
    try {
      final snapshot = await _orderCollection
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by status: $e');
    }
  }

  /// FETCH orders by status within date range
  Future<List<OrderModel>> fetchOrdersByStatusAndDateRange(
    OrderStatus status,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _orderCollection
          .where('status', isEqualTo: status.name)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(endDate.add(const Duration(days: 1))))
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by status and date range: $e');
    }
  }

  /// UPDATE order
  Future<void> updateOrder(OrderModel order) async {
    try {
      await _orderCollection.doc(order.id).update(order.toMap());
      print('Order updated successfully!');
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  /// UPDATE order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _orderCollection.doc(orderId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == OrderStatus.delivered)
          'deliveredAt': FieldValue.serverTimestamp(),
      });
      print('Order status updated successfully!');
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  /// DELETE order
  Future<void> deleteOrder(String id) async {
    try {
      await _orderCollection.doc(id).delete();
      print('Order deleted successfully!');
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  /// GET total revenue for date range (only delivered orders)
  Future<double> getTotalRevenueByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _orderCollection
          .where('status', isEqualTo: OrderStatus.delivered.name)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(endDate.add(const Duration(days: 1))))
          .get();

      return snapshot.docs.fold<double>(
        0.0,
        (sum, doc) => sum + (doc['total'] ?? 0.0),
      );
    } catch (e) {
      throw Exception('Failed to calculate total revenue: $e');
    }
  }

  /// GET total order count for date range
  Future<int> getTotalOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _orderCollection
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(endDate.add(const Duration(days: 1))))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get total orders count: $e');
    }
  }

  /// GET daily sales data for chart
  Future<List<Map<String, dynamic>>> getDailySalesData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _orderCollection
          .where('status', isEqualTo: OrderStatus.delivered.name)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(endDate.add(const Duration(days: 1))))
          .orderBy('createdAt')
          .get();

      // Group orders by date
      Map<String, double> dailyRevenue = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp).toDate();
        final dateKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
        final total = data['total'] ?? 0.0;

        dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0.0) + total;
      }

      // Convert to list sorted by date
      List<Map<String, dynamic>> result = [];
      DateTime currentDate = startDate;

      while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
        final dateKey =
            '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}';
        result.add({
          'date': dateKey,
          'revenue': dailyRevenue[dateKey] ?? 0.0,
        });
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return result;
    } catch (e) {
      throw Exception('Failed to get daily sales data: $e');
    }
  }

  /// STREAM orders by date range for real-time updates
  Stream<List<OrderModel>> streamOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _orderCollection
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt',
            isLessThanOrEqualTo:
                Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// STREAM delivered orders by date range for real-time sales data
  Stream<List<OrderModel>> streamDeliveredOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _orderCollection
        .where('status', isEqualTo: OrderStatus.delivered.name)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt',
            isLessThanOrEqualTo:
                Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
