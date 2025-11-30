import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/brand_model.dart';
import '/services/admin/brand_service.dart';

class AdminBrandForm extends StatefulWidget {
  final BrandModel? brand;
  const AdminBrandForm({Key? key, this.brand}) : super(key: key);

  @override
  State<AdminBrandForm> createState() => _AdminBrandFormState();
}

class _AdminBrandFormState extends State<AdminBrandForm> {
  final _formKey = GlobalKey<FormState>();
  final BrandService _brandService = BrandService();

  late TextEditingController _nameController;
  bool _isArchived = false;

  @override
  void initState() {
    super.initState();
    final brand = widget.brand;
    _nameController = TextEditingController(text: brand?.name ?? '');
    _isArchived = brand?.is_archived ?? false;
  }

  Future<void> _saveBrand() async {
    if (!_formKey.currentState!.validate()) return;

    final id =
        widget.brand?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final brand = BrandModel(
      id: id,
      name: _nameController.text.trim(),
      is_archived: _isArchived,
      created_at: widget.brand?.created_at ?? DateTime.now(),
      updated_at: DateTime.now(),
    );

    if (widget.brand == null) {
      await _brandService.createBrand(brand);
    } else {
      await _brandService.updateBrand(brand);
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
              onPressed: () {
                Navigator.pop(context);
              },
            ),

            const SizedBox(height: 8),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Brand Name'),
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
                    onPressed: _saveBrand,
                    child: Text(widget.brand == null ? 'Create' : 'Update'),
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
