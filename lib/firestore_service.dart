import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase/models/product_variant_model.dart';
import 'package:firebase/models/user_model.dart';
import 'package:firebase/services/admin/stock_out_service.dart';
import 'package:firebase/models/stock_out_model.dart';
import 'models/product.dart'; // Import the correct model

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get featured products
  static Stream<List<ProductModel>> getFeaturedProducts() {
    return _firestore
        .collection('products')
        .where('is_featured', isEqualTo: true)
        .where('is_archived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      print('Featured products snapshot: ${snapshot.docs.length} documents');
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Featured product data: $data');
        // ProductModel.fromMap expects the id in the map
        return ProductModel.fromMap({
          'id': doc.id,
          ...data,
        });
      }).toList();
    }).handleError((error) {
      print('Error fetching featured products: $error');
      // Return empty list if query fails
      return Stream.value(<ProductModel>[]);
    });
  }

  // Get discounted products
  static Stream<List<ProductModel>> getDiscountedProducts() {
    return _firestore
        .collection('products')
        .where('is_archived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return ProductModel.fromMap({
              'id': doc.id,
              ...data,
            });
          })
          .where((product) => product.base_price > product.sale_price)
          .toList();
    }).handleError((error) {
      print('Error fetching discounted products: $error');
      // Return empty list if query fails
      return Stream.value(<ProductModel>[]);
    });
  }

  // Get products by category
  // Replace the getProductsByCategory method in FirestoreService:
  static Stream<List<ProductModel>> getProductsByCategory(String category) {
    print('Fetching products for category: $category');

    if (category == 'All') {
      return _firestore
          .collection('products')
          .where('is_archived', isEqualTo: false) // Add this filter
          .snapshots()
          .map((snapshot) {
        print('All products snapshot: ${snapshot.docs.length} documents');
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          print(
              'DEBUG: Product ${doc.id} category field: "${data['category']}"');
          print('DEBUG: Product ${doc.id} full data: $data');
          return ProductModel.fromMap({
            'id': doc.id,
            ...data,
          });
        }).toList();
      }).handleError((error) {
        print('Error fetching all products: $error');
        throw error;
      });
    }

    // CHANGED: Use category_id instead of category
    return _firestore
        .collection('products')
        .where('category_id',
            isEqualTo: category) // CHANGED: Revert to 'category' field
        .where('is_archived', isEqualTo: false) // Add this filter
        .snapshots()
        .map((snapshot) {
      print('Category products snapshot: ${snapshot.docs.length} documents');
      return snapshot.docs
          .map((doc) => ProductModel.fromMap({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              }))
          .toList();
    }).handleError((error) {
      print('Error fetching category products: $error');
      throw error;
    });
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

  // Get cart stream
  static Stream<QuerySnapshot> getCartStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('cart')
        .snapshots();
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
  // Add these methods to your existing FirestoreService class:

// Get product variants
  // Update the getProductVariants method in FirestoreService
  static Stream<List<ProductVariantModel>> getProductVariants(
      String productId) {
    return _firestore
        .collection('product_variants') // Changed from 'products/{id}/variants'
        .where('product_id', isEqualTo: productId)
        .where('is_archived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ProductVariantModel.fromMap({
          'id': doc.id,
          ...doc.data()!,
        });
      }).toList();
    }).handleError((error) {
      print('Error fetching variants: $error');
      throw error;
    });
  }

// Also update the getVariantById method:
  static Future<ProductVariantModel?> getVariantById(
      String productId, String variantId) async {
    try {
      final doc = await _firestore
          .collection('product_variants') // Changed here too
          .doc(variantId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        // Verify this variant belongs to the product
        if (data['product_id'] == productId) {
          return ProductVariantModel.fromMap({
            'id': doc.id,
            ...data,
          });
        }
        return null;
      }
      return null;
    } catch (e) {
      print('Error getting variant: $e');
      throw e;
    }
  }

