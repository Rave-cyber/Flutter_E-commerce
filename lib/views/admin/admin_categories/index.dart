import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/category_model.dart';
import '/services/admin/category_service.dart';
import '/views/admin/admin_categories/form.dart';
import '/widgets/product_search_widget.dart';
import '/widgets/product_filter_widget.dart';
import '/widgets/product_pagination_widget.dart';
import '/widgets/floating_action_button_widget.dart';

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

<<<<<<< HEAD
  int _getTotalPages(List<CategoryModel> categories) {
    // Apply filters
    List<CategoryModel> filtered = categories.where((cat) {
      if (_filterStatus == 'active') return !cat.is_archived;
      if (_filterStatus == 'archived') return cat.is_archived;
      return true;
    }).toList();

    // Apply search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((cat) => cat.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    }

    // Calculate total pages
    if (filtered.isEmpty) {
      return 1;
    }

    return (filtered.length + _itemsPerPage - 1) ~/ _itemsPerPage;
  }

=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
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

<<<<<<< HEAD
  Future<void> _handleMenuSelection(
      String value, CategoryModel category) async {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminCategoryForm(category: category),
          ),
        );
        break;
      case 'archive':
      case 'unarchive':
        final action = category.is_archived ? 'unarchive' : 'archive';
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Confirm $action'),
            content: Text(
              'Are you sure you want to $action "${category.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                ),
                child: Text(
                  action[0].toUpperCase() + action.substring(1),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await _categoryService.toggleArchive(category);
        }
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Confirm Delete'),
            content: Text(
              'Are you sure you want to delete "${category.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  elevation: 2,
                ),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await _categoryService.deleteCategory(category.id);
        }
        break;
    }
  }

  void _onFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _filterStatus = value;
        _currentPage = 1;
      });
    }
  }

  void _onItemsPerPageChanged(int? value) {
    if (value != null) {
      setState(() {
        _itemsPerPage = value;
        _currentPage = 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedRoute: '/admin/categories',
=======
  @override
  Widget build(BuildContext context) {
    return AdminLayout(
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
<<<<<<< HEAD
            // SEARCH FIELD
            ProductSearchWidget(
              controller: _searchController,
              placeholder: 'Search categories',
              onChanged: () => setState(() {
                _currentPage = 1;
              }),
            ),
            const SizedBox(height: 16),

            // FILTER AND PER PAGE DROPDOWN
            ProductFilterWidget(
              filterStatus: _filterStatus,
              itemsPerPage: _itemsPerPage,
              onFilterChanged: _onFilterChanged,
              onItemsPerPageChanged: _onItemsPerPageChanged,
            ),
            const SizedBox(height: 16),

            // CATEGORY LIST WITH BOTTOM CONTROLS
=======
            // SEARCH FIELD - Using ProductSearchWidget
            ProductSearchWidget(
              controller: _searchController,
              onChanged: () {
                setState(() {
                  _currentPage = 1;
                });
              },
            ),
            const SizedBox(height: 16),

            // FILTER WIDGET - Using ProductFilterWidget
            ProductFilterWidget(
              filterStatus: _filterStatus,
              itemsPerPage: _itemsPerPage,
              onFilterChanged: (val) {
                if (val != null) {
                  setState(() {
                    _filterStatus = val;
                    _currentPage = 1;
                  });
                }
              },
              onItemsPerPageChanged: (val) {
                if (val != null) {
                  setState(() {
                    _itemsPerPage = val;
                    _currentPage = 1;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // CATEGORY LIST
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
            Expanded(
              child: StreamBuilder<List<CategoryModel>>(
                stream: _categoryService.getCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
<<<<<<< HEAD
                    return Center(
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.category_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No categories found.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
=======
                    return const Center(child: Text('No categories found.'));
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                  }

                  final categories = snapshot.data!;
                  final paginatedCategories =
                      _applyFilterSearchPagination(categories);
<<<<<<< HEAD
                  final totalPages = _getTotalPages(categories);

                  return Column(
                    children: [
                      // CATEGORY LIST
=======

                  return Column(
                    children: [
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedCategories.length,
                          itemBuilder: (context, index) {
                            final category = paginatedCategories[index];
<<<<<<< HEAD

=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Material(
                                elevation: 0,
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.white,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(
                                      category.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: category.is_archived
                                            ? Colors.grey
                                            : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      category.is_archived
                                          ? 'Archived'
                                          : 'Active',
                                      style: TextStyle(
                                        color: category.is_archived
                                            ? Colors.grey[600]
                                            : Colors.green[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
<<<<<<< HEAD
                                    trailing: PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: Colors.grey[700],
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 8,
                                      onSelected: (value) =>
                                          _handleMenuSelection(value, category),
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 20),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: category.is_archived
                                              ? 'unarchive'
                                              : 'archive',
                                          child: Row(
                                            children: [
                                              Icon(
                                                category.is_archived
                                                    ? Icons.unarchive
                                                    : Icons.archive,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(category.is_archived
                                                  ? 'Unarchive'
                                                  : 'Archive'),
                                            ],
                                          ),
                                        ),
                                        // const PopupMenuItem(
                                        //   value: 'delete',
                                        //   child: Row(
                                        //     children: [
                                        //       Icon(Icons.delete,
                                        //           size: 20, color: Colors.red),
                                        //       SizedBox(width: 8),
                                        //       Text('Delete',
                                        //           style: TextStyle(
                                        //               color: Colors.red)),
                                        //     ],
                                        //   ),
                                        // ),
                                      ],
=======
                                    trailing: Material(
                                      elevation: 2,
                                      shadowColor:
                                          Colors.black.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[50],
                                      child: PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: Colors.grey[700],
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 8,
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AdminCategoryForm(
                                                        category: category),
                                              ),
                                            );
                                          } else if (value == 'archive' ||
                                              value == 'unarchive') {
                                            final action = value;
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                title: Text('Confirm $action'),
                                                content: Text(
                                                  'Are you sure you want to $action "${category.name}"?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.orange,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                    child: Text(
                                                      action[0].toUpperCase() +
                                                          action.substring(1),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await _categoryService
                                                  .toggleArchive(category);
                                            }
                                          } else if (value == 'delete') {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                title: const Text(
                                                    'Confirm Delete'),
                                                content: Text(
                                                    'Are you sure you want to delete "${category.name}"?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await _categoryService
                                                  .deleteCategory(category.id);
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 20),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: category.is_archived
                                                ? 'unarchive'
                                                : 'archive',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  category.is_archived
                                                      ? Icons.unarchive
                                                      : Icons.archive,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(category.is_archived
                                                    ? 'Unarchive'
                                                    : 'Archive'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    size: 20,
                                                    color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

<<<<<<< HEAD
                      const SizedBox(height: 16),

                      // BOTTOM CONTROLS - Pagination (left) and Add Button (right) in one line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // PAGINATION CONTROLS - Left end
                          ProductPaginationWidget(
                            currentPage: _currentPage,
                            totalPages: totalPages,
                            onPreviousPage: _prevPage,
                            onNextPage: () => _nextPage(categories.length),
                          ),

                          // ADD CATEGORY BUTTON - Right end
                          FloatingActionButtonWidget(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminCategoryForm()),
                              );
                            },
                          ),
                        ],
=======
                      // PAGINATION CONTROLS - Using ProductPaginationWidget
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ProductPaginationWidget(
                          currentPage: _currentPage,
                          onPreviousPage: _prevPage,
                          onNextPage: () => _nextPage(categories.length),
                        ),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                      ),
                    ],
                  );
                },
              ),
            ),
<<<<<<< HEAD
=======

            // FLOATING BUTTON - Using FloatingActionButtonWidget
            FloatingActionButtonWidget(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminCategoryForm(),
                  ),
                );
              },
              tooltip: 'Add Category',
            ),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
          ],
        ),
      ),
    );
  }
}
