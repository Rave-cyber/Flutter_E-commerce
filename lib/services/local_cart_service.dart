import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase/firestore_service.dart';

class LocalCartService {
  static const String _cartKey = 'guest_cart';

  // Merge local cart to firestore
  static Future<void> mergeGuestCart(String userId) async {
    final cartItems = await getCart();
    if (cartItems.isEmpty) return;

    for (final item in cartItems) {
      await FirestoreService.addToCart(
        userId: userId,
        productId: item['productId'],
        productName: item['productName'] ?? '',
        productImage: item['productImage'] ?? '',
        price: (item['price'] ?? 0).toDouble(),
        quantity: item['quantity'] ?? 1,
      );
    }
    await clearCart();
  }

  // Get all cart items
  static Future<List<Map<String, dynamic>>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cartJson = prefs.getString(_cartKey);
    if (cartJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(cartJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // Add item to cart
  static Future<void> addToCart(Map<String, dynamic> newItem) async {
    final cart = await getCart();
    final String productId = newItem['productId'];

    // Check if item exists
    final index = cart.indexWhere((item) => item['productId'] == productId);

    if (index != -1) {
      // Update quantity
      int currentQty = cart[index]['quantity'] ?? 1;
      cart[index]['quantity'] = currentQty + (newItem['quantity'] as int? ?? 1);
    } else {
      // Add new
      cart.add(newItem);
    }

    await _saveCart(cart);
  }

  // Remove item
  static Future<void> removeFromCart(String productId) async {
    final cart = await getCart();
    cart.removeWhere((item) => item['productId'] == productId);
    await _saveCart(cart);
  }

  // Update quantity
  static Future<void> updateQuantity(String productId, int quantity) async {
    final cart = await getCart();
    final index = cart.indexWhere((item) => item['productId'] == productId);

    if (index != -1) {
      if (quantity <= 0) {
        cart.removeAt(index);
      } else {
        cart[index]['quantity'] = quantity;
      }
      await _saveCart(cart);
    }
  }

  // Clear cart
  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  static final _cartController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  // Get cart stream
  static Stream<List<Map<String, dynamic>>> getCartStream() async* {
    yield await getCart();
    yield* _cartController.stream;
  }

  // Save helper
  static Future<void> _saveCart(List<Map<String, dynamic>> cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cartKey, jsonEncode(cart));
    _cartController.add(cart);
  }
}
