import 'package:firebase/views/admin/admin_stock_ins/form.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/stock_in_model.dart';
import '/services/admin/stock_in_service.dart';
<<<<<<< HEAD
import '../../../widgets/stock_search_widget.dart';
import '../../../widgets/stock_filter_widget.dart';
import '../../../widgets/stock_in_card_widget.dart';
import '../../../widgets/stock_pagination_widget.dart';
import '../../../widgets/floating_action_button_widget.dart';
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

class AdminStockInIndex extends StatefulWidget {
  const AdminStockInIndex({Key? key}) : super(key: key);

  @override
  State<AdminStockInIndex> createState() => _AdminStockInIndexState();
}

class _AdminStockInIndexState extends State<AdminStockInIndex> {
  final StockInService _stockInService = StockInService();
  final TextEditingController _searchController = TextEditingController();

  String _filterStatus = 'active';
  int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StockInModel> _applyFilterSearchPagination(List<StockInModel> list) {
    // FILTER
    List<StockInModel> filtered = list.where((item) {
      if (_filterStatus == 'active') return !item.is_archived;
      if (_filterStatus == 'archived') return item.is_archived;
      return true;
    }).toList();

    // SEARCH (by product name, supplier, or reference number)
    if (_searchController.text.isNotEmpty) {
      final text = _searchController.text.toLowerCase();
      filtered = filtered.where((item) {
        return (item.product_id?.toLowerCase().contains(text) ?? false) ||
            (item.product_variant_id?.toLowerCase().contains(text) ?? false) ||
            (item.supplier_id.toLowerCase().contains(text)) ||
            (item.warehouse_id.toLowerCase().contains(text)) ||
            (item.stock_checker_id.toLowerCase().contains(text)) ||
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

<<<<<<< HEAD
  int _getTotalPages(List<StockInModel> list) {
    // Apply filters
    List<StockInModel> filtered = list.where((item) {
      if (_filterStatus == 'active') return !item.is_archived;
      if (_filterStatus == 'archived') return item.is_archived;
      return true;
    }).toList();

    // Apply search
    if (_searchController.text.isNotEmpty) {
      final text = _searchController.text.toLowerCase();
      filtered = filtered.where((item) {
        return (item.product_id?.toLowerCase().contains(text) ?? false) ||
            (item.product_variant_id?.toLowerCase().contains(text) ?? false) ||
            (item.supplier_id.toLowerCase().contains(text)) ||
            (item.warehouse_id.toLowerCase().contains(text)) ||
            (item.stock_checker_id.toLowerCase().contains(text)) ||
            (item.reason.toLowerCase().contains(text));
      }).toList();
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
  Future<void> _handleMenuSelection(String value, StockInModel stockIn) async {
    switch (value) {
      case 'details':
        _showBatchDetails(stockIn);
        break;
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminStockInForm(stockIn: stockIn),
          ),
        );
        break;
      case 'archive':
      case 'unarchive':
        final action = stockIn.is_archived ? 'unarchive' : 'archive';
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Confirm $action'),
            content: Text(
              'Are you sure you want to $action this stock-in record?',
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
          await _stockInService.toggleArchive(stockIn);
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
            content: const Text(
              'Are you sure you want to delete this stock-in record?',
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
          await _stockInService.deleteStockIn(stockIn.id);
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

=======
  /// Show detailed FIFO batch information in a dialog
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
  void _showBatchDetails(StockInModel stockIn) async {
    final deductedQuantity = stockIn.quantity - stockIn.remaining_quantity;
    final isDepleted = stockIn.remaining_quantity == 0;

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Batch ${stockIn.id.substring(0, 8).toUpperCase()}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product: ${stockIn.product_variant_id != null ? "Variant: ${stockIn.product_variant_id!.substring(0, 8).toUpperCase()}" : "Main: ${stockIn.product_id ?? "No Product"}"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Quantity: ${stockIn.quantity} units',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Remaining: ${stockIn.remaining_quantity} units',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: stockIn.remaining_quantity == 0
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
                Text(
                  'Deducted: $deductedQuantity units',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: stockIn.remaining_quantity / stockIn.quantity,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDepleted ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'FIFO Status: ${isDepleted ? "Depleted (Used in Stock-Out)" : "${((stockIn.remaining_quantity / stockIn.quantity) * 100).toInt()}% Remaining"}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDepleted ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Date Created: ${stockIn.created_at?.toString().substring(0, 19) ?? "N/A"}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  'Price: \$${stockIn.price.toStringAsFixed(2)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
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
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
<<<<<<< HEAD
      selectedRoute: '/admin/stock-ins',
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SEARCH FIELD
<<<<<<< HEAD
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

            // STOCK-IN LIST WITH BOTTOM CONTROLS
=======
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Stock-In (Product, Supplier, Reference No.)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _currentPage = 1),
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

            // STOCK-IN LIST
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
            Expanded(
              child: StreamBuilder<List<StockInModel>>(
                stream: _stockInService.getStockIns(),
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
                              Icon(Icons.inventory_2_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No stock-in records found.',
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
                    return const Center(
                        child: Text('No stock-in records found.'));
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                  }

                  final stockInList = snapshot.data!;
                  final paginatedList =
                      _applyFilterSearchPagination(stockInList);
<<<<<<< HEAD
                  final totalPages = _getTotalPages(stockInList);

                  return Column(
                    children: [
                      // STOCK-IN LIST
=======

                  return Column(
                    children: [
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedList.length,
                          itemBuilder: (context, index) {
<<<<<<< HEAD
                            final stockIn = paginatedList[index];

                            return StockInCardWidget(
                              stockIn: stockIn,
                              onMenuSelected: (value) =>
                                  _handleMenuSelection(value, stockIn),
                              onTap: () => _showBatchDetails(stockIn),
=======
                            final item = paginatedList[index];
                            final deductedQuantity =
                                item.quantity - item.remaining_quantity;
                            final isDepleted = item.remaining_quantity == 0;
                            final remainingPercentage =
                                (item.remaining_quantity / item.quantity * 100)
                                    .round();

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDepleted
                                        ? Colors.red.withOpacity(0.2)
                                        : Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDepleted
                                          ? Colors.red
                                          : Colors.green,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    isDepleted
                                        ? Icons.close
                                        : Icons.check_circle,
                                    color:
                                        isDepleted ? Colors.red : Colors.green,
                                    size: 24,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.product_variant_id != null
                                            ? 'Variant: ${item.product_variant_id!.substring(0, 8).toUpperCase()}'
                                            : 'Product: ${item.product_id ?? "No Product Assigned"}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: item.is_archived
                                              ? Colors.grey
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isDepleted
                                            ? Colors.red
                                            : Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$remainingPercentage%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.created_at
                                                  ?.toString()
                                                  .substring(0, 10) ??
                                              "N/A",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Batch: ${item.id.substring(0, 8).toUpperCase()}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Total: ${item.quantity} units',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                'Remaining: ${item.remaining_quantity} units',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: isDepleted
                                                      ? Colors.red
                                                      : Colors.green,
                                                ),
                                              ),
                                              Text(
                                                'Deducted: $deductedQuantity units',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.orange,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(
                                          width: 100,
                                          child: LinearProgressIndicator(
                                            value: item.remaining_quantity /
                                                item.quantity,
                                            backgroundColor: Colors.grey[300],
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              isDepleted
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Reason: ${item.reason}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                onTap: () => _showBatchDetails(item),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    /// BATCH DETAILS
                                    IconButton(
                                      icon: const Icon(
                                        Icons.info_outline,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _showBatchDetails(item),
                                      tooltip: 'View FIFO Batch Details',
                                    ),

                                    /// ARCHIVE / UNARCHIVE
                                    IconButton(
                                      icon: Icon(
                                        item.is_archived
                                            ? Icons.unarchive
                                            : Icons.archive,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () async {
                                        final action = item.is_archived
                                            ? 'unarchive'
                                            : 'archive';
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('Confirm $action'),
                                            content: Text(
                                                'Are you sure you want to $action this stock-in record?'),
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
                                          await _stockInService
                                              .toggleArchive(item);
                                        }
                                      },
                                    ),

                                    /// EDIT
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AdminStockInForm(stockIn: item),
                                          ),
                                        );
                                      },
                                    ),

                                    /// DELETE
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Confirm Delete'),
                                            content: const Text(
                                                'Are you sure you want to delete this stock-in record?'),
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
                                          await _stockInService
                                              .deleteStockIn(item.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
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
                          StockPaginationWidget(
                            currentPage: _currentPage,
                            totalPages: totalPages,
                            onPreviousPage: _prevPage,
                            onNextPage: () => _nextPage(stockInList.length),
                          ),

                          // ADD STOCK-IN BUTTON - Right end
                          FloatingActionButtonWidget(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminStockInForm()),
                              );
                            },
                            tooltip: 'Add Stock-In',
=======
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
                            onPressed: () => _nextPage(stockInList.length),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
<<<<<<< HEAD
=======

            // FLOATING BUTTON
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminStockInForm(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
                tooltip: 'Add Stock-In',
              ),
            ),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
          ],
        ),
      ),
    );
  }
}
