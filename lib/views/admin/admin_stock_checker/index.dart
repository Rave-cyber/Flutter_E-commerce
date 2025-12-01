import 'package:firebase/views/admin/admin_stock_checker/form.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/stock_checker_model.dart';
import '/services/admin/stock_checker_service.dart';

class AdminStockCheckersIndex extends StatefulWidget {
  const AdminStockCheckersIndex({Key? key}) : super(key: key);

  @override
  State<AdminStockCheckersIndex> createState() =>
      _AdminStockCheckersIndexState();
}

class _AdminStockCheckersIndexState extends State<AdminStockCheckersIndex> {
  final StockCheckerService _checkerService = StockCheckerService();
  final TextEditingController _searchController = TextEditingController();

  String _filterStatus = 'active';
  int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StockCheckerModel> _applyFilterSearchPagination(
      List<StockCheckerModel> checkers) {
    // FILTER
    List<StockCheckerModel> filtered = checkers.where((c) {
      if (_filterStatus == 'active') return !c.is_archived;
      if (_filterStatus == 'archived') return c.is_archived;
      return true;
    }).toList();

    // SEARCH (by firstname, middlename, lastname)
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((c) =>
              c.firstname.toLowerCase().contains(query) ||
              c.middlename.toLowerCase().contains(query) ||
              c.lastname.toLowerCase().contains(query))
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
    if (_currentPage > 1) setState(() => _currentPage--);
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
                labelText: 'Search Stock Checker',
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

            // STOCK CHECKER LIST
            Expanded(
              child: StreamBuilder<List<StockCheckerModel>>(
                stream: _checkerService.getStockCheckers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('No stock checkers found.'));
                  }

                  final checkers = snapshot.data!;
                  final paginated = _applyFilterSearchPagination(checkers);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginated.length,
                          itemBuilder: (context, index) {
                            final checker = paginated[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(
                                  "${checker.firstname} ${checker.middlename} ${checker.lastname}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: checker.is_archived
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Address: ${checker.address}"),
                                    Text("Contact: ${checker.contact}"),
                                    Text(checker.is_archived
                                        ? 'Archived'
                                        : 'Active'),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Archive / Unarchive
                                    IconButton(
                                      icon: Icon(
                                        checker.is_archived
                                            ? Icons.unarchive
                                            : Icons.archive,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () async {
                                        final action = checker.is_archived
                                            ? 'unarchive'
                                            : 'archive';
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('Confirm $action'),
                                            content: Text(
                                                'Are you sure you want to $action "${checker.firstname} ${checker.lastname}"?'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Cancel')),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: Text(
                                                      action[0].toUpperCase() +
                                                          action.substring(1))),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _checkerService
                                              .toggleArchive(checker);
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
                                            builder: (_) =>
                                                AdminStockCheckerForm(
                                                    checker: checker),
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
                                                'Are you sure you want to delete "${checker.firstname} ${checker.lastname}"?'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Cancel')),
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Delete')),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _checkerService
                                              .deleteStockChecker(checker.id);
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

                      // PAGINATION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: _prevPage),
                          Text('Page $_currentPage'),
                          IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () => _nextPage(checkers.length)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // ADD BUTTON
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminStockCheckerForm()),
                  );
                },
                child: const Icon(Icons.add),
                tooltip: 'Add Stock Checker',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
