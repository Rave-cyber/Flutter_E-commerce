import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/supplier_model.dart';
import '/services/admin/supplier_service.dart';

class AdminSupplierForm extends StatefulWidget {
  final SupplierModel? supplier;
  const AdminSupplierForm({Key? key, this.supplier}) : super(key: key);

  @override
  State<AdminSupplierForm> createState() => _AdminSupplierFormState();
}

class _AdminSupplierFormState extends State<AdminSupplierForm> {
  final _formKey = GlobalKey<FormState>();
  final SupplierService _supplierService = SupplierService();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  late TextEditingController _contactPersonController;

  bool _isArchived = false;

  @override
  void initState() {
    super.initState();

    final supplier = widget.supplier;

    _nameController = TextEditingController(text: supplier?.name ?? '');
    _addressController = TextEditingController(text: supplier?.address ?? '');
    _contactController = TextEditingController(text: supplier?.contact ?? '');
    _contactPersonController =
        TextEditingController(text: supplier?.contact_person ?? '');

    _isArchived = supplier?.is_archived ?? false;
  }

  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    final id =
        widget.supplier?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final supplier = SupplierModel(
      id: id,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      contact: _contactController.text.trim(),
      contact_person: _contactPersonController.text.trim(),
      is_archived: _isArchived,
      created_at: widget.supplier?.created_at ?? DateTime.now(),
      updated_at: DateTime.now(),
    );

    if (widget.supplier == null) {
      await _supplierService.createSupplier(supplier);
    } else {
      await _supplierService.updateSupplier(supplier);
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
                  // NAME
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Supplier Name'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // ADDRESS
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // CONTACT
                  TextFormField(
                    controller: _contactController,
                    decoration:
                        const InputDecoration(labelText: 'Contact Number'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // CONTACT PERSON
                  TextFormField(
                    controller: _contactPersonController,
                    decoration:
                        const InputDecoration(labelText: 'Contact Person'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  /// ARCHIVED SWITCH
                  SwitchListTile(
                    title: const Text('Archived'),
                    value: _isArchived,
                    onChanged: (val) => setState(() => _isArchived = val),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _saveSupplier,
                    child: Text(widget.supplier == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
