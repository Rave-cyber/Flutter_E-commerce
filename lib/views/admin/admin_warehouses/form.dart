import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/warehouse_model.dart';
import '/services/admin/warehouse_service.dart';

class AdminWarehouseForm extends StatefulWidget {
  final WarehouseModel? warehouse;
  const AdminWarehouseForm({Key? key, this.warehouse}) : super(key: key);

  @override
  State<AdminWarehouseForm> createState() => _AdminWarehouseFormState();
}

class _AdminWarehouseFormState extends State<AdminWarehouseForm> {
  final _formKey = GlobalKey<FormState>();
  final WarehouseService _warehouseService = WarehouseService();

  late TextEditingController _nameController;
  bool _isArchived = false;

  @override
  void initState() {
    super.initState();
    final warehouse = widget.warehouse;
    _nameController = TextEditingController(text: warehouse?.name ?? '');
    _isArchived = warehouse?.is_archived ?? false;
  }

  Future<void> _saveWarehouse() async {
    if (!_formKey.currentState!.validate()) return;

    final id = widget.warehouse?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();

    final warehouse = WarehouseModel(
      id: id,
      name: _nameController.text.trim(),
      is_archived: _isArchived,
      created_at: widget.warehouse?.created_at ?? DateTime.now(),
      updated_at: DateTime.now(),
    );

    if (widget.warehouse == null) {
      await _warehouseService.createWarehouse(warehouse);
    } else {
      await _warehouseService.updateWarehouse(warehouse);
    }

    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BACK BUTTON
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),

            const SizedBox(height: 8),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Warehouse Name'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),

                  const SizedBox(height: 12),

                  /// ARCHIVE SWITCH
                  SwitchListTile(
                    title: const Text('Archived'),
                    value: _isArchived,
                    onChanged: (val) => setState(() => _isArchived = val),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _saveWarehouse,
                    child: Text(widget.warehouse == null ? 'Create' : 'Update'),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
