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
            // BACK BUTTON with improved styling
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.blue),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FORM CONTAINER with improved styling
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                elevation: 0,
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                widget.brand == null ? Icons.add : Icons.edit,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                widget.brand == null
                                    ? 'Add Brand'
                                    : 'Edit Brand',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Brand Name Field
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Material(
                            elevation: 1,
                            borderRadius: BorderRadius.circular(12),
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Brand Name',
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(
                                  Icons.storefront,
                                  color: Colors.green.shade600,
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.green.shade400,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ARCHIVED SWITCH with improved styling
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Material(
                            elevation: 1,
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.orange.shade50,
                            child: SwitchListTile(
                              title: Row(
                                children: [
                                  Icon(
                                    _isArchived
                                        ? Icons.unarchive
                                        : Icons.archive,
                                    color: Colors.orange.shade600,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Archived',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              value: _isArchived,
                              onChanged: (val) =>
                                  setState(() => _isArchived = val),
                              activeColor: Colors.orange.shade600,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // SAVE BUTTON with improved styling
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _saveBrand,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: Colors.green.withOpacity(0.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.brand == null ? Icons.add : Icons.save,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.brand == null
                                      ? 'Create Brand'
                                      : 'Update Brand',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