// Get brand by ID
  static Future<Map<String, dynamic>?> getBrandById(String brandId) async {
    try {
      final doc = await _firestore.collection('brands').doc(brandId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      print('Error getting brand: $e');
      return null;
    }
  }

// Get category by ID
  static Future<Map<String, dynamic>?> getCategoryById(
      String categoryId) async {
    try {
      final doc =
          await _firestore.collection('categories').doc(categoryId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }

// Get all brands
  static Stream<List<Map<String, dynamic>>> getAllBrands() {
    return _firestore.collection('brands').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

// Get all categories
  static Stream<List<Map<String, dynamic>>> getAllCategories() {
    return _firestore.collection('categories').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  // Create order
  static Future<String> createOrder({
    required String userId,
    required String customerId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double shipping,
    required double total,
    required String paymentMethod,
    String? shippingAddress,
    String? contactNumber,
  }) async {
    try {
      final orderRef = _firestore.collection('orders').doc();
      final orderId = orderRef.id;

      await orderRef.set({
        'id': orderId,
        'userId': userId,
        'customerId': customerId,
        'items': items,
        'subtotal': subtotal,
        'shipping': shipping,
        'total': total,
        'paymentMethod': paymentMethod,
        'status': 'confirmed',
        'shippingAddress': shippingAddress,
        'contactNumber': contactNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return orderId;
    } catch (e) {
      print('Error creating order: $e');
      throw e;
    }
  }

  // Remove items from cart after order creation
  static Future<void> removeCartItems(
      String userId, List<String> productIds) async {
    try {
      final batch = _firestore.batch();
      for (final productId in productIds) {
        final cartRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(productId);
        batch.delete(cartRef);
      }
      await batch.commit();
    } catch (e) {
      print('Error removing cart items: $e');
      throw e;
    }
  }

  // Get order by ID
  static Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  // Get orders by user ID
  static Stream<List<Map<String, dynamic>>> getUserOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Sort by createdAt in memory to avoid composite index requirement
      orders.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Descending order
      });

      return orders;
    }).handleError((error) {
      print('Error fetching user orders: $error');
      // Return empty list on error instead of throwing
      return Stream.value(<Map<String, dynamic>>[]);
    });
  }

  // Get all orders (for admin)
  static Stream<List<Map<String, dynamic>>> getAllOrders() {
    return _firestore.collection('orders').snapshots().map((snapshot) {
      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Sort by createdAt in memory (descending - newest first)
      orders.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return orders;
    }).handleError((error) {
      print('Error fetching all orders: $error');
      return Stream.value(<Map<String, dynamic>>[]);
    });
  }

  // Get product ratings stream (only activated ratings by default)
  static Stream<List<Map<String, dynamic>>> getProductRatingsStream(
      String productId,
      {bool onlyActivated = true}) {
    return _firestore
        .collection('product_ratings')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) {
      final ratings = snapshot.docs
          .map((doc) {
            return {
              'id': doc.id,
              ...doc.data()!,
            };
          })
          .where((r) => !onlyActivated || (r['activated'] == true))
          .toList();

      // sort newest first
      ratings.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return ratings;
    }).handleError((error) {
      print('Error fetching product ratings: $error');
      return Stream.value(<Map<String, dynamic>>[]);
    });
  }

  // Add a product rating. If the user has a delivered order for this product,
  // the rating will be activated immediately. Otherwise it will be saved but
  // marked as not activated.
  static Future<void> addProductRating({
    required String productId,
    required String userId,
    required int stars,
    String? comment,
  }) async {
    try {
      // Check if user has a delivered order containing this product
      final delivered =
          await hasUserDeliveredOrderForProduct(userId, productId);

      final ratingsRef = _firestore.collection('product_ratings').doc();
      await ratingsRef.set({
        'productId': productId,
        'userId': userId,
        'stars': stars,
        'comment': comment ?? '',
        'activated': delivered,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding product rating: $e');
      throw e;
    }
  }

  // Returns true if the given user has at least one order with status
  // 'delivered' that contains the given productId in its items.
  static Future<bool> hasUserDeliveredOrderForProduct(
      String userId, String productId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'delivered')
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final items = (data['items'] as List<dynamic>?) ?? [];
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            if ((item['productId'] ?? '') == productId) return true;
          }
        }
      }

      return false;
    } catch (e) {
      print('Error checking delivered orders: $e');
      return false;
    }
  }

  // Helper method to handle stock-out logic for shipped orders
  static Future<void> _handleStockOutForShippedOrder(String orderId) async {
    // 1. Fetch Order Items
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) throw Exception('Order not found');

    final data = orderDoc.data();
    final items = (data?['items'] as List<dynamic>?) ?? [];

    // 2. Create Stock-Out records for each item
    final stockOutService = StockOutService();

    for (final item in items) {
      final itemMap = item as Map<String, dynamic>;
      final String itemId = itemMap['productId'];
      final int quantity = itemMap['quantity'];

      String? productId;
      String? variantId;

      // Check if itemId matches a Product
      final productDoc =
          await _firestore.collection('products').doc(itemId).get();
      if (productDoc.exists) {
        productId = itemId;
      } else {
        // Check if itemId matches a Variant
        final variantDoc =
            await _firestore.collection('product_variants').doc(itemId).get();
        if (variantDoc.exists) {
          variantId = itemId;
          productId = variantDoc.data()?['product_id'];
        }
      }

      if (productId != null) {
        // Generate a unique ID for the stock-out record
        // Use a suffix to ensure uniqueness if multiple items are processed quickly
        final stockOutId = DateTime.now().millisecondsSinceEpoch.toString() +
            '_' +
            (variantId ?? productId).substring(0, 4);

        final stockOut = StockOutModel(
          id: stockOutId,
          product_id: productId,
          product_variant_id: variantId,
          quantity: quantity,
          reason: 'Order Shipped: #${orderId.substring(0, 8).toUpperCase()}',
          created_at: DateTime.now(),
          updated_at: DateTime.now(),
        );

        await stockOutService.createStockOut(stockOut);
      } else {
        print(
            'Warning: Product/Variant not found for ID $itemId during stock-out.');
      }
    }
  }

  // Update order status (for admin)
  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      if (status == 'shipped') {
        await _handleStockOutForShippedOrder(orderId);
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating order status: $e');
      throw e;
    }
  }

  // Get banners (ordered by sequence)
  static Stream<List<Map<String, dynamic>>> getBanners() {
    return _firestore
        .collection('banners')
        .orderBy('order')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  // Add banner
  static Future<void> addBanner(Map<String, dynamic> data) async {
    try {
      await _firestore.collection('banners').add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding banner: $e');
      throw e;
    }
  }

  // Delete banner
  static Future<void> deleteBanner(String id) async {
    try {
      await _firestore.collection('banners').doc(id).delete();
    } catch (e) {
      print('Error deleting banner: $e');
      throw e;
    }
  }

  // Update banner (for order or editing)
  static Future<void> updateBanner(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('banners').doc(id).update(data);
    } catch (e) {
      print('Error updating banner: $e');
      throw e;
    }
  }

  // Get orders for delivery staff (confirmed and processing statuses)
  static Stream<List<Map<String, dynamic>>> getDeliveryStaffOrders(
      String deliveryStaffId) {
    return _firestore
        .collection('orders')
        .where('status', whereIn: ['confirmed', 'processing'])
        .where('deliveryStaffId', isEqualTo: deliveryStaffId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();

          // Sort by createdAt in memory (descending - newest first)
          orders.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return orders;
        })
        .handleError((error) {
          print('Error fetching delivery staff orders: $error');
          return Stream.value(<Map<String, dynamic>>[]);
        });
  }

  // Get shipped orders for delivery staff deliveries
  static Stream<List<Map<String, dynamic>>> getDeliveryStaffDeliveries(
      String deliveryStaffId) {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'shipped')
        .where('deliveryStaffId', isEqualTo: deliveryStaffId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          ...data,
        };
      }).toList();

      // Sort by createdAt in memory (descending - newest first)
      orders.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return orders;
    }).handleError((error) {
      print('Error fetching delivery staff deliveries: $error');
      return Stream.value(<Map<String, dynamic>>[]);
    });
  }

  // Update order status to shipped
  static Future<void> markOrderAsShipped(
      String orderId, String deliveryStaffId) async {
    try {
      await _handleStockOutForShippedOrder(orderId);

      await _firestore.collection('orders').doc(orderId).update({
        'status': 'shipped',
        'deliveryStaffId': deliveryStaffId,
        'shippedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking order as shipped: $e');
      throw e;
    }
  }

  // Update order status to delivered with proof
  static Future<void> markOrderAsDelivered(
      String orderId,
      String deliveryStaffId,
      String proofImageUrl,
      String? deliveryNotes) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'delivered',
        'deliveryStaffId': deliveryStaffId,
        'deliveredAt': FieldValue.serverTimestamp(),
        'deliveryProofImage': proofImageUrl,
        'deliveryNotes': deliveryNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking order as delivered: $e');
      throw e;
    }
  }

  // Get delivery staff data by user ID - IMPROVED with multiple search strategies
  static Future<Map<String, dynamic>?> getDeliveryStaffData(
      String deliveryStaffId) async {
    try {
      print('🔍 Searching for delivery staff with ID: $deliveryStaffId');

      // First try: Search by user_id field (most common scenario)
      print('📋 Strategy 1: Searching by user_id field...');
      final queryByUserId = await _firestore
          .collection('delivery_staff')
          .where('user_id', isEqualTo: deliveryStaffId)
          .limit(1)
          .get();

      if (queryByUserId.docs.isNotEmpty) {
        print(
            '✅ Found delivery staff by user_id: ${queryByUserId.docs.first.data()}');
        return {
          'id': queryByUserId.docs.first.id,
          ...queryByUserId.docs.first.data(),
        };
      }

      // Second try: Search by document ID (if deliveryStaffId is the document ID)
      print('📋 Strategy 2: Searching by document ID...');
      final docById = await _firestore
          .collection('delivery_staff')
          .doc(deliveryStaffId)
          .get();

      if (docById.exists) {
        print('✅ Found delivery staff by document ID: ${docById.data()}');
        return {
          'id': docById.id,
          ...docById.data()!,
        };
      }

      // Third try: Search by id field in document (if there's an id field)
      print('📋 Strategy 3: Searching by id field in document...');
      final queryByIdField = await _firestore
          .collection('delivery_staff')
          .where('id', isEqualTo: deliveryStaffId)
          .limit(1)
          .get();

      if (queryByIdField.docs.isNotEmpty) {
        print(
            '✅ Found delivery staff by id field: ${queryByIdField.docs.first.data()}');
        return {
          'id': queryByIdField.docs.first.id,
          ...queryByIdField.docs.first.data(),
        };
      }

      // Fourth try: Search by staff_id field (alternative field name)
      print('📋 Strategy 4: Searching by staff_id field...');
      final queryByStaffId = await _firestore
          .collection('delivery_staff')
          .where('staff_id', isEqualTo: deliveryStaffId)
          .limit(1)
          .get();

      if (queryByStaffId.docs.isNotEmpty) {
        print(
            '✅ Found delivery staff by staff_id: ${queryByStaffId.docs.first.data()}');
        return {
          'id': queryByStaffId.docs.first.id,
          ...queryByStaffId.docs.first.data(),
        };
      }

      print(
          '⚠️ No delivery staff found for ID: $deliveryStaffId after trying all strategies');
      return null;
    } catch (e) {
      print('❌ Error getting delivery staff data: $e');
      return null;
    }
  }

  // Upload delivery proof image to Cloudinary
  static Future<String> uploadDeliveryProofImage(
      String orderId, File imageFile) async {
    try {
      // Initialize Cloudinary with same config as product service
      final CloudinaryPublic _cloudinary = CloudinaryPublic(
        'drwoht0pd',
        'presets',
        cache: false,
      );

      // Create unique public ID with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = 'delivery_proofs/${orderId}_${timestamp}';

      // Upload file to Cloudinary
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          publicId: publicId,
        ),
      );

      print(
          'Delivery proof image uploaded successfully: ${response.secureUrl}');
      return response.secureUrl;
    } catch (e) {
      print('Error uploading delivery proof image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Get delivered orders for delivery staff order history
  static Stream<List<Map<String, dynamic>>> getDeliveryStaffOrderHistory(
      String deliveryStaffId) {
    return _firestore
        .collection('orders')
        .where('status', isEqualTo: 'delivered')
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      // Sort by deliveredAt in memory (descending - newest first)
      orders.sort((a, b) {
        final aTime = a['deliveredAt'] as Timestamp?;
        final bTime = b['deliveredAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return orders;
    }).handleError((error) {
      print('Error fetching delivery staff order history: $error');
      return Stream.value(<Map<String, dynamic>>[]);
    });
  }

  // Archive an order
  static Future<void> archiveOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error archiving order: $e');
      throw e;
    }
  }

  // Unarchive an order
  static Future<void> unarchiveOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'isArchived': false,
        'archivedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error unarchiving order: $e');
      throw e;
    }
  }
}
