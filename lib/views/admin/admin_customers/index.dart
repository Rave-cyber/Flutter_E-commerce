import 'package:firebase/models/customer_model.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
<<<<<<< HEAD
import '../../../widgets/customer_search_widget.dart';
import '../../../widgets/product_pagination_widget.dart';
import '../../../widgets/product_filter_widget.dart';
import '../../../widgets/customer_card_widget.dart';
import '../../../widgets/customer_details_modal.dart';
=======
import '../../../widgets/product_search_widget.dart';
import '../../../widgets/product_pagination_widget.dart';
import '../../../widgets/product_filter_widget.dart';
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

class AdminCustomersIndex extends StatefulWidget {
  const AdminCustomersIndex({Key? key}) : super(key: key);

  @override
  State<AdminCustomersIndex> createState() => _AdminCustomersIndexState();
}

class _AdminCustomersIndexState extends State<AdminCustomersIndex> {
  final AuthService _authService = AuthService();
<<<<<<< HEAD

  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'active';
  int _itemsPerPage = 10;
  int _currentPage = 1;
=======
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showArchived = false;
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  List<CustomerModel> _allCustomers = [];

  // Cache user archive statuses
  final Map<String, bool> _userArchiveStatus = {};

<<<<<<< HEAD
  @override
  void initState() {
    super.initState();
    _loadUserArchiveStatuses();
=======
  Stream<List<CustomerModel>> getCustomersStream() {
    return _authService.firestore.collection('customers').snapshots().map(
      (snapshot) {
        List<CustomerModel> customers = [];

        for (var doc in snapshot.docs) {
          final customer = CustomerModel.fromMap(doc.data());

          final isArchived = _userArchiveStatus[customer.user_id] ?? false;

          if ((_showArchived && isArchived) ||
              (!_showArchived && !isArchived)) {
            if (_searchQuery.isEmpty ||
                '${customer.firstname} ${customer.middlename} ${customer.lastname}'
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase())) {
              customers.add(customer);
            }
          }
        }

        // Update pagination data
        _allCustomers = customers;
        _totalPages = (customers.length / _itemsPerPage).ceil();
        if (_totalPages == 0) _totalPages = 1;

        // Return paginated results
        final startIndex = (_currentPage - 1) * _itemsPerPage;
        final endIndex = startIndex + _itemsPerPage;

        if (startIndex >= customers.length) {
          _currentPage = 1;
        }

        return customers.sublist(
          startIndex,
          endIndex.clamp(0, customers.length),
        );
      },
    );
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
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

<<<<<<< HEAD
  void _onFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _filterStatus = value;
        _currentPage = 1;
=======
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _currentPage = 1; // Reset to first page when searching
    });
  }

  void _onFilterChanged(String? newFilter) {
    setState(() {
      _showArchived = newFilter == 'archived';
      _currentPage = 1;
    });
  }

  void _onItemsPerPageChanged(int? newItemsPerPage) {
    if (newItemsPerPage != null) {
      setState(() {
        _itemsPerPage = newItemsPerPage;
        _currentPage = 1; // Reset to first page when changing items per page
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
      });
    }
  }

<<<<<<< HEAD
  void _onItemsPerPageChanged(int? value) {
    if (value != null) {
      setState(() {
        _itemsPerPage = value;
        _currentPage = 1;
=======
  void _onPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
      });
    }
  }

<<<<<<< HEAD
  void _showCustomerDetailsModal(CustomerModel customer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomerDetailsModal(customer: customer);
      },
    );
=======
  void _onNextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadUserArchiveStatuses();
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedRoute: '/admin/customers',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
<<<<<<< HEAD
            // SEARCH FIELD
            CustomerSearchWidget(
              controller: _searchController,
              onChanged: () => setState(() {
                _currentPage = 1;
              }),
            ),
            const SizedBox(height: 16),

            // FILTER AND PER PAGE DROPDOWN
            ProductFilterWidget(
              filterStatus: _filterStatus,
=======
            // Search Widget
            ProductSearchWidget(
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),

            // Filter Widget
            ProductFilterWidget(
              filterStatus: _showArchived ? 'archived' : 'active',
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
              itemsPerPage: _itemsPerPage,
              onFilterChanged: _onFilterChanged,
              onItemsPerPageChanged: _onItemsPerPageChanged,
            ),
            const SizedBox(height: 16),

<<<<<<< HEAD
            // CUSTOMER LIST WITH BOTTOM CONTROLS
=======
            // Customer List
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
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
<<<<<<< HEAD
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
=======
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No customers found.',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                      ),
                    );
                  }

                  final customers = snapshot.data!;
                  final paginatedCustomers =
                      _applyFilterSearchPagination(customers);
                  final totalPages = _getTotalPages(customers);

                  return Column(
                    children: [
<<<<<<< HEAD
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
=======
                      Expanded(
                        child: ListView.builder(
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            final customer = customers[index];
                            final isArchived =
                                _userArchiveStatus[customer.user_id] ?? false;

                            return _buildCustomerCard(
                              customer: customer,
                              isArchived: isArchived,
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

<<<<<<< HEAD
                      // BOTTOM CONTROLS - Centered Pagination (removed Add button)
                      Center(
                        child: ProductPaginationWidget(
                          currentPage: _currentPage,
                          totalPages: totalPages,
                          onPreviousPage: _prevPage,
                          onNextPage: () => _nextPage(customers.length),
                        ),
=======
                      // Pagination Widget
                      ProductPaginationWidget(
                        currentPage: _currentPage,
                        onPreviousPage: _onPreviousPage,
                        onNextPage: _onNextPage,
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
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

  Widget _buildCustomerCard({
    required CustomerModel customer,
    required bool isArchived,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.green.shade200,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row with Avatar, Name, and Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Avatar - Elevated
                    Material(
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color:
                              isArchived ? Colors.grey[100] : Colors.green[50],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: isArchived
                                ? Colors.grey[400]
                                : Colors.green[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Customer Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Customer Name and Status
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${customer.firstname} ${customer.middlename} ${customer.lastname}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isArchived
                                        ? Colors.grey
                                        : Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Status Badge - Elevated
                              Material(
                                elevation: 2,
                                shadowColor: isArchived
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.green.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: isArchived
                                        ? Colors.red[100]
                                        : Colors.green[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isArchived ? 'Archived' : 'Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isArchived
                                          ? Colors.red[700]
                                          : Colors.green[700],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Contact Information
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                customer.contact,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  customer.address,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Archive/Unarchive Button - Elevated
                    Material(
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => toggleArchive(customer),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isArchived ? Icons.unarchive : Icons.archive,
                                color: isArchived
                                    ? Colors.orange[600]
                                    : Colors.red[600],
                                size: 20,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isArchived ? 'Unarchive' : 'Archive',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isArchived
                                      ? Colors.orange[600]
                                      : Colors.red[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.green.shade200,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Row with Customer Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Registration Date - Elevated
                    Material(
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.blue[600],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Registered',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Customer ID - Elevated
                    Material(
                      elevation: 3,
                      shadowColor: Colors.blue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: ${customer.user_id.substring(0, 8)}...',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
