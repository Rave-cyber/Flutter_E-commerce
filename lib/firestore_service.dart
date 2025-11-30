import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/models/user_model.dart';
import 'models/product.dart'; // Import the correct model

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get featured products
  static Stream<List<ProductModel>> getFeaturedProducts() {
    return _firestore
        .collection('products')
        .where('is_featured', isEqualTo: true) // Note: changed to is_featured
        .snapshots()
        .map((snapshot) {
      print('Featured products snapshot: ${snapshot.docs.length} documents');
      return snapshot.docs.map((doc) {
        print('Featured product data: ${doc.data()}');
        return ProductModel.fromMap(doc.data());
      }).toList();
    }).handleError((error) {
      print('Error fetching featured products: $error');
      throw error;
    });
  }

  // Get products by category
  static Stream<List<ProductModel>> getProductsByCategory(String category) {
    print('Fetching products for category: $category');

    if (category == 'All') {
      return _firestore.collection('products').snapshots().map((snapshot) {
        print('All products snapshot: ${snapshot.docs.length} documents');
        snapshot.docs.forEach((doc) {
          print('Product data: ${doc.data()}');
        });
        return snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data()))
            .toList();
      }).handleError((error) {
        print('Error fetching all products: $error');
        throw error;
      });
    }

    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      print('Category products snapshot: ${snapshot.docs.length} documents');
      snapshot.docs.forEach((doc) {
        print('Category product data: ${doc.data()}');
      });
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    }).handleError((error) {
      print('Error fetching category products: $error');
      throw error;
    });
  }

  // Get product by ID
  static Future<ProductModel?> getProductById(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (doc.exists) {
      return ProductModel.fromMap(doc.data()!);
    }
    return null;
  }

  // Add new product (for admin)
  static Future<void> addProduct(ProductModel product) {
    return _firestore.collection('products').add(product.toMap());
  }

  // Check if product is in favorites
  static Future<bool> isProductInFavorites(
      String userId, String productId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // Toggle favorite status
  static Future<void> toggleFavorite(String userId, String productId) async {
    try {
      final favoritesRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(productId);

      final doc = await favoritesRef.get();
      if (doc.exists) {
        await favoritesRef.delete();
      } else {
        await favoritesRef.set({
          'productId': productId,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      throw e;
    }
  }

  // Add to cart
  static Future<void> addToCart({
    required String userId,
    required String productId,
    required String productName,
    required String productImage,
    required double price,
    required int quantity,
  }) async {
    try {
      final cartRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(productId);

      final doc = await cartRef.get();
      if (doc.exists) {
        // Update quantity if item already in cart
        await cartRef.update({
          'quantity': FieldValue.increment(quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Add new item to cart
        await cartRef.set({
          'productId': productId,
          'productName': productName,
          'productImage': productImage,
          'price': price,
          'quantity': quantity,
          'addedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error adding to cart: $e');
      throw e;
    }
  }

  // Add this method to your existing FirestoreService class
  static Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}
