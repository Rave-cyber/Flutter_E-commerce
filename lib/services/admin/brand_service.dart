import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/brand_model.dart';

class BrandService {
  final CollectionReference _brandCollection =
      FirebaseFirestore.instance.collection('brands');

  /// CREATE brand
  Future<void> createBrand(BrandModel brand) async {
    await _brandCollection.doc(brand.id).set(brand.toMap());
  }

  /// READ brands (stream for UI)
  Stream<List<BrandModel>> getBrands() {
    return _brandCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(
                (doc) => BrandModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// UPDATE brand
  Future<void> updateBrand(BrandModel brand) async {
    await _brandCollection.doc(brand.id).update(brand.toMap());
  }

  /// DELETE brand
  Future<void> deleteBrand(String id) async {
    await _brandCollection.doc(id).delete();
  }

  /// 🔥 ARCHIVE / UNARCHIVE
  Future<void> toggleArchive(BrandModel brand) async {
    final updated = BrandModel(
      id: brand.id,
      name: brand.name,
      is_archived: !brand.is_archived,
      created_at: brand.created_at,
      updated_at: DateTime.now(),
    );

    await updateBrand(updated);
  }
}
