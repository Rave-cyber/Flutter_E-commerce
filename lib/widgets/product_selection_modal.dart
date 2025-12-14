import 'package:flutter/material.dart';
import 'package:firebase/models/product.dart';
import 'package:firebase/models/product_variant_model.dart';
import '../../../widgets/product_search_widget.dart';
import '../../../widgets/product_filter_widget.dart';
import '../../../widgets/product_pagination_widget.dart';

class ProductSelectionModal extends StatefulWidget {
  final List<ProductModel> products;
  final List<ProductVariantModel> allVariants;
  final ProductModel? selectedProduct;

  const ProductSelectionModal({
    Key? key,
    required this.products,
    required this.allVariants,
    this.selectedProduct,
  }) : super(key: key);

  @override
  State<ProductSelectionModal> createState() => _ProductSelectionModalState();
}

class _ProductSelectionModalState extends State<ProductSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'active';
  int _itemsPerPage = 10;
  int _currentPage = 0;

  bool _hasVariants(ProductModel product) {
    return widget.allVariants
        .any((variant) => variant.product_id == product.id);
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
    final start = (_currentPage) * _itemsPerPage;
    final end = start + _itemsPerPage;
    if (start >= filtered.length) return [];
    return filtered.sublist(
        start, end > filtered.length ? filtered.length : end);
  }

  int _getTotalPages(List<ProductModel> products) {
    // Apply filters
    List<ProductModel> filtered = products.where((product) {
      if (_filterStatus == 'active') return !product.is_archived;
      if (_filterStatus == 'archived') return product.is_archived;
      return true;
    }).toList();

    // Apply search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((product) => product.name
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

  void _nextPage(int totalItems) {
    if (_currentPage * _itemsPerPage < totalItems) {
      setState(() => _currentPage++);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  void _onFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _filterStatus = value;
        _currentPage = 0;
      });
    }
  }

  void _onItemsPerPageChanged(int? value) {
    if (value != null) {
      setState(() {
        _itemsPerPage = value;
        _currentPage = 0;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paginatedProducts = _applyFilterSearchPagination(widget.products);
    final totalPages = _getTotalPages(widget.products);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Select Product',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search Field
              ProductSearchWidget(
                controller: _searchController,
                onChanged: () => setState(() {
                  _currentPage = 0;
                }),
              ),
              const SizedBox(height: 16),

              // Filter and Per Page Dropdown
              ProductFilterWidget(
                filterStatus: _filterStatus,
                itemsPerPage: _itemsPerPage,
                onFilterChanged: _onFilterChanged,
                onItemsPerPageChanged: _onItemsPerPageChanged,
              ),
              const SizedBox(height: 16),

              // Products List with Bottom Controls
              Expanded(
                child: paginatedProducts.isEmpty
                    ? Center(
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
                      )
                    : Column(
                        children: [
                          // Products List
                          Expanded(
                            child: ListView.builder(
                              itemCount: paginatedProducts.length,
                              itemBuilder: (context, index) {
                                final product = paginatedProducts[index];
                                final isSelected =
                                    widget.selectedProduct?.id == product.id;
                                final hasVariants = _hasVariants(product);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.green
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: product.image.isNotEmpty
                                            ? Image.network(
                                                product.image,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Icon(
                                                    hasVariants
                                                        ? Icons.check_circle
                                                        : Icons.remove_circle,
                                                    color: hasVariants
                                                        ? Colors.green
                                                        : Colors.grey,
                                                    size: 24,
                                                  );
                                                },
                                              )
                                            : Icon(
                                                hasVariants
                                                    ? Icons.check_circle
                                                    : Icons.remove_circle,
                                                color: hasVariants
                                                    ? Colors.green
                                                    : Colors.grey,
                                                size: 24,
                                              ),
                                      ),
                                    ),
                                    title: Text(
                                      product.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('SKU: ${product.sku ?? "N/A"}'),
                                        Text(
                                            '₱${product.base_price.toStringAsFixed(2)} - ₱${product.sale_price.toStringAsFixed(2)}'),
                                        Text(
                                            'Stock: ${product.stock_quantity ?? 0}'),
                                        if (hasVariants)
                                          Text(
                                            'Has variants',
                                            style: TextStyle(
                                              color: Colors.green.shade600,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(product),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSelected
                                            ? Colors.green
                                            : Colors.grey.shade100,
                                        foregroundColor: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                          isSelected ? 'Selected' : 'Select'),
                                    ),
                                    onTap: () =>
                                        Navigator.of(context).pop(product),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Bottom Controls - Pagination
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ProductPaginationWidget(
                                currentPage: _currentPage + 1,
                                totalPages: totalPages,
                                onPreviousPage: _prevPage,
                                onNextPage: () =>
                                    _nextPage(widget.products.length),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
