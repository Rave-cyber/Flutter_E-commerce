import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/stock_in_model.dart';

class StockInService {
  final CollectionReference _stockInCollection =
      FirebaseFirestore.instance.collection('stock_ins');

  /// CREATE stock-in
  Future<void> createStockIn(StockInModel stockIn) async {
    try {
      await _stockInCollection.doc(stockIn.id).set(stockIn.toMap());
      print('Stock-in record created successfully!');
    } catch (e) {
      throw Exception('Failed to create stock-in: $e');
    }
  }

  /// READ all stock-ins (stream for UI)
  Stream<List<StockInModel>> getStockIns() {
    return _stockInCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                StockInModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// UPDATE stock-in
  Future<void> updateStockIn(StockInModel stockIn) async {
    try {
      await _stockInCollection.doc(stockIn.id).update(stockIn.toMap());
      print('Stock-in record updated successfully!');
    } catch (e) {
      throw Exception('Failed to update stock-in: $e');
    }
  }

  /// DELETE stock-in
  Future<void> deleteStockIn(String id) async {
    try {
      await _stockInCollection.doc(id).delete();
      print('Stock-in record deleted successfully!');
    } catch (e) {
      throw Exception('Failed to delete stock-in: $e');
    }
  }

  /// TOGGLE archive / unarchive
  Future<void> toggleArchive(StockInModel stockIn) async {
    try {
      await _stockInCollection.doc(stockIn.id).update({
        'is_archived': !stockIn.is_archived,
        'updated_at': DateTime.now(),
      });
      print(
          'Stock-in record "${stockIn.id}" is now ${!stockIn.is_archived ? 'active' : 'archived'}');
    } catch (e) {
      throw Exception('Failed to toggle archive status: $e');
    }
  }

  /// FETCH stock-ins for a specific product (main or variant)
  Future<List<StockInModel>> fetchStockInsByProduct(String productId) async {
    try {
      final snapshot = await _stockInCollection
          .where('product_id', isEqualTo: productId)
          .get();

      return snapshot.docs
          .map(
              (doc) => StockInModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch stock-ins for product: $e');
    }
  }

  Future<List<StockInModel>> fetchStockInsByVariant(String variantId) async {
    try {
      final snapshot = await _stockInCollection
          .where('product_variant_id', isEqualTo: variantId)
          .get();

      return snapshot.docs
          .map(
              (doc) => StockInModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch stock-ins for variant: $e');
    }
  }
}
