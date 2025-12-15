<<<<<<< HEAD
=======
import 'package:firebase/views/admin/admin_suppliers/form.dart';
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/supplier_model.dart';
import '/services/admin/supplier_service.dart';
<<<<<<< HEAD
import '/views/admin/admin_suppliers/form.dart';
import '../../../widgets/supplier_search_widget.dart';
import '../../../widgets/supplier_filter_widget.dart';
import '../../../widgets/supplier_card';
import '../../../widgets/supplier_pagination_widget.dart';
import '../../../widgets/floating_action_button_widget.dart';
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

class AdminSuppliersIndex extends StatefulWidget {
  const AdminSuppliersIndex({Key? key}) : super(key: key);

  @override
  State<AdminSuppliersIndex> createState() => _AdminSuppliersIndexState();
}

class _AdminSuppliersIndexState extends State<AdminSuppliersIndex> {
  final SupplierService _supplierService = SupplierService();
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

  List<SupplierModel> _applyFilterSearchPagination(
      List<SupplierModel> suppliers) {
    // FILTER
    List<SupplierModel> filtered = suppliers.where((s) {
      if (_filterStatus == 'active') return !s.is_archived;
      if (_filterStatus == 'archived') return s.is_archived;
      return true;
    }).toList();

<<<<<<< HEAD
    // SEARCH
=======
    // SEARCH (by supplier name)
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((s) => s.name
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
  int _getTotalPages(List<SupplierModel> suppliers) {
    // Apply filters
    List<SupplierModel> filtered = suppliers.where((s) {
      if (_filterStatus == 'active') return !s.is_archived;
      if (_filterStatus == 'archived') return s.is_archived;
      return true;
    }).toList();

    // Apply search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((s) => s.name
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
      String value, SupplierModel supplier) async {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminSupplierForm(supplier: supplier),
          ),
        );
        break;
      case 'archive':
      case 'unarchive':
        final action = supplier.is_archived ? 'unarchive' : 'archive';
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Confirm $action'),
            content: Text(
              'Are you sure you want to $action "${supplier.name}"?',
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
          await _supplierService.toggleArchive(supplier);
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
              'Are you sure you want to delete "${supplier.name}"?',
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
          await _supplierService.deleteSupplier(supplier.id);
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
      selectedRoute: '/admin/suppliers',
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
            SupplierSearchWidget(
              controller: _searchController,
              onChanged: () => setState(() {
                _currentPage = 1;
              }),
            ),
            const SizedBox(height: 16),

            // FILTER AND PER PAGE DROPDOWN
            SupplierFilterWidget(
              filterStatus: _filterStatus,
              itemsPerPage: _itemsPerPage,
              onFilterChanged: _onFilterChanged,
              onItemsPerPageChanged: _onItemsPerPageChanged,
            ),
            const SizedBox(height: 16),

            // SUPPLIER LIST WITH BOTTOM CONTROLS
=======
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Supplier',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {
                _currentPage = 1;
              }),
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

            // SUPPLIER LIST
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
            Expanded(
              child: StreamBuilder<List<SupplierModel>>(
                stream: _supplierService.getSuppliers(),
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
                              Icon(Icons.business_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No suppliers found.',
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

                  final suppliers = snapshot.data!;
                  final paginatedSuppliers =
                      _applyFilterSearchPagination(suppliers);
                  final totalPages = _getTotalPages(suppliers);

                  return Column(
                    children: [
                      // SUPPLIER LIST
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedSuppliers.length,
                          itemBuilder: (context, index) {
                            final supplier = paginatedSuppliers[index];

                            return SupplierCardWidget(
                              supplier: supplier,
                              onMenuSelected: (value) =>
                                  _handleMenuSelection(value, supplier),
=======
                    return const Center(child: Text('No suppliers found.'));
                  }

                  final suppliers = snapshot.data!;
                  final paginated = _applyFilterSearchPagination(suppliers);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginated.length,
                          itemBuilder: (context, index) {
                            final supplier = paginated[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(
                                  supplier.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: supplier.is_archived
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Address: ${supplier.address}"),
                                    Text("Contact: ${supplier.contact}"),
                                    Text(
                                        "Contact Person: ${supplier.contact_person}"),
                                    Text(supplier.is_archived
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
                                        supplier.is_archived
                                            ? Icons.unarchive
                                            : Icons.archive,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () async {
                                        final action = supplier.is_archived
                                            ? 'unarchive'
                                            : 'archive';
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('Confirm $action'),
                                            content: Text(
                                                'Are you sure you want to $action "${supplier.name}"?'),
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
                                          await _supplierService
                                              .toggleArchive(supplier);
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
                                            builder: (_) => AdminSupplierForm(
                                                supplier: supplier),
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
                                                'Are you sure you want to delete "${supplier.name}"?'),
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
                                          await _supplierService
                                              .deleteSupplier(supplier.id);
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
                          SupplierPaginationWidget(
                            currentPage: _currentPage,
                            totalPages: totalPages,
                            onPreviousPage: _prevPage,
                            onNextPage: () => _nextPage(suppliers.length),
                          ),

                          // ADD SUPPLIER BUTTON - Right end
                          FloatingActionButtonWidget(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminSupplierForm()),
                              );
                            },
=======
                      // PAGINATION
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
                            onPressed: () => _nextPage(suppliers.length),
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
                      builder: (_) => const AdminSupplierForm(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
                tooltip: 'Add Supplier',
              ),
            ),
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
          ],
        ),
      ),
    );
  }
}
