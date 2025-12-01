import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/warehouse_model.dart';

class WarehouseService {
  final CollectionReference _warehouseCollection =
      FirebaseFirestore.instance.collection('warehouses');

  /// CREATE warehouse
  Future<void> createWarehouse(WarehouseModel warehouse) async {
    await _warehouseCollection.doc(warehouse.id).set(warehouse.toMap());
  }

  /// READ warehouses (stream for UI)
  Stream<List<WarehouseModel>> getWarehouses() {
    return _warehouseCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                WarehouseModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// UPDATE warehouse
  Future<void> updateWarehouse(WarehouseModel warehouse) async {
    await _warehouseCollection.doc(warehouse.id).update(warehouse.toMap());
  }

  /// DELETE warehouse
  Future<void> deleteWarehouse(String id) async {
    await _warehouseCollection.doc(id).delete();
  }

  /// 🔥 ARCHIVE / UNARCHIVE
  Future<void> toggleArchive(WarehouseModel warehouse) async {
    final updated = WarehouseModel(
      id: warehouse.id,
      name: warehouse.name,
      is_archived: !warehouse.is_archived,
      created_at: warehouse.created_at,
      updated_at: DateTime.now(),
    );

    await updateWarehouse(updated);
  }

  Future<List<WarehouseModel>> fetchWarehousesOnce() async {
    final snapshot = await _warehouseCollection
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map(
            (doc) => WarehouseModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
