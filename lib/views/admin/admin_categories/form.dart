import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/category_model.dart';
import '/services/admin/category_service.dart';

class AdminCategoryForm extends StatefulWidget {
  final CategoryModel? category;
  const AdminCategoryForm({Key? key, this.category}) : super(key: key);

  @override
  State<AdminCategoryForm> createState() => _AdminCategoryFormState();
}

class _AdminCategoryFormState extends State<AdminCategoryForm> {
  final _formKey = GlobalKey<FormState>();
  final CategoryService _categoryService = CategoryService();

  late TextEditingController _nameController;
  bool _isArchived = false;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _isArchived = category?.is_archived ?? false;
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final id =
        widget.category?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    final category = CategoryModel(
      id: id,
      name: _nameController.text.trim(),
      is_archived: _isArchived,
      created_at: widget.category?.created_at ?? DateTime.now(),
      updated_at: DateTime.now(),
    );

    if (widget.category == null) {
      await _categoryService.createCategory(category);
    } else {
      await _categoryService.updateCategory(category);
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
                                widget.category == null
                                    ? Icons.add
                                    : Icons.edit,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                widget.category == null
                                    ? 'Add Category'
                                    : 'Edit Category',
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

                        // Category Name Field
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
                                labelText: 'Category Name',
                                labelStyle: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Icon(
                                  Icons.category,
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
                            onPressed: _saveCategory,
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
                                  widget.category == null
                                      ? Icons.add
                                      : Icons.save,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.category == null
                                      ? 'Create Category'
                                      : 'Update Category',
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
