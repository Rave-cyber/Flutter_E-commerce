<<<<<<< HEAD
=======
import 'package:firebase/views/admin/admin_stock_checker/form.dart';
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/stock_checker_model.dart';
import '/services/admin/stock_checker_service.dart';
<<<<<<< HEAD
import '/views/admin/admin_stock_checker/form.dart';
import '../../../widgets/stock_checker_search_widget.dart';
import '../../../widgets/stock_checker_filter_widget.dart';
import '../../../widgets/stock_checker_card_widget.dart';
import '../../../widgets/stock_checker_pagination_widget.dart';
import '../../../widgets/floating_action_button_widget.dart';
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

class AdminStockCheckersIndex extends StatefulWidget {
  const AdminStockCheckersIndex({Key? key}) : super(key: key);

  @override
  State<AdminStockCheckersIndex> createState() =>
      _AdminStockCheckersIndexState();
}

class _AdminStockCheckersIndexState extends State<AdminStockCheckersIndex> {
  final StockCheckerService _checkerService = StockCheckerService();
<<<<<<< HEAD

  final TextEditingController _searchController = TextEditingController();
=======
  final TextEditingController _searchController = TextEditingController();

>>>>>>> 3add35312551b90752a2c004e342857fcb126663
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

<<<<<<< HEAD
  int _getTotalPages(List<StockCheckerModel> checkers) {
    // Apply filters
    List<StockCheckerModel> filtered = checkers.where((c) {
      if (_filterStatus == 'active') return !c.is_archived;
      if (_filterStatus == 'archived') return c.is_archived;
      return true;
    }).toList();

    // Apply search
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where((c) =>
              c.firstname.toLowerCase().contains(query) ||
              c.middlename.toLowerCase().contains(query) ||
              c.lastname.toLowerCase().contains(query))
          .toList();
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
<<<<<<< HEAD
    if (_currentPage > 1) {
      setState(() => _currentPage--);
    }
  }

  Future<void> _handleMenuSelection(
      String value, StockCheckerModel checker) async {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminStockCheckerForm(checker: checker),
          ),
        );
        break;
      case 'archive':
      case 'unarchive':
        final action = checker.is_archived ? 'unarchive' : 'archive';
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Confirm $action'),
            content: Text(
              'Are you sure you want to $action "${checker.firstname} ${checker.lastname}"?',
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
          await _checkerService.toggleArchive(checker);
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
            content: Text(
              'Are you sure you want to delete "${checker.firstname} ${checker.lastname}"?',
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
          await _checkerService.deleteStockChecker(checker.id);
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
=======
    if (_currentPage > 1) setState(() => _currentPage--);
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
<<<<<<< HEAD
      selectedRoute: '/admin/stock-checkers',
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SEARCH FIELD
<<<<<<< HEAD
            StockCheckerSearchWidget(
              controller: _searchController,
              onChanged: () => setState(() {
                _currentPage = 1;
              }),
            ),
            const SizedBox(height: 16),

            // FILTER AND PER PAGE DROPDOWN
            StockCheckerFilterWidget(
              filterStatus: _filterStatus,
              itemsPerPage: _itemsPerPage,
              onFilterChanged: _onFilterChanged,
              onItemsPerPageChanged: _onItemsPerPageChanged,
            ),
            const SizedBox(height: 16),

            // STOCK CHECKER LIST WITH BOTTOM CONTROLS
=======
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
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
            Expanded(
              child: StreamBuilder<List<StockCheckerModel>>(
                stream: _checkerService.getStockCheckers(),
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
                              Icon(Icons.person_search_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No stock checkers found.',
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

                  final checkers = snapshot.data!;
                  final paginatedCheckers =
                      _applyFilterSearchPagination(checkers);
                  final totalPages = _getTotalPages(checkers);

                  return Column(
                    children: [
                      // STOCK CHECKER LIST
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedCheckers.length,
                          itemBuilder: (context, index) {
                            final checker = paginatedCheckers[index];

                            return StockCheckerCardWidget(
                              checker: checker,
                              onMenuSelected: (value) =>
                                  _handleMenuSelection(value, checker),
=======
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
                          StockCheckerPaginationWidget(
                            currentPage: _currentPage,
                            totalPages: totalPages,
                            onPreviousPage: _prevPage,
                            onNextPage: () => _nextPage(checkers.length),
                          ),

                          // ADD STOCK CHECKER BUTTON - Right end
                          FloatingActionButtonWidget(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminStockCheckerForm()),
                              );
                            },
                          ),
=======
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
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
<<<<<<< HEAD
=======

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
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
          ],
        ),
      ),
    );
  }
}
