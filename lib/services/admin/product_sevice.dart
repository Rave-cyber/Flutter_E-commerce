import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase/models/attribute_model.dart';
import 'package:firebase/models/attribute_value_model.dart';
import 'package:image_picker/image_picker.dart';
import '/models/product.dart';
import '/models/category_model.dart';
import '/models/brand_model.dart';
import '/models/product_variant_model.dart';

class PickedImage {
  final File file;
  final String url;

  PickedImage({required this.file, required this.url});
}

class ProductService {
  final CollectionReference _productCollection =
      FirebaseFirestore.instance.collection('products');

  final CollectionReference _variantCollection =
      FirebaseFirestore.instance.collection('product_variants');

  final CollectionReference _categoryCollection =
      FirebaseFirestore.instance.collection('categories');

  final CollectionReference _brandCollection =
      FirebaseFirestore.instance.collection('brands');

  final CollectionReference _attributeCollection =
      FirebaseFirestore.instance.collection('attributes');

  final CollectionReference _attributeValueCollection =
      FirebaseFirestore.instance.collection('attribute_values');

  final CollectionReference _variantAttributeCollection =
      FirebaseFirestore.instance.collection('variant_attributes');

  final CloudinaryPublic _cloudinary = CloudinaryPublic(
    'drwoht0pd',
    'presets',
    cache: false,
  );

  final ImagePicker _picker = ImagePicker();

  /// Pick & upload image to Cloudinary
  Future<PickedImage?> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return null;

      final file = File(pickedFile.path);

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      return PickedImage(file: file, url: response.secureUrl);
    } catch (e) {
      print("Image upload error: $e");
      return null;
    }
  }

  /// CREATE product
  Future<void> createProduct(ProductModel product) async {
    try {
      await _productCollection.doc(product.id).set(product.toMap());
      print('Product created successfully!');
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  /// READ products (stream for UI)
  Stream<List<ProductModel>> getProducts() {
    return _productCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                ProductModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// UPDATE product
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _productCollection.doc(product.id).update(product.toMap());
      print('Product updated successfully!');
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// DELETE product
  Future<void> deleteProduct(String id) async {
    try {
      await _productCollection.doc(id).delete();
      print('Product deleted successfully!');
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// FETCH categories
  Future<List<CategoryModel>> fetchCategories() async {
    try {
      final snapshot = await _categoryCollection
          .where('is_archived', isEqualTo: false)
          .get();
      return snapshot.docs
          .map((doc) =>
              CategoryModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// FETCH brands
  Future<List<BrandModel>> fetchBrands() async {
    try {
      final snapshot =
          await _brandCollection.where('is_archived', isEqualTo: false).get();
      return snapshot.docs
          .map((doc) => BrandModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch brands: $e');
    }
  }

  /// TOGGLE archive / unarchive product
  Future<void> toggleArchive(ProductModel product) async {
    try {
      await _productCollection.doc(product.id).update({
        'is_archived': !product.is_archived,
        'updated_at': DateTime.now(),
      });
      print(
          'Product "${product.name}" is now ${!product.is_archived ? 'active' : 'archived'}');
    } catch (e) {
      throw Exception('Failed to toggle archive status: $e');
    }
  }

  /// CREATE or UPDATE a product variant
  Future<void> createOrUpdateVariant(ProductVariantModel variant) async {
    try {
      final docRef = _variantCollection.doc(variant.id);
      final doc = await docRef.get();

      if (doc.exists) {
        // UPDATE
        await docRef.update(variant.toMap());
        print('Variant updated successfully!');
      } else {
        // CREATE
        await docRef.set(variant.toMap());
        print('Variant created successfully!');
      }
    } catch (e) {
      throw Exception('Failed to create/update variant: $e');
    }
  }

  /// FETCH variants for a specific product
  Future<List<ProductVariantModel>> fetchVariants(String productId) async {
    try {
      final snapshot = await _variantCollection
          .where('product_id', isEqualTo: productId)
          .where('is_archived', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) =>
              ProductVariantModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch variants: $e');
    }
  }

  /// DELETE a variant
  Future<void> deleteVariant(String id) async {
    try {
      await _variantCollection.doc(id).delete();
      print('Variant deleted successfully!');
    } catch (e) {
      throw Exception('Failed to delete variant: $e');
    }
  }

  /// FETCH all attributes (non-archived)
  Future<List<AttributeModel>> fetchAttributes() async {
    try {
      final snapshot = await _attributeCollection
          .where('is_archived', isEqualTo: false)
          .get();
      return snapshot.docs
          .map((doc) =>
              AttributeModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch attributes: $e');
    }
  }

  /// FETCH attribute values for a specific attribute
  Future<List<AttributeValueModel>> fetchAttributeValues(
      String attributeId) async {
    try {
      final snapshot = await _attributeValueCollection
          .where('attribute_id', isEqualTo: attributeId)
          .where('is_archived', isEqualTo: false)
          .get();

      return snapshot.docs
          .map((doc) =>
              AttributeValueModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch attribute values: $e');
    }
  }

  /// FETCH all attribute-value pairs for a specific variant
  Future<List<Map<String, dynamic>>> fetchVariantAttributes(
      String variantId) async {
    try {
      final snapshot = await _variantAttributeCollection
          .where('variant_id', isEqualTo: variantId)
          .get();

      return snapshot.docs
          .map((doc) => {
                "id": doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      throw Exception("Failed to fetch variant attributes: $e");
    }
  }

  /// DELETE all attribute-value pairs for a variant
  Future<void> deleteVariantAttributesForVariant(String variantId) async {
    try {
      final snapshot = await _variantAttributeCollection
          .where('variant_id', isEqualTo: variantId)
          .get();

      for (var doc in snapshot.docs) {
        await _variantAttributeCollection.doc(doc.id).delete();
      }

      print("Variant attributes cleared for variant $variantId");
    } catch (e) {
      throw Exception("Failed to delete variant attributes: $e");
    }
  }

  /// CREATE a new attribute-value mapping for a variant
  Future<void> createVariantAttribute({
    required String variantId,
    required String attributeId,
    required String attributeValueId,
  }) async {
    try {
      await _variantAttributeCollection.add({
        'variant_id': variantId,
        'attribute_id': attributeId,
        'attribute_value_id': attributeValueId,
        'created_at': DateTime.now(),
      });
    } catch (e) {
      throw Exception("Failed to create variant attribute: $e");
    }
  }
}
