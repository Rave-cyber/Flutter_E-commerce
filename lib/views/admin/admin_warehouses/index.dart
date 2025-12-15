import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/warehouse_model.dart';
import '/services/admin/warehouse_service.dart';
import '/views/admin/admin_warehouses/form.dart';
<<<<<<< HEAD
import '../../../widgets/warehouse_search_widget.dart';
import '../../../widgets/warehouse_filter_widget.dart';
import '../../../widgets/warehouse_card_widget.dart';
import '../../../widgets/warehouse_pagination_widget.dart';
import '../../../widgets/floating_action_button_widget.dart';
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

class AdminWarehousesIndex extends StatefulWidget {
  const AdminWarehousesIndex({Key? key}) : super(key: key);

  @override
  State<AdminWarehousesIndex> createState() => _AdminWarehousesIndexState();
}

class _AdminWarehousesIndexState extends State<AdminWarehousesIndex> {
  final WarehouseService _warehouseService = WarehouseService();
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

  List<WarehouseModel> _applyFilterSearchPagination(
      List<WarehouseModel> warehouses) {
    // FILTER
    List<WarehouseModel> filtered = warehouses.where((w) {
      if (_filterStatus == 'active') return !w.is_archived;
      if (_filterStatus == 'archived') return w.is_archived;
      return true;
    }).toList();

    // SEARCH
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((w) => w.name
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

<<<<<<< HEAD
  int _getTotalPages(List<WarehouseModel> warehouses) {
    // Apply filters
    List<WarehouseModel> filtered = warehouses.where((w) {
      if (_filterStatus == 'active') return !w.is_archived;
      if (_filterStatus == 'archived') return w.is_archived;
      return true;
    }).toList();

    // Apply search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((w) => w.name
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
  Future<void> _handleMenuSelection(
      String value, WarehouseModel warehouse) async {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminWarehouseForm(warehouse: warehouse),
          ),
        );
        break;
      case 'archive':
      case 'unarchive':
        final action = warehouse.is_archived ? 'unarchive' : 'archive';
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Confirm $action'),
            content: Text(
              'Are you sure you want to $action "${warehouse.name}"?',
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
          await _warehouseService.toggleArchive(warehouse);
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
              'Are you sure you want to delete "${warehouse.name}"?',
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
          await _warehouseService.deleteWarehouse(warehouse.id);
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

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedRoute: '/admin/warehouses',
=======
  @override
  Widget build(BuildContext context) {
    return AdminLayout(
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SEARCH FIELD
<<<<<<< HEAD
            WarehouseSearchWidget(
              controller: _searchController,
              onChanged: () => setState(() {
                _currentPage = 1;
              }),
            ),
            const SizedBox(height: 16),

            // FILTER AND PER PAGE DROPDOWN
            WarehouseFilterWidget(
              filterStatus: _filterStatus,
              itemsPerPage: _itemsPerPage,
              onFilterChanged: _onFilterChanged,
              onItemsPerPageChanged: _onItemsPerPageChanged,
            ),
            const SizedBox(height: 16),

            // WAREHOUSE LIST WITH BOTTOM CONTROLS
=======
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Warehouses',
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

            // WAREHOUSE LIST
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
            Expanded(
              child: StreamBuilder<List<WarehouseModel>>(
                stream: _warehouseService.getWarehouses(),
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
                              Icon(Icons.warehouse_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No warehouses found.',
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
                    return const Center(child: Text('No warehouses found.'));
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                  }

                  final warehouses = snapshot.data!;
                  final paginatedWarehouses =
                      _applyFilterSearchPagination(warehouses);
<<<<<<< HEAD
                  final totalPages = _getTotalPages(warehouses);

                  return Column(
                    children: [
                      // WAREHOUSE LIST
=======

                  return Column(
                    children: [
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedWarehouses.length,
                          itemBuilder: (context, index) {
                            final warehouse = paginatedWarehouses[index];
<<<<<<< HEAD

                            return WarehouseCardWidget(
                              warehouse: warehouse,
                              onMenuSelected: (value) =>
                                  _handleMenuSelection(value, warehouse),
=======
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(
                                  warehouse.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: warehouse.is_archived
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Text(warehouse.is_archived
                                    ? 'Archived'
                                    : 'Active'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ARCHIVE / UNARCHIVE
                                    IconButton(
                                      icon: Icon(
                                        warehouse.is_archived
                                            ? Icons.unarchive
                                            : Icons.archive,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () async {
                                        final action = warehouse.is_archived
                                            ? 'unarchive'
                                            : 'archive';
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('Confirm $action'),
                                            content: Text(
                                              'Are you sure you want to $action "${warehouse.name}"?',
                                            ),
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
                                                      action.substring(1),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _warehouseService
                                              .toggleArchive(warehouse);
                                        }
                                      },
                                    ),

                                    // EDIT
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AdminWarehouseForm(
                                              warehouse: warehouse,
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                    // DELETE
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text('Confirm Delete'),
                                            content: Text(
                                                'Delete warehouse "${warehouse.name}"?'),
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
                                          await _warehouseService
                                              .deleteWarehouse(warehouse.id);
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
                          WarehousePaginationWidget(
                            currentPage: _currentPage,
                            totalPages: totalPages,
                            onPreviousPage: _prevPage,
                            onNextPage: () => _nextPage(warehouses.length),
                          ),

                          // ADD WAREHOUSE BUTTON - Right end
                          FloatingActionButtonWidget(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminWarehouseForm()),
                              );
                            },
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
                            onPressed: () => _nextPage(warehouses.length),
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

            // ADD BUTTON
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminWarehouseForm(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
                tooltip: 'Add Warehouse',
              ),
            ),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
          ],
        ),
      ),
    );
  }
}
