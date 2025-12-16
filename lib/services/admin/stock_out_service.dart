import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/stock_out_model.dart';
import '/models/stock_in_out_model.dart';
import '/models/stock_in_model.dart';
import '/models/product_variant_model.dart';

class StockOutService {
  final CollectionReference _stockOutCollection =
      FirebaseFirestore.instance.collection('stock_outs');
  final CollectionReference _stockInOutCollection =
      FirebaseFirestore.instance.collection('stock_in_outs');

  /// CREATE stock-out with FIFO logic
  Future<void> createStockOut(StockOutModel stockOut) async {
    try {
      // 1. Create the stock-out record
      await _stockOutCollection.doc(stockOut.id).set(stockOut.toMap());
      print('Stock-out record created successfully!');

      // 2. Apply FIFO logic to deduct stock
      await _applyFIFOLogic(stockOut);
    } catch (e) {
      throw Exception('Failed to create stock-out: $e');
    }
  }

  /// FIFO Logic Implementation
  /// Deducts from oldest stock-in first, then next, etc.
  Future<void> _applyFIFOLogic(StockOutModel stockOut) async {
    final stockInCollection =
        FirebaseFirestore.instance.collection('stock_ins');
    final variantsCollection =
        FirebaseFirestore.instance.collection('product_variants');
    final productsCollection =
        FirebaseFirestore.instance.collection('products');

    // Determine if we're working with a product or variant
    final isForVariant = stockOut.product_variant_id != null;
    final targetId =
        isForVariant ? stockOut.product_variant_id! : stockOut.product_id!;
    final productId = isForVariant
        ? await _getProductIdForVariant(targetId, variantsCollection)
        : targetId!;

    // Get all stock-in records for this product/variant (no compound queries)
    Query stockInQuery = stockInCollection.where(
        isForVariant ? 'product_variant_id' : 'product_id',
        isEqualTo: targetId);

    final stockInSnapshot = await stockInQuery.get();
    final stockInRecords = stockInSnapshot.docs
        .map((doc) => StockInModel.fromMap(doc.data() as Map<String, dynamic>))
        .where((stockIn) => stockIn.remaining_quantity > 0) // Filter in memory
        .toList();

    // Sort by creation date (oldest first) for FIFO
    stockInRecords.sort((a, b) => a.created_at!.compareTo(b.created_at!));

    int remainingToDeduct = stockOut.quantity;
    List<Map<String, dynamic>> fifoDeductions = [];

    // Apply FIFO: deduct from oldest stock-in first
    for (final stockIn in stockInRecords) {
      if (remainingToDeduct <= 0) break;

      final availableQuantity = stockIn.remaining_quantity;
      if (availableQuantity <= 0) continue;

      final deductionQuantity = remainingToDeduct <= availableQuantity
          ? remainingToDeduct
          : availableQuantity;

      // Record this deduction for batch processing
      fifoDeductions.add({
        'stockInId': stockIn.id,
        'deductedQuantity': deductionQuantity,
        'stockInDoc': stockInCollection.doc(stockIn.id),
        'currentRemaining':
            stockIn.remaining_quantity, // Store current remaining
      });

      remainingToDeduct -= deductionQuantity;
    }

    // Check if we have enough stock
    if (remainingToDeduct > 0) {
      throw Exception(
          'Insufficient stock. Need $remainingToDeduct more units.');
    }

    // Execute all deductions in a transaction
    // First, pre-fetch all stock-in documents to avoid reads inside transaction
    final List<DocumentSnapshot> stockInDocs = [];
    for (final deduction in fifoDeductions) {
      final stockInDoc = deduction['stockInDoc'] as DocumentReference;
      final doc = await stockInDoc.get();
      stockInDocs.add(doc);
    }

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Now perform all operations inside the transaction
      for (int i = 0; i < fifoDeductions.length; i++) {
        final deduction = fifoDeductions[i];
        final stockInDoc = deduction['stockInDoc'] as DocumentReference;
        final deductedQuantity = deduction['deductedQuantity'] as int;
        final stockInId = deduction['stockInId'] as String;
        final stockInDocSnapshot = stockInDocs[i];
        final currentRemaining =
            (stockInDocSnapshot.get('remaining_quantity') ?? 0) as int;

        // Update stock-in remaining quantity
        final newRemaining = currentRemaining - deductedQuantity;
        transaction.update(stockInDoc, {'remaining_quantity': newRemaining});

        // Create stock_in_out record to track the deduction
        final stockInOutId = '${stockOut.id}_$stockInId';
        final stockInOut = StockInOutModel(
          id: stockInOutId,
          stock_in_id: stockInId,
          stock_out_id: stockOut.id,
          deducted_quantity: deductedQuantity,
          created_at: DateTime.now(),
          updated_at: DateTime.now(),
        );

        transaction.set(
            _stockInOutCollection.doc(stockInOutId), stockInOut.toMap());
      }
    });

    // Update main product stock quantity by recalculating from remaining quantities
    await _updateProductStock(productId);
  }

  /// Get product ID for a variant
  Future<String> _getProductIdForVariant(
      String variantId, CollectionReference variantsCollection) async {
    final variantDoc = await variantsCollection.doc(variantId).get();
    return variantDoc.get('product_id');
  }

  /// Update main product stock quantity based on all remaining quantities
  Future<void> _updateProductStock(String productId) async {
    final stockInCollection =
        FirebaseFirestore.instance.collection('stock_ins');
    final productsCollection =
        FirebaseFirestore.instance.collection('products');
    final variantsCollection =
        FirebaseFirestore.instance.collection('product_variants');

    // Check if product has variants
    final variantsSnapshot = await variantsCollection
        .where('product_id', isEqualTo: productId)
        .get();

    if (variantsSnapshot.docs.isNotEmpty) {
      // Product has variants - sum up all variant stocks from remaining quantities
      int totalVariantStock = 0;

      for (var variantDoc in variantsSnapshot.docs) {
        final variantId = variantDoc.id;
        final variantStockInSnapshot = await stockInCollection
            .where('product_variant_id', isEqualTo: variantId)
            .get();

        int variantRemainingStock = 0;
        for (var doc in variantStockInSnapshot.docs) {
          final remaining = (doc.data()['remaining_quantity'] ?? 0) as int;
          variantRemainingStock += remaining;
        }

        // Update individual variant stock
        await variantsCollection
            .doc(variantId)
            .update({'stock': variantRemainingStock});

        totalVariantStock += variantRemainingStock;
      }

      // Update main product stock
      await productsCollection
          .doc(productId)
          .update({'stock_quantity': totalVariantStock});
    } else {
      // Product has no variants - sum up direct stock-in remaining quantities
      final productStockInSnapshot = await stockInCollection
          .where('product_id', isEqualTo: productId)
          .get();

      int totalStock = 0;
      for (var doc in productStockInSnapshot.docs) {
        final remaining = (doc.data()['remaining_quantity'] ?? 0) as int;
        totalStock += remaining;
      }

      // Update main product stock
      await productsCollection
          .doc(productId)
          .update({'stock_quantity': totalStock});
    }
  }

  /// READ all stock-outs (stream for UI)
  Stream<List<StockOutModel>> getStockOuts() {
    return _stockOutCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                StockOutModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// READ all stock-in-out records for a specific stock-out
  Future<List<StockInOutModel>> getStockInOutRecords(String stockOutId) async {
    try {
      final snapshot = await _stockInOutCollection
          .where('stock_out_id', isEqualTo: stockOutId)
          .get();

      final records = snapshot.docs
          .map((doc) =>
              StockInOutModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Sort by creation date (oldest first)
      records.sort((a, b) => a.created_at!.compareTo(b.created_at!));
      return records;
    } catch (e) {
      throw Exception('Failed to fetch stock-in-out records: $e');
    }
  }

  /// UPDATE stock-out
  Future<void> updateStockOut(StockOutModel stockOut) async {
    try {
      await _stockOutCollection.doc(stockOut.id).update(stockOut.toMap());
      print('Stock-out record updated successfully!');
    } catch (e) {
      throw Exception('Failed to update stock-out: $e');
    }
  }

  /// DELETE stock-out (cancelled - should archive instead)
  Future<void> deleteStockOut(String id) async {
    try {
      await _stockOutCollection.doc(id).delete();
      print('Stock-out record deleted successfully!');
    } catch (e) {
      throw Exception('Failed to delete stock-out: $e');
    }
  }

  /// FETCH stock-outs for a specific product (main or variant)
  Future<List<StockOutModel>> fetchStockOutsByProduct(String productId) async {
    try {
      final snapshot = await _stockOutCollection
          .where('product_id', isEqualTo: productId)
          .get();

      return snapshot.docs
          .map((doc) =>
              StockOutModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch stock-outs for product: $e');
    }
  }

  Future<List<StockOutModel>> fetchStockOutsByVariant(String variantId) async {
    try {
      final snapshot = await _stockOutCollection
          .where('product_variant_id', isEqualTo: variantId)
          .get();

      return snapshot.docs
          .map((doc) =>
              StockOutModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch stock-outs for variant: $e');
    }
  }

  /// FETCH all stock-outs once
  Future<List<StockOutModel>> fetchAllStockOuts() async {
    try {
      final snapshot = await _stockOutCollection
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs
          .map((doc) =>
              StockOutModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all stock-outs: $e');
    }
  }
}
