import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/stock_in_model.dart';
import '/models/product_variant_model.dart';

class StockInService {
  final CollectionReference _stockInCollection =
      FirebaseFirestore.instance.collection('stock_ins');

  /// CREATE stock-in with FIFO support
  Future<void> createStockIn(StockInModel stockIn) async {
    try {
      // 1. Create the stock-in record with remaining_quantity initialized
      final stockInWithRemaining = StockInModel(
        id: stockIn.id,
        product_id: stockIn.product_id,
        product_variant_id: stockIn.product_variant_id,
        supplier_id: stockIn.supplier_id,
        warehouse_id: stockIn.warehouse_id,
        stock_checker_id: stockIn.stock_checker_id,
        quantity: stockIn.quantity,
        remaining_quantity:
            stockIn.quantity, // Initialize with full quantity for FIFO tracking
        price: stockIn.price,
        reason: stockIn.reason,
        is_archived: stockIn.is_archived,
        created_at: stockIn.created_at,
        updated_at: DateTime.now(),
      );

      await _stockInCollection
          .doc(stockIn.id)
          .set(stockInWithRemaining.toMap());
      print('Stock-in record created successfully with FIFO tracking!');

      // 2. Update the corresponding stock
      final productsCollection =
          FirebaseFirestore.instance.collection('products');
      final variantsCollection =
          FirebaseFirestore.instance.collection('product_variants');

      if (stockIn.product_variant_id != null) {
        // If this stock-in is for a variant
        final variantDoc = variantsCollection.doc(stockIn.product_variant_id);

        // First, get the current variant data
        final variantSnapshot = await variantDoc.get();
        final productId = variantSnapshot.get('product_id');

        // Calculate the new total stock for all variants
        final allVariantsSnapshot = await variantsCollection
            .where('product_id', isEqualTo: productId)
            .get();

        int totalVariantStock = 0;
        for (var doc in allVariantsSnapshot.docs) {
          if (doc.id == stockIn.product_variant_id) {
            // This is the variant we're updating
            final currentStock = (doc.data()['stock'] ?? 0) as int;
            totalVariantStock += currentStock + stockIn.quantity;
          } else {
            // Other variants
            final variantStock = (doc.data()['stock'] ?? 0) as int;
            totalVariantStock += variantStock;
          }
        }

        // Now update everything in a transaction
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Update the variant stock
          final currentStock = (variantSnapshot.get('stock') ?? 0) as int;
          transaction
              .update(variantDoc, {'stock': currentStock + stockIn.quantity});

          // Update the main product stock
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

  /// UPDATE stock-in (use with caution - may affect FIFO logic)
  Future<void> updateStockIn(StockInModel stockIn) async {
    try {
      await _stockInCollection.doc(stockIn.id).update(stockIn.toMap());
      print('Stock-in record updated successfully!');
    } catch (e) {
      throw Exception('Failed to update stock-in: $e');
    }
  }

  /// DELETE stock-in (use with caution - may affect FIFO logic)
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

  /// Get FIFO ordered stock-ins for a specific product/variant
  /// This returns stock-in records ordered by creation date (oldest first)
  Future<List<StockInModel>> getFIFOStockIns({
    String? productId,
    String? variantId,
    bool includeDepleted = false,
  }) async {
    try {
      Query query = _stockInCollection;

      if (variantId != null) {
        query = query.where('product_variant_id', isEqualTo: variantId);
      } else if (productId != null) {
        query = query.where('product_id', isEqualTo: productId);
      }

      final snapshot = await query.get();
      List<StockInModel> stockIns = snapshot.docs
          .map(
              (doc) => StockInModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter in memory to avoid compound queries
      if (!includeDepleted) {
        stockIns = stockIns
            .where((stockIn) => stockIn.remaining_quantity > 0)
            .toList();
      }

      // Sort by creation date (oldest first) for FIFO
      stockIns.sort((a, b) => a.created_at!.compareTo(b.created_at!));

      return stockIns;
    } catch (e) {
      throw Exception('Failed to fetch FIFO stock-ins: $e');
    }
  }

  /// Get available stock summary for FIFO tracking
  Future<Map<String, int>> getStockSummary({
    String? productId,
    String? variantId,
  }) async {
    try {
      final stockIns = await getFIFOStockIns(
        productId: productId,
        variantId: variantId,
        includeDepleted: true,
      );

      int totalQuantity = 0;
      int totalRemaining = 0;
      int depletedBatches = 0;

      for (final stockIn in stockIns) {
        totalQuantity += stockIn.quantity;
        totalRemaining += stockIn.remaining_quantity;
        if (stockIn.remaining_quantity == 0) {
          depletedBatches++;
        }
      }

      return {
        'totalQuantity': totalQuantity,
        'totalRemaining': totalRemaining,
        'totalDepleted': totalQuantity - totalRemaining,
        'depletedBatches': depletedBatches,
        'activeBatches': stockIns.where((s) => s.remaining_quantity > 0).length,
        'totalBatches': stockIns.length,
      };
    } catch (e) {
      throw Exception('Failed to get stock summary: $e');
    }
  }

  /// FETCH all stock-ins once
  Future<List<StockInModel>> fetchAllStockIns() async {
    try {
      final snapshot = await _stockInCollection
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs
          .map(
              (doc) => StockInModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all stock-ins: $e');
    }
  }
}
