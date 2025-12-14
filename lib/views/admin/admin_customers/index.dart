import 'package:firebase/models/customer_model.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '../../../widgets/product_search_widget.dart';
import '../../../widgets/product_pagination_widget.dart';
import '../../../widgets/product_filter_widget.dart';
import '../../../widgets/customer_card_widget.dart';
import '../../../widgets/floating_action_button_widget.dart';
import '../../../widgets/customer_details_modal.dart';

class AdminCustomersIndex extends StatefulWidget {
  const AdminCustomersIndex({Key? key}) : super(key: key);

  @override
  State<AdminCustomersIndex> createState() => _AdminCustomersIndexState();
}

class _AdminCustomersIndexState extends State<AdminCustomersIndex> {
  final AuthService _authService = AuthService();

  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'active';
  int _itemsPerPage = 10;
  int _currentPage = 1;

  // Cache user archive statuses
  final Map<String, bool> _userArchiveStatus = {};

  @override
  void initState() {
    super.initState();
    _loadUserArchiveStatuses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserArchiveStatuses() async {
    final userSnapshot = await _authService.firestore.collection('users').get();
    for (var doc in userSnapshot.docs) {
      _userArchiveStatus[doc.id] = doc.data()['is_archived'] ?? false;
    }
    setState(() {}); // Trigger rebuild to update the UI
  }

  List<CustomerModel> _applyFilterSearchPagination(
      List<CustomerModel> customers) {
    // FILTER - Apply active/archived filter like products
    List<CustomerModel> filtered = customers.where((customer) {
      final isArchived = _userArchiveStatus[customer.user_id] ?? false;
      if (_filterStatus == 'active') return !isArchived;
      if (_filterStatus == 'archived') return isArchived;
      return true;
    }).toList();

    // SEARCH
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((customer) =>
              '${customer.firstname} ${customer.middlename} ${customer.lastname}'
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

  int _getTotalPages(List<CustomerModel> customers) {
    // Apply filters like products
    List<CustomerModel> filtered = customers.where((customer) {
      final isArchived = _userArchiveStatus[customer.user_id] ?? false;
      if (_filterStatus == 'active') return !isArchived;
      if (_filterStatus == 'archived') return isArchived;
      return true;
    }).toList();

    // Apply search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((customer) =>
              '${customer.firstname} ${customer.middlename} ${customer.lastname}'
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
      String value, CustomerModel customer) async {
    switch (value) {
      case 'view':
        _showCustomerDetailsModal(customer);
        break;
      case 'edit':
        // TODO: Navigate to edit form
        break;
      case 'archive':
      case 'unarchive':
        final action = _userArchiveStatus[customer.user_id] ?? false
            ? 'unarchive'
            : 'archive';
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Confirm $action'),
            content: Text(
              'Are you sure you want to $action "${customer.firstname} ${customer.lastname}"?',
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
          await toggleArchive(customer);
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
              'Are you sure you want to delete "${customer.firstname} ${customer.lastname}"?',
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
          // TODO: Implement delete customer functionality
        }
        break;
    }
  }

  Future<void> toggleArchive(CustomerModel customer) async {
    final currentStatus = _userArchiveStatus[customer.user_id] ?? false;

    await _authService.firestore
        .collection('users')
        .doc(customer.user_id)
        .update({'is_archived': !currentStatus});

    setState(() {
      _userArchiveStatus[customer.user_id] = !currentStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Customer ${!currentStatus ? 'archived' : 'unarchived'} successfully'),
        backgroundColor: Colors.green,
      ),
    );
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

  void _showCustomerDetailsModal(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomerDetailsModal(customer: customer);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SEARCH FIELD
            ProductSearchWidget(
              controller: _searchController,
              onChanged: () => setState(() {
                _currentPage = 1;
              }),
            ),
            const SizedBox(height: 16),

            // FILTER AND PER PAGE DROPDOWN
            ProductFilterWidget(
              filterStatus: _filterStatus,
              itemsPerPage: _itemsPerPage,
              onFilterChanged: _onFilterChanged,
              onItemsPerPageChanged: _onItemsPerPageChanged,
            ),
            const SizedBox(height: 16),

            // CUSTOMER LIST WITH BOTTOM CONTROLS
            Expanded(
              child: StreamBuilder<List<CustomerModel>>(
                stream: _authService.firestore
                    .collection('customers')
                    .snapshots()
                    .map(
                  (snapshot) {
                    List<CustomerModel> customers = [];
                    for (var doc in snapshot.docs) {
                      final customer = CustomerModel.fromMap(doc.data());
                      customers.add(customer);
                    }
                    return customers;
                  },
                ),
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
                              Icon(Icons.people_outline,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No customers found.',
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

                  final customers = snapshot.data!;
                  final paginatedCustomers =
                      _applyFilterSearchPagination(customers);
                  final totalPages = _getTotalPages(customers);

                  return Column(
                    children: [
                      // CUSTOMER LIST
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = paginatedCustomers[index];
                            final isArchived =
                                _userArchiveStatus[customer.user_id] ?? false;

                            return CustomerCardWidget(
                              customer: customer,
                              isArchived: isArchived,
                              onMenuSelected: (value) =>
                                  _handleMenuSelection(value, customer),
                              onTap: () => _showCustomerDetailsModal(customer),
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
                          ProductPaginationWidget(
                            currentPage: _currentPage,
                            totalPages: totalPages,
                            onPreviousPage: _prevPage,
                            onNextPage: () => _nextPage(customers.length),
                          ),

                          // ADD CUSTOMER BUTTON - Right end
                          FloatingActionButtonWidget(
                            onPressed: () {
                              // TODO: Navigate to add customer form
                            },
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
