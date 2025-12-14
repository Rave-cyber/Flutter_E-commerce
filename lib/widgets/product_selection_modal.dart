import 'package:flutter/material.dart';
import 'package:firebase/models/product.dart';
import 'package:firebase/models/product_variant_model.dart';

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
  final TextEditingController _itemsPerPageController = TextEditingController();

  List<ProductModel> _filteredProducts = [];
  int _currentPage = 0;
  int _itemsPerPage = 10;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredProducts = widget.products;
    _itemsPerPageController.text = _itemsPerPage.toString();
  }

  bool _hasVariants(ProductModel product) {
    return widget.allVariants
        .any((variant) => variant.product_id == product.id);
  }

  void _filterProducts() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _currentPage = 0; // Reset to first page when filtering

      if (_searchQuery.isEmpty) {
        _filteredProducts = widget.products;
      } else {
        _filteredProducts = widget.products.where((product) {
          return product.name.toLowerCase().contains(_searchQuery) ||
              (product.sku?.toLowerCase().contains(_searchQuery) ?? false);
        }).toList();
      }
    });
  }

  void _updateItemsPerPage(String value) {
    setState(() {
      _itemsPerPage = int.tryParse(value) ?? 10;
      _currentPage = 0; // Reset to first page when changing items per page
    });
  }

  List<ProductModel> _getCurrentPageProducts() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex =
        (startIndex + _itemsPerPage).clamp(0, _filteredProducts.length);

    if (startIndex >= _filteredProducts.length) {
      return [];
    }

    return _filteredProducts.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_filteredProducts.length / _itemsPerPage).ceil();

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _itemsPerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentProducts = _getCurrentPageProducts();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Select Product',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name or SKU',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _filterProducts(),
            ),
            const SizedBox(height: 16),

            // Controls Row
            Row(
              children: [
                const Text('Items per page:'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _itemsPerPageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onSubmitted: _updateItemsPerPage,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                    'Showing ${currentProducts.length} of ${_filteredProducts.length} products'),
              ],
            ),
            const SizedBox(height: 16),

            // Products Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('SKU')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Variants')),
                      DataColumn(label: Text('Base Price')),
                      DataColumn(label: Text('Sale Price')),
                      DataColumn(label: Text('Stock')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: currentProducts.map((product) {
                      final isSelected =
                          widget.selectedProduct?.id == product.id;
                      final hasVariants = _hasVariants(product);
                      return DataRow(
                        selected: isSelected,
                        onSelectChanged: (selected) {
                          if (selected == true) {
                            Navigator.of(context).pop(product);
                          }
                        },
                        cells: [
                          DataCell(Text(product.sku ?? 'N/A')),
                          DataCell(Text(product.name)),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasVariants
                                      ? Icons.check_circle
                                      : Icons.remove_circle,
                                  color:
                                      hasVariants ? Colors.green : Colors.grey,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(hasVariants ? 'Yes' : 'No'),
                              ],
                            ),
                          ),
                          DataCell(Text(
                              '₱${product.base_price.toStringAsFixed(2)}')),
                          DataCell(Text(
                              '₱${product.sale_price.toStringAsFixed(2)}')),
                          DataCell(
                              Text(product.stock_quantity?.toString() ?? '0')),
                          DataCell(
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(product),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    isSelected ? Colors.green : null,
                              ),
                              child: Text(isSelected ? 'Selected' : 'Select'),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pagination Controls
            Row(
              children: [
                const Text('Page:'),
                const SizedBox(width: 8),
                Text(
                  '${_currentPage + 1} of $_totalPages',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                  disabledColor: Colors.grey,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      _currentPage < _totalPages - 1 ? _goToNextPage : null,
                  disabledColor: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
