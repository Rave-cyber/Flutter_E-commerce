import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/stock_in_model.dart';
import '/models/product_model.dart';
import '/models/product_variant_model.dart';

class StockInService {
  final CollectionReference _stockInCollection =
      FirebaseFirestore.instance.collection('stock_ins');

  /// CREATE stock-in
  Future<void> createStockIn(StockInModel stockIn) async {
    try {
      // 1. Create the stock-in record
      await _stockInCollection.doc(stockIn.id).set(stockIn.toMap());
      print('Stock-in record created successfully!');

      // 2. Update the corresponding stock
      final productsCollection =
          FirebaseFirestore.instance.collection('products');
      final variantsCollection =
          FirebaseFirestore.instance.collection('product_variants');

      if (stockIn.product_variant_id != null) {
        // If this stock-in is for a variant
        final variantDoc = variantsCollection.doc(stockIn.product_variant_id);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(variantDoc);
          final currentStock = (snapshot.get('stock') ?? 0) as int;
          transaction
              .update(variantDoc, {'stock': currentStock + stockIn.quantity});

          // Now also update main product stock as sum of all variants
          final productId = snapshot.get('product_id');
          final variantsSnapshot = await variantsCollection
              .where('product_id', isEqualTo: productId)
              .get();
          final totalVariantStock = variantsSnapshot.docs
              .fold<int>(0, (sum, doc) => sum + (doc['stock'] ?? 0) as int);
          final productDoc = productsCollection.doc(productId);
          transaction.update(productDoc, {'stock_quantity': totalVariantStock});
        });
      } else if (stockIn.product_id != null) {
        // If stock-in is for main product (no variants)
        final productDoc = productsCollection.doc(stockIn.product_id);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(productDoc);
          final currentStock = (snapshot.get('stock_quantity') ?? 0) as int;
          transaction.update(
              productDoc, {'stock_quantity': currentStock + stockIn.quantity});
        });
      }
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
