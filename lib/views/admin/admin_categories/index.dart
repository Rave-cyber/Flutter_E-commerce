import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/category_model.dart';
import '/services/admin/category_service.dart';
import '/views/admin/admin_categories/form.dart';

class AdminCategoriesIndex extends StatefulWidget {
  const AdminCategoriesIndex({Key? key}) : super(key: key);

  @override
  State<AdminCategoriesIndex> createState() => _AdminCategoriesIndexState();
}

class _AdminCategoriesIndexState extends State<AdminCategoriesIndex> {
  final CategoryService _categoryService = CategoryService();

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: Stack(
        children: [
          StreamBuilder<List<CategoryModel>>(
            stream: _categoryService.getCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No categories found.'));
              }

              final categories = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              category.is_archived ? Colors.grey : Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        category.is_archived ? 'Archived' : 'Active',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Archive / Unarchive Button
                          IconButton(
                            icon: Icon(
                              category.is_archived
                                  ? Icons.unarchive
                                  : Icons.archive,
                              color: Colors.orange,
                            ),
                            onPressed: () async {
                              await _categoryService.toggleArchive(category);
                            },
                          ),

                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AdminCategoryForm(category: category),
                                ),
                              );
                            },
                          ),

                          // Delete Button
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Confirm Delete'),
                                  content: Text(
                                    'Are you sure you want to delete "${category.name}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _categoryService
                                    .deleteCategory(category.id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // Floating Button for creating a new category
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminCategoryForm(),
                  ),
                );
              },
              child: const Icon(Icons.add),
              tooltip: 'Add Category',
            ),
          ),
        ],
      ),
    );
  }
}
