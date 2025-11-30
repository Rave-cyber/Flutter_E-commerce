import 'package:firebase/models/brand_model.dart';
import 'package:firebase/models/category_model.dart';
import 'package:firebase/services/admin/product_sevice.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/product.dart';
import 'form.dart';

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
                labelText: 'Search Products',
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

            // PRODUCT LIST
            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: _productService.getProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }

                  final products = snapshot.data!;
                  final paginatedProducts =
                      _applyFilterSearchPagination(products);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedProducts.length,
                          itemBuilder: (context, index) {
                            final product = paginatedProducts[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: product.image.isNotEmpty
                                    ? Image.network(
                                        product.image,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                    : const Icon(Icons.image),
                                title: Text(
                                  product.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: product.is_archived
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  'Category: ${_getCategoryName(product.category_id)}\n'
                                  'Brand: ${_getBrandName(product.brand_id)}\n'
                                  'Stock: ${product.stock_quantity} | Price: \$${product.sale_price}\n'
                                  '${product.is_archived ? "Archived" : "Active"}',
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Archive / Unarchive
                                    IconButton(
                                      icon: Icon(
                                        product.is_archived
                                            ? Icons.unarchive
                                            : Icons.archive,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () async {
                                        final action = product.is_archived
                                            ? 'unarchive'
                                            : 'archive';
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('Confirm $action'),
                                            content: Text(
                                              'Are you sure you want to $action "${product.name}"?',
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
                                                      action.substring(1),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _productService
                                              .toggleArchive(product);
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
                                            builder: (_) => AdminProductForm(
                                                product: product),
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
                                                'Are you sure you want to delete "${product.name}"?'),
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
                                          await _productService
                                              .deleteProduct(product.id);
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
                            onPressed: () => _nextPage(products.length),
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
                    MaterialPageRoute(builder: (_) => const AdminProductForm()),
                  );
                },
                child: const Icon(Icons.add),
                tooltip: 'Add Product',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
