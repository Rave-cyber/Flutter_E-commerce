import 'package:firebase/views/admin/admin_stock_outs/form.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/stock_out_model.dart';
import '/services/admin/stock_out_service.dart';
import 'package:firebase/models/stock_in_out_model.dart';
import '../../../widgets/stock_search_widget.dart';
import '../../../widgets/stock_filter_widget.dart';
import '../../../widgets/stock_out_card_widget.dart';
import '../../../widgets/stock_pagination_widget.dart';
import '../../../widgets/floating_action_button_widget.dart';

class AdminStockOutIndex extends StatefulWidget {
  const AdminStockOutIndex({Key? key}) : super(key: key);

  @override
  State<AdminStockOutIndex> createState() => _AdminStockOutIndexState();
}

class _AdminStockOutIndexState extends State<AdminStockOutIndex> {
  final StockOutService _stockOutService = StockOutService();
  final TextEditingController _searchController = TextEditingController();

  String _filterStatus = 'all';
  int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StockOutModel> _applyFilterSearchPagination(List<StockOutModel> list) {
    // FILTER
    List<StockOutModel> filtered = list;

    // SEARCH (by product name, variant, or reason)
    if (_searchController.text.isNotEmpty) {
      final text = _searchController.text.toLowerCase();
      filtered = filtered.where((item) {
        return (item.product_id?.toLowerCase().contains(text) ?? false) ||
            (item.product_variant_id?.toLowerCase().contains(text) ?? false) ||
            (item.reason.toLowerCase().contains(text));
      }).toList();
    }

    // PAGINATION
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    if (start >= filtered.length) return [];
    return filtered.sublist(
        start, end > filtered.length ? filtered.length : end);
  }

  int _getTotalPages(List<StockOutModel> list) {
    // Apply filters (currently no specific filters for stock-outs)
    List<StockOutModel> filtered = list;

    // Apply search
    if (_searchController.text.isNotEmpty) {
      final text = _searchController.text.toLowerCase();
      filtered = filtered.where((item) {
        return (item.product_id?.toLowerCase().contains(text) ?? false) ||
            (item.product_variant_id?.toLowerCase().contains(text) ?? false) ||
            (item.reason.toLowerCase().contains(text));
      }).toList();
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
    if (_currentPage > 1) {
      setState(() => _currentPage--);
    }
  }

  Future<void> _handleMenuSelection(
      String value, StockOutModel stockOut) async {
    switch (value) {
      case 'fifo_details':
        _showFIFODetails(stockOut);
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminStockOutForm(stockOut: stockOut),
          ),
        );
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Confirm Delete'),
            content: const Text(
              'Are you sure you want to delete this stock-out record?',
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
          await _stockOutService.deleteStockOut(stockOut.id);
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

  /// Show FIFO deduction details in a dialog
  void _showFIFODetails(StockOutModel stockOut) async {
    try {
      final stockInOutRecords =
          await _stockOutService.getStockInOutRecords(stockOut.id);

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title:
                Text('Stock-Out ${stockOut.id.substring(0, 8).toUpperCase()}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Deduction: ${stockOut.quantity} units',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'FIFO Deductions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (stockInOutRecords.isEmpty) ...[
                    const Text('No deductions recorded'),
                  ] else ...[
                    ...stockInOutRecords.map((record) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock-In: ${record.stock_in_id.substring(0, 8).toUpperCase()}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text('Deducted: ${record.deducted_quantity} units'),
                            Text(
                              'Date: ${record.created_at.toString().substring(0, 19)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading FIFO details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            StockSearchWidget(
              controller: _searchController,
              onChanged: () => setState(() {
                _currentPage = 1;
              }),
            ),
            const SizedBox(height: 16),

            // FILTER AND PER PAGE DROPDOWN
            StockFilterWidget(
              filterStatus: _filterStatus,
              itemsPerPage: _itemsPerPage,
              onFilterChanged: _onFilterChanged,
              onItemsPerPageChanged: _onItemsPerPageChanged,
            ),
            const SizedBox(height: 16),

            // STOCK-OUT LIST WITH BOTTOM CONTROLS
            Expanded(
              child: StreamBuilder<List<StockOutModel>>(
                stream: _stockOutService.getStockOuts(),
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
                                'No stock-out records found.',
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

                  final stockOutList = snapshot.data!;
                  final paginatedList =
                      _applyFilterSearchPagination(stockOutList);
                  final totalPages = _getTotalPages(stockOutList);

                  return Column(
                    children: [
                      // STOCK-OUT LIST
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedList.length,
                          itemBuilder: (context, index) {
                            final stockOut = paginatedList[index];

                            return StockOutCardWidget(
                              stockOut: stockOut,
                              onMenuSelected: (value) =>
                                  _handleMenuSelection(value, stockOut),
                              onTap: () => _showFIFODetails(stockOut),
                              onViewFifoDetails: () =>
                                  _showFIFODetails(stockOut),
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
                          StockPaginationWidget(
                            currentPage: _currentPage,
                            totalPages: totalPages,
                            onPreviousPage: _prevPage,
                            onNextPage: () => _nextPage(stockOutList.length),
                          ),

                          // ADD STOCK-OUT BUTTON - Right end
                          FloatingActionButtonWidget(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminStockOutForm()),
                              );
                            },
                            tooltip: 'Add Stock-Out',
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
