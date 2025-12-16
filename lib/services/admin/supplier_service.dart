import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/supplier_model.dart';

class SupplierService {
  final CollectionReference _supplierCollection =
      FirebaseFirestore.instance.collection('suppliers');

  /// CREATE supplier
  Future<void> createSupplier(SupplierModel supplier) async {
    await _supplierCollection.doc(supplier.id).set(supplier.toMap());
  }

  /// READ suppliers (live stream)
  Stream<List<SupplierModel>> getSuppliers() {
    return _supplierCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                SupplierModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// UPDATE supplier
  Future<void> updateSupplier(SupplierModel supplier) async {
    await _supplierCollection.doc(supplier.id).update(supplier.toMap());
  }

  /// DELETE supplier
  Future<void> deleteSupplier(String id) async {
    await _supplierCollection.doc(id).delete();
  }

  /// ARCHIVE / UNARCHIVE supplier
  Future<void> toggleArchive(SupplierModel supplier) async {
    final updated = SupplierModel(
      id: supplier.id,
      name: supplier.name,
      address: supplier.address,
      contact: supplier.contact,
      contact_person: supplier.contact_person,
      is_archived: !supplier.is_archived,
      created_at: supplier.created_at,
      updated_at: DateTime.now(),
    );

    await updateSupplier(updated);
  }

  Future<List<SupplierModel>> fetchSuppliersOnce() async {
    final snapshot =
        await _supplierCollection.orderBy('created_at', descending: true).get();

    return snapshot.docs
        .map((doc) => SupplierModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
