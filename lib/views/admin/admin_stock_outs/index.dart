import 'package:firebase/views/admin/admin_stock_outs/form.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/stock_out_model.dart';
import '/services/admin/stock_out_service.dart';
import 'package:firebase/models/stock_in_out_model.dart';

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
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Stock-Out (Product, Variant, Reason)',
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
                    DropdownMenuItem(value: 'recent', child: Text('Recent')),
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

            // STOCK-OUT LIST
            Expanded(
              child: StreamBuilder<List<StockOutModel>>(
                stream: _stockOutService.getStockOuts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No stock-out records found.'));
                  }

                  final stockOutList = snapshot.data!;
                  final paginatedList =
                      _applyFilterSearchPagination(stockOutList);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedList.length,
                          itemBuilder: (context, index) {
                            final item = paginatedList[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.redAccent,
                                ),
                                title: Text(
                                  item.product_variant_id != null
                                      ? 'Variant: ${item.product_variant_id!.substring(0, 8).toUpperCase()}'
                                      : 'Product: ${item.product_id ?? "No Product Assigned"}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Quantity: ${item.quantity}\n'
                                  'Reason: ${item.reason}\n'
                                  'Date: ${item.created_at?.toString().substring(0, 19) ?? "N/A"}',
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    /// FIFO DETAILS
                                    IconButton(
                                      icon: const Icon(
                                        Icons.list_alt,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () => _showFIFODetails(item),
                                      tooltip: 'Show FIFO Deduction Details',
                                    ),

                                    /// EDIT
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AdminStockOutForm(
                                                stockOut: item),
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
                                                'Are you sure you want to delete this stock-out record?'),
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
                                          await _stockOutService
                                              .deleteStockOut(item.id);
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
                            onPressed: () => _nextPage(stockOutList.length),
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
                    MaterialPageRoute(
                      builder: (_) => const AdminStockOutForm(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
                tooltip: 'Add Stock-Out',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
