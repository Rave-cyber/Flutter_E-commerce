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
            // SEARCH FIELD - Elevated
            Material(
              elevation: 4,
              shadowColor: Colors.green.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search Products',
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  filled: true,
                  fillColor: Colors.white,
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
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                onChanged: (_) => setState(() {
                  _currentPage = 1;
                }),
              ),
            ),
            const SizedBox(height: 16),

            // FILTER DROPDOWN - Elevated
            Material(
              elevation: 3,
              shadowColor: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterStatus,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All')),
                            DropdownMenuItem(
                                value: 'active', child: Text('Active')),
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PRODUCT LIST
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
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedProducts.length,
                          itemBuilder: (context, index) {
                            final product = paginatedProducts[index];

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
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Header Row with Image, Title, and Menu
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Product Image - Elevated
                                            Material(
                                              elevation: 4,
                                              shadowColor:
                                                  Colors.black.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: Colors.grey[50],
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: product
                                                          .image.isNotEmpty
                                                      ? Image.network(
                                                          product.image,
                                                          width: 80,
                                                          height: 80,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return const Icon(
                                                              Icons
                                                                  .image_not_supported,
                                                              size: 40,
                                                              color:
                                                                  Colors.grey,
                                                            );
                                                          },
                                                        )
                                                      : const Icon(
                                                          Icons
                                                              .image_not_supported,
                                                          size: 40,
                                                          color: Colors.grey,
                                                        ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 16),

                                            // Product Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Product Name and Status
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          product.name,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: product
                                                                    .is_archived
                                                                ? Colors.grey
                                                                : Colors
                                                                    .black87,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      // Status Badge - Elevated
                                                      Material(
                                                        elevation: 2,
                                                        shadowColor: product
                                                                .is_archived
                                                            ? Colors.red
                                                                .withOpacity(
                                                                    0.3)
                                                            : Colors.green
                                                                .withOpacity(
                                                                    0.3),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 5),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: product
                                                                    .is_archived
                                                                ? Colors
                                                                    .red[100]
                                                                : Colors
                                                                    .green[100],
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          ),
                                                          child: Text(
                                                            product.is_archived
                                                                ? 'Archived'
                                                                : 'Active',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: product
                                                                      .is_archived
                                                                  ? Colors
                                                                      .red[700]
                                                                  : Colors.green[
                                                                      700],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),

                                                  // Category and Brand
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.category,
                                                        size: 16,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _getCategoryName(product
                                                            .category_id),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Icon(
                                                        Icons.storefront,
                                                        size: 16,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        _getBrandName(
                                                            product.brand_id),
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // 3-Dots Menu - Elevated
                                            Material(
                                              elevation: 2,
                                              shadowColor:
                                                  Colors.black.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                  switch (value) {
                                                    case 'edit':
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              AdminProductForm(
                                                                  product:
                                                                      product),
                                                        ),
                                                      );
                                                      break;
                                                    case 'archive':
                                                    case 'unarchive':
                                                      final action =
                                                          product.is_archived
                                                              ? 'unarchive'
                                                              : 'archive';
                                                      final confirm =
                                                          await showDialog<
                                                              bool>(
                                                        context: context,
                                                        builder: (_) =>
                                                            AlertDialog(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        16),
                                                          ),
                                                          title: Text(
                                                              'Confirm $action'),
                                                          content: Text(
                                                            'Are you sure you want to $action "${product.name}"?',
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      false),
                                                              child: const Text(
                                                                  'Cancel'),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      true),
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                elevation: 2,
                                                              ),
                                                              child: Text(
                                                                action[0]
                                                                        .toUpperCase() +
                                                                    action
                                                                        .substring(
                                                                            1),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );

                                                      if (confirm == true) {
                                                        await _productService
                                                            .toggleArchive(
                                                                product);
                                                      }
                                                      break;
                                                    case 'delete':
                                                      final confirm =
                                                          await showDialog<
                                                              bool>(
                                                        context: context,
                                                        builder: (_) =>
                                                            AlertDialog(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        16),
                                                          ),
                                                          title: const Text(
                                                              'Confirm Delete'),
                                                          content: Text(
                                                              'Are you sure you want to delete "${product.name}"?'),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      false),
                                                              child: const Text(
                                                                  'Cancel'),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      true),
                                                              style:
                                                                  ElevatedButton
                                                                      .styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                elevation: 2,
                                                              ),
                                                              child: const Text(
                                                                'Delete',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );

                                                      if (confirm == true) {
                                                        await _productService
                                                            .deleteProduct(
                                                                product.id);
                                                      }
                                                      break;
                                                  }
                                                },
                                                itemBuilder: (context) => [
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.edit,
                                                            size: 20),
                                                        SizedBox(width: 8),
                                                        Text('Edit'),
                                                      ],
                                                    ),
                                                  ),
                                                  PopupMenuItem(
                                                    value: product.is_archived
                                                        ? 'unarchive'
                                                        : 'archive',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          product.is_archived
                                                              ? Icons.unarchive
                                                              : Icons.archive,
                                                          size: 20,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(product.is_archived
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
                                                                color: Colors
                                                                    .red)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 16),

                                        // Divider
                                        Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Colors.green.shade200,
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Bottom Row with Stock and Price
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Stock Info - Elevated
                                            Material(
                                              elevation: 2,
                                              shadowColor:
                                                  Colors.black.withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.inventory_2,
                                                      size: 18,
                                                      color: (product.stock_quantity ??
                                                                  0) >
                                                              10
                                                          ? Colors.green[600]
                                                          : (product.stock_quantity ??
                                                                      0) >
                                                                  0
                                                              ? Colors
                                                                  .orange[600]
                                                              : Colors.red[600],
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      'Stock: ${product.stock_quantity ?? 0}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: (product.stock_quantity ??
                                                                    0) >
                                                                10
                                                            ? Colors.green[600]
                                                            : (product.stock_quantity ??
                                                                        0) >
                                                                    0
                                                                ? Colors
                                                                    .orange[600]
                                                                : Colors
                                                                    .red[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            // Price - Elevated
                                            Material(
                                              elevation: 3,
                                              shadowColor:
                                                  Colors.green.withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.green.shade400,
                                                      Colors.green.shade600,
                                                    ],
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '\$${product.sale_price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // PAGINATION CONTROLS - Elevated
                      Material(
                        elevation: 4,
                        shadowColor: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                elevation: 0,
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: _prevPage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(Icons.arrow_back_ios_new,
                                        size: 18, color: Colors.green[700]),
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Page $_currentPage',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Material(
                                elevation: 0,
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => _nextPage(products.length),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(Icons.arrow_forward_ios,
                                        size: 18, color: Colors.green[700]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // FLOATING BUTTON - Enhanced elevation
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
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
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminProductForm()),
                    );
                  },
                  backgroundColor: Colors.green,
                  elevation: 8,
                  highlightElevation: 12,
                  child: const Icon(Icons.add, color: Colors.white, size: 28),
                  tooltip: 'Add Product',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
