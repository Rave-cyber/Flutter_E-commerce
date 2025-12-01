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
  final TextEditingController _searchController = TextEditingController();

  String _filterStatus = 'active';
  int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryModel> _applyFilterSearchPagination(
      List<CategoryModel> categories) {
    // FILTER
    List<CategoryModel> filtered = categories.where((cat) {
      if (_filterStatus == 'active') return !cat.is_archived;
      if (_filterStatus == 'archived') return cat.is_archived;
      return true;
    }).toList();

    // SEARCH
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((cat) => cat.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    }

    // PAGINATION
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    if (start >= filtered.length) return [];
    return filtered.sublist(
        start, end > filtered.length ? filtered.length : end);
  }

  void _nextPage(int totalItems) {
    if (_currentPage * _itemsPerPage < totalItems) {
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      setState(() => _currentPage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SEARCH FIELD
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Categories',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {
                _currentPage = 1;
              }),
            ),
            const SizedBox(height: 12),

            // FILTER DROPDOWN
            Row(
              children: [
                const Text('Filter: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                        value: 'archived', child: Text('Archived')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _filterStatus = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // CATEGORY LIST
            Expanded(
              child: StreamBuilder<List<CategoryModel>>(
                stream: _categoryService.getCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No categories found.'));
                  }

                  final categories = snapshot.data!;
                  final paginatedCategories =
                      _applyFilterSearchPagination(categories);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedCategories.length,
                          itemBuilder: (context, index) {
                            final category = paginatedCategories[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: category.is_archived
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Text(category.is_archived
                                    ? 'Archived'
                                    : 'Active'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Archive / Unarchive
                                    IconButton(
                                      icon: Icon(
                                        category.is_archived
                                            ? Icons.unarchive
                                            : Icons.archive,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () async {
                                        final action = category.is_archived
                                            ? 'unarchive'
                                            : 'archive';
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('Confirm $action'),
                                            content: Text(
                                              'Are you sure you want to $action "${category.name}"?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: Text(
                                                    action[0].toUpperCase() +
                                                        action.substring(1)),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _categoryService
                                              .toggleArchive(category);
                                        }
                                      },
                                    ),
                                    // Edit
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AdminCategoryForm(
                                                category: category),
                                          ),
                                        );
                                      },
                                    ),
                                    // Delete
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Confirm Delete'),
                                            content: Text(
                                                'Are you sure you want to delete "${category.name}"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
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
                        ),
                      ),

                      // PAGINATION CONTROLS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _prevPage,
                          ),
                          Text('Page $_currentPage'),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () => _nextPage(categories.length),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // FLOATING BUTTON
            Align(
              alignment: Alignment.bottomRight,
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
      ),
    );
  }
}
