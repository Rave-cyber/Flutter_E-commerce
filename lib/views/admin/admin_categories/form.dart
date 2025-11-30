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
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
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
                onPressed: _saveCategory,
                child: Text(widget.category == null ? 'Create' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
