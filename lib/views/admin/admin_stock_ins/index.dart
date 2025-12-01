import 'package:firebase/views/admin/admin_stock_ins/form.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/stock_in_model.dart';
import '/services/admin/stock_in_service.dart';

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
            Expanded(
              child: StreamBuilder<List<StockInModel>>(
                stream: _stockInService.getStockIns(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No stock-in records found.'));
                  }

                  final stockInList = snapshot.data!;
                  final paginatedList =
                      _applyFilterSearchPagination(stockInList);

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
                                  color: Colors.blueGrey,
                                ),
                                title: Text(
                                  item.product_id ?? "No Product Assigned",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: item.is_archived
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  "Supplier ID: ${item.supplier_id}\n"
                                  "Warehouse ID: ${item.warehouse_id}\n"
                                  "Reason: ${item.reason}",
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                            onPressed: () => _nextPage(stockInList.length),
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
                      builder: (_) => const AdminStockInForm(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
                tooltip: 'Add Stock-In',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
