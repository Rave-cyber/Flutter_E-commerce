import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/stock_in_model.dart';
import 'services/admin/stock_out_service.dart';
import 'models/stock_out_model.dart';

/// Debug utility to test inventory deduction
class InventoryDebugHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final StockOutService _stockOutService = StockOutService();

  /// Test inventory deduction for a specific product
  static Future<void> testInventoryDeduction(String productId,
      {String? variantId}) async {
    print(
        '🧪 [DEBUG TEST] Starting inventory deduction test for product: $productId');

    try {
      // 1. Check stock-in records
      final stockInCollection = _firestore.collection('stock_ins');
      Query stockInQuery = variantId != null
          ? stockInCollection.where('product_variant_id', isEqualTo: variantId)
          : stockInCollection.where('product_id', isEqualTo: productId);

      final stockInSnapshot = await stockInQuery.get();
      print(
          '📊 [DEBUG TEST] Found ${stockInSnapshot.docs.length} stock-in records');

      if (stockInSnapshot.docs.isEmpty) {
        print(
            '❌ [DEBUG TEST] No stock-in records found for product: $productId');
        return;
      }

      // 2. Show stock-in details
      int totalAvailableStock = 0;
      for (var doc in stockInSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final remaining = (data['remaining_quantity'] ?? 0) as int;
        final initial = (data['initial_quantity'] ?? 0) as int;
        totalAvailableStock += remaining;

        print('📦 [DEBUG TEST] Stock-in ${doc.id}:');
        print('   - Initial: $initial');
        print('   - Remaining: $remaining');
        print('   - Created: ${data['created_at']}');
      }

      print('📈 [DEBUG TEST] Total available stock: $totalAvailableStock');

      if (totalAvailableStock <= 0) {
        print('⚠️  [DEBUG TEST] No stock available to deduct');
        return;
      }

      // 3. Test stock-out creation
      final testStockOutId = 'TEST_${DateTime.now().millisecondsSinceEpoch}';
      final testStockOut = StockOutModel(
        id: testStockOutId,
        product_id: variantId == null ? productId : null,
        product_variant_id: variantId,
        quantity: 1, // Test with 1 unit
        reason: 'Test Deduction - Debug',
        created_at: DateTime.now(),
        updated_at: DateTime.now(),
      );

      print('🧪 [DEBUG TEST] Creating test stock-out: $testStockOutId');
      await _stockOutService.createStockOut(testStockOut);
      print('✅ [DEBUG TEST] Test stock-out created successfully');

      // 4. Verify deduction
      print('🔍 [DEBUG TEST] Verifying inventory deduction...');
      await Future.delayed(Duration(seconds: 2)); // Wait for Firestore update

      final updatedStockInSnapshot = await stockInQuery.get();
      int updatedTotalStock = 0;

      for (var doc in updatedStockInSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final remaining = (data['remaining_quantity'] ?? 0) as int;
        updatedTotalStock += remaining;
      }

      print(
          '📊 [DEBUG TEST] Updated total available stock: $updatedTotalStock');
      print(
          '📉 [DEBUG TEST] Stock deducted: ${totalAvailableStock - updatedTotalStock}');

      if (totalAvailableStock - updatedTotalStock > 0) {
        print('✅ [DEBUG TEST] SUCCESS: Inventory was deducted correctly!');
      } else {
        print('❌ [DEBUG TEST] FAILED: Inventory was NOT deducted');
      }
    } catch (e) {
      print('❌ [DEBUG TEST] Error during test: $e');
    }
  }

  /// List all products with stock information
  static Future<void> listAllProductsWithStock() async {
    print('📋 [DEBUG TEST] Listing all products with stock information...');

    try {
      final productsSnapshot = await _firestore.collection('products').get();
      print('📊 [DEBUG TEST] Found ${productsSnapshot.docs.length} products');

      for (var productDoc in productsSnapshot.docs) {
        final productData = productDoc.data();
        final productId = productDoc.id;
        final productName = productData['name'] ?? 'Unknown';
        final stockQuantity = productData['stock_quantity'] ?? 0;

        print('🏷️  [DEBUG TEST] Product: $productName (ID: $productId)');
        print('   - Stock Quantity: $stockQuantity');

        // Check stock-in records
        final stockInSnapshot = await _firestore
            .collection('stock_ins')
            .where('product_id', isEqualTo: productId)
            .get();

        if (stockInSnapshot.docs.isNotEmpty) {
          print('   - Stock-in records: ${stockInSnapshot.docs.length}');
          for (var stockDoc in stockInSnapshot.docs) {
            final stockData = stockDoc.data();
            final remaining = stockData['remaining_quantity'] ?? 0;
            final initial = stockData['initial_quantity'] ?? 0;
            print(
                '     * Stock-in ${stockDoc.id}: Initial=$initial, Remaining=$remaining');
          }
        } else {
          print('   - No stock-in records found');
        }
        print('');
      }
    } catch (e) {
      print('❌ [DEBUG TEST] Error listing products: $e');
    }
  }
}
