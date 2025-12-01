import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category_model.dart';

class CustomerCategoryService {
  final CollectionReference _categoryCollection =
      FirebaseFirestore.instance.collection('categories');

  /// Get all active categories with workaround for missing index
  Stream<List<CategoryModel>> getActiveCategories() {
    try {
      // Try the optimized query first
      return _categoryCollection
          .where('is_archived', isEqualTo: false)
          .orderBy('name')
          .snapshots()
          .map((snapshot) => _processCategories(snapshot))
          .handleError((error) {
        print('Optimized query failed, falling back to simple query: $error');
        // Fall back to simple query
        return _getCategoriesSimpleStream();
      });
    } catch (e) {
      print('Error in getActiveCategories, using fallback: $e');
      return _getCategoriesSimpleStream();
    }
  }

  /// Simple query without composite index requirements
  Stream<List<CategoryModel>> _getCategoriesSimpleStream() {
    return _categoryCollection.snapshots().map((snapshot) {
      return _processCategories(snapshot, filterArchived: true);
    });
  }

  /// Process categories from snapshot
  List<CategoryModel> _processCategories(
    QuerySnapshot snapshot, {
    bool filterArchived = false,
  }) {
    if (snapshot.docs.isEmpty) {
      return [];
    }

    final categories = <CategoryModel>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data == null) continue;

      final mapData = data as Map<String, dynamic>;

      // Apply filtering if requested
      if (filterArchived && mapData['is_archived'] == true) {
        continue;
      }

      final category = CategoryModel(
        id: mapData['id']?.toString() ?? doc.id,
        name: mapData['name']?.toString() ?? 'Unknown',
        is_archived: mapData['is_archived'] ?? false,
        created_at: (mapData['created_at'] as Timestamp?)?.toDate(),
        updated_at: (mapData['updated_at'] as Timestamp?)?.toDate(),
      );

      categories.add(category);
    }

    // Sort by name
    categories.sort((a, b) => a.name.compareTo(b.name));

    return categories;
  }

  /// Alternative: Get categories with a different query pattern
  Stream<List<CategoryModel>> getCategoriesAlternative() {
    // Query without ordering first, then sort locally
    return _categoryCollection
        .where('is_archived', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return [];

      final categories = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data == null) {
          return CategoryModel(
            id: doc.id,
            name: 'Unknown',
            is_archived: false,
            created_at: null,
            updated_at: null,
          );
        }

        final mapData = data as Map<String, dynamic>;
        return CategoryModel(
          id: mapData['id']?.toString() ?? doc.id,
          name: mapData['name']?.toString() ?? 'Unknown',
          is_archived: mapData['is_archived'] ?? false,
          created_at: (mapData['created_at'] as Timestamp?)?.toDate(),
          updated_at: (mapData['updated_at'] as Timestamp?)?.toDate(),
        );
      }).toList();

      // Sort locally
      categories.sort((a, b) => a.name.compareTo(b.name));
      return categories;
    });
  }
}
