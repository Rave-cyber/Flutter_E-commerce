import 'package:flutter/material.dart';
import 'package:firebase/models/product_variant_model.dart';

class ProductVariantSelectionModal extends StatefulWidget {
  final List<ProductVariantModel> variants;
  final ProductVariantModel? selectedVariant;

  const ProductVariantSelectionModal({
    Key? key,
    required this.variants,
    this.selectedVariant,
  }) : super(key: key);

  @override
  State<ProductVariantSelectionModal> createState() =>
      _ProductVariantSelectionModalState();
}

class _ProductVariantSelectionModalState
    extends State<ProductVariantSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _itemsPerPageController = TextEditingController();

  List<ProductVariantModel> _filteredVariants = [];
  int _currentPage = 0;
  int _itemsPerPage = 10;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredVariants = widget.variants;
    _itemsPerPageController.text = _itemsPerPage.toString();
  }

  void _filterVariants() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();
      _currentPage = 0; // Reset to first page when filtering

      if (_searchQuery.isEmpty) {
        _filteredVariants = widget.variants;
      } else {
        _filteredVariants = widget.variants.where((variant) {
          return variant.name.toLowerCase().contains(_searchQuery) ||
              (variant.sku?.toLowerCase().contains(_searchQuery) ?? false);
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

  List<ProductVariantModel> _getCurrentPageVariants() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex =
        (startIndex + _itemsPerPage).clamp(0, _filteredVariants.length);

    if (startIndex >= _filteredVariants.length) {
      return [];
    }

    return _filteredVariants.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_filteredVariants.length / _itemsPerPage).ceil();

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
    final currentVariants = _getCurrentPageVariants();

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
                  'Select Product Variant',
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
              onChanged: (value) => _filterVariants(),
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
                    'Showing ${currentVariants.length} of ${_filteredVariants.length} variants'),
              ],
            ),
            const SizedBox(height: 16),

            // Variants Table
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
                      DataColumn(label: Text('Base Price')),
                      DataColumn(label: Text('Sale Price')),
                      DataColumn(label: Text('Stock')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: currentVariants.map((variant) {
                      final isSelected =
                          widget.selectedVariant?.id == variant.id;
                      return DataRow(
                        selected: isSelected,
                        onSelectChanged: (selected) {
                          if (selected == true) {
                            Navigator.of(context).pop(variant);
                          }
                        },
                        cells: [
                          DataCell(Text(variant.sku ?? 'N/A')),
                          DataCell(Text(variant.name)),
                          DataCell(Text(
                              '₱${variant.base_price.toStringAsFixed(2)}')),
                          DataCell(Text(
                              '₱${variant.sale_price.toStringAsFixed(2)}')),
                          DataCell(Text(variant.stock?.toString() ?? '0')),
                          DataCell(
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(variant),
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
