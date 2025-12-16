import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/customer_model.dart';

class CustomerService {
  final CollectionReference _customerCollection =
      FirebaseFirestore.instance.collection('customers');

  /// CREATE customer
  Future<void> createCustomer(CustomerModel customer) async {
    try {
      await _customerCollection.doc(customer.id).set(customer.toMap());
      print('Customer created successfully!');
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  /// READ customers (stream for UI)
  Stream<List<CustomerModel>> getCustomers() {
    return _customerCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                CustomerModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// FETCH all customers once
  Future<List<CustomerModel>> fetchAllCustomers() async {
    try {
      final snapshot = await _customerCollection
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs
          .map((doc) =>
              CustomerModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  /// FETCH customers within date range
  Future<List<CustomerModel>> fetchCustomersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _customerCollection
          .where('created_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(endDate.add(const Duration(days: 1))))
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              CustomerModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch customers by date range: $e');
    }
  }

  /// GET total customer count for date range
  Future<int> getTotalCustomersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _customerCollection
          .where('created_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(endDate.add(const Duration(days: 1))))
          .get();

      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get total customers count: $e');
    }
  }

  /// GET monthly customer growth data for chart
  Future<List<Map<String, dynamic>>> getMonthlyCustomerGrowthData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _customerCollection
          .where('created_at',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at',
              isLessThanOrEqualTo:
                  Timestamp.fromDate(endDate.add(const Duration(days: 1))))
          .orderBy('created_at')
          .get();

      // Group customers by month
      Map<String, int> monthlyCustomers = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['created_at'] as Timestamp).toDate();
        final monthKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';

        monthlyCustomers[monthKey] = (monthlyCustomers[monthKey] ?? 0) + 1;
      }

      // Convert to list sorted by month
      List<Map<String, dynamic>> result = [];
      DateTime currentDate = DateTime(startDate.year, startDate.month);

      while (currentDate.isBefore(endDate.add(const Duration(days: 1)))) {
        final monthKey =
            '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}';
        result.add({
          'month': monthKey,
          'count': monthlyCustomers[monthKey] ?? 0,
        });
        // Move to next month
        if (currentDate.month == 12) {
          currentDate = DateTime(currentDate.year + 1, 1);
        } else {
          currentDate = DateTime(currentDate.year, currentDate.month + 1);
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to get monthly customer growth data: $e');
    }
  }

  /// UPDATE customer
  Future<void> updateCustomer(CustomerModel customer) async {
    try {
      await _customerCollection.doc(customer.id).update(customer.toMap());
      print('Customer updated successfully!');
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  /// DELETE customer
  Future<void> deleteCustomer(String id) async {
    try {
      await _customerCollection.doc(id).delete();
      print('Customer deleted successfully!');
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  /// GET customer by ID
  Future<CustomerModel?> getCustomerById(String id) async {
    try {
      final doc = await _customerCollection.doc(id).get();
      if (doc.exists) {
        return CustomerModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get customer by ID: $e');
    }
  }

  /// SEARCH customers by name or contact
  Future<List<CustomerModel>> searchCustomers(String query) async {
    try {
      // Note: Firestore doesn't support direct text search,
      // this is a basic implementation. For better search, consider using Algolia or similar
      final snapshot = await _customerCollection
          .orderBy('firstname')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) =>
              CustomerModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((customer) =>
              customer.firstname.toLowerCase().contains(query.toLowerCase()) ||
              customer.lastname.toLowerCase().contains(query.toLowerCase()) ||
              customer.contact.contains(query))
          .toList();
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  /// STREAM customers by date range for real-time updates
  Stream<List<CustomerModel>> streamCustomersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return _customerCollection
        .where('created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('created_at',
            isLessThanOrEqualTo:
                Timestamp.fromDate(endDate.add(const Duration(days: 1))))
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                CustomerModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }
}
