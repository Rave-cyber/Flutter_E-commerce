import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/brand_model.dart';
import '/services/admin/brand_service.dart';
import '/views/admin/admin_brands/form.dart';
import '/widgets/product_search_widget.dart';
import '/widgets/product_filter_widget.dart';
import '/widgets/product_pagination_widget.dart';
import '/widgets/floating_action_button_widget.dart';

class AdminBrandsIndex extends StatefulWidget {
  const AdminBrandsIndex({Key? key}) : super(key: key);

  @override
  State<AdminBrandsIndex> createState() => _AdminBrandsIndexState();
}

class _AdminBrandsIndexState extends State<AdminBrandsIndex> {
  final BrandService _brandService = BrandService();
  final TextEditingController _searchController = TextEditingController();

  String _filterStatus = 'active';
  int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BrandModel> _applyFilterSearchPagination(List<BrandModel> brands) {
    // FILTER
    List<BrandModel> filtered = brands.where((brand) {
      if (_filterStatus == 'active') return !brand.is_archived;
      if (_filterStatus == 'archived') return brand.is_archived;
      return true;
    }).toList();

    // SEARCH
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((brand) => brand.name
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

            // BRAND LIST
            Expanded(
              child: StreamBuilder<List<BrandModel>>(
                stream: _brandService.getBrands(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No brands found.'));
                  }

                  final brands = snapshot.data!;
                  final paginatedBrands = _applyFilterSearchPagination(brands);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedBrands.length,
                          itemBuilder: (context, index) {
                            final brand = paginatedBrands[index];
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
                                      brand.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: brand.is_archived
                                            ? Colors.grey
                                            : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      brand.is_archived ? 'Archived' : 'Active',
                                      style: TextStyle(
                                        color: brand.is_archived
                                            ? Colors.grey[600]
                                            : Colors.green[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
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
                                                builder: (_) => AdminBrandForm(
                                                  brand: brand,
                                                ),
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
                                                  'Are you sure you want to $action "${brand.name}"?',
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
                                                      '${action[0].toUpperCase()}${action.substring(1)}',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await _brandService
                                                  .toggleArchive(brand);
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
                                                    'Are you sure you want to delete "${brand.name}"?'),
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
                                              await _brandService
                                                  .deleteBrand(brand.id);
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
                                            value: brand.is_archived
                                                ? 'unarchive'
                                                : 'archive',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  brand.is_archived
                                                      ? Icons.unarchive
                                                      : Icons.archive,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(brand.is_archived
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
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // PAGINATION CONTROLS - Using ProductPaginationWidget
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ProductPaginationWidget(
                          currentPage: _currentPage,
                          onPreviousPage: _prevPage,
                          onNextPage: () => _nextPage(brands.length),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // FLOATING BUTTON - Using FloatingActionButtonWidget
            FloatingActionButtonWidget(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminBrandForm(),
                  ),
                );
              },
              tooltip: 'Add Brand',
            ),
          ],
        ),
      ),
    );
  }
}
