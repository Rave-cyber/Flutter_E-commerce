import 'package:firebase/models/brand_model.dart';
import 'package:firebase/models/category_model.dart';
import 'package:firebase/services/admin/product_sevice.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/product.dart';
import 'form.dart';
import '../../../widgets/product_search_widget.dart';
import '../../../widgets/product_filter_widget.dart';
import '../../../widgets/product_card_widget.dart';
import '../../../widgets/product_pagination_widget.dart';
import '../../../widgets/floating_action_button_widget.dart';

class AdminProductsIndex extends StatefulWidget {
  const AdminProductsIndex({Key? key}) : super(key: key);

  @override
  State<AdminProductsIndex> createState() => _AdminProductsIndexState();
}

class _AdminProductsIndexState extends State<AdminProductsIndex> {
  final ProductService _productService = ProductService();

  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'active';
  int _itemsPerPage = 10;
  int _currentPage = 1;

  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdowns() async {
    final categories = await _productService.fetchCategories();
    final brands = await _productService.fetchBrands();

    setState(() {
      _categories = categories;
      _brands = brands;
    });
  }

  String _getCategoryName(String categoryId) {
    return _categories
        .firstWhere(
          (c) => c.id == categoryId,
          orElse: () =>
              CategoryModel(id: '', name: 'Unknown', is_archived: false),
        )
        .name;
  }

  String _getBrandName(String brandId) {
    return _brands
        .firstWhere(
          (b) => b.id == brandId,
          orElse: () => BrandModel(id: '', name: 'Unknown', is_archived: false),
        )
        .name;
  }

  List<ProductModel> _applyFilterSearchPagination(List<ProductModel> products) {
    // FILTER
    List<ProductModel> filtered = products.where((product) {
      if (_filterStatus == 'active') return !product.is_archived;
      if (_filterStatus == 'archived') return product.is_archived;
      return true;
    }).toList();

    // SEARCH
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((product) => product.name
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

  Future<void> _handleMenuSelection(String value, ProductModel product) async {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminProductForm(product: product),
          ),
        );
        break;
      case 'archive':
      case 'unarchive':
        final action = product.is_archived ? 'unarchive' : 'archive';
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Confirm $action'),
            content: Text(
              'Are you sure you want to $action "${product.name}"?',
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
          await _productService.toggleArchive(product);
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
              'Are you sure you want to delete "${product.name}"?',
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
          await _productService.deleteProduct(product.id);
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SEARCH FIELD
            ProductSearchWidget(
              controller: _searchController,
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

            // PRODUCT LIST WITH BOTTOM CONTROLS
            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: _productService.getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                              Icon(Icons.inventory_2_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No products found.',
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
                  }

                  final products = snapshot.data!;
                  final paginatedProducts =
                      _applyFilterSearchPagination(products);

                  return Column(
                    children: [
                      // PRODUCT LIST
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedProducts.length,
                          itemBuilder: (context, index) {
                            final product = paginatedProducts[index];

                            return ProductCardWidget(
                              product: product,
                              getCategoryName: _getCategoryName,
                              getBrandName: _getBrandName,
                              onMenuSelected: (value) =>
                                  _handleMenuSelection(value, product),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // BOTTOM CONTROLS - Pagination (left) and Add Button (right) in one line
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // PAGINATION CONTROLS - Left end
                          ProductPaginationWidget(
                            currentPage: _currentPage,
                            onPreviousPage: _prevPage,
                            onNextPage: () => _nextPage(products.length),
                          ),

                          // ADD PRODUCT BUTTON - Right end
                          FloatingActionButtonWidget(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminProductForm()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
