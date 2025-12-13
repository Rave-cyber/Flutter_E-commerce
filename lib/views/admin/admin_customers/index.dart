import 'package:firebase/models/customer_model.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '../../../widgets/product_search_widget.dart';
import '../../../widgets/product_pagination_widget.dart';
import '../../../widgets/product_filter_widget.dart';

class AdminCustomersIndex extends StatefulWidget {
  const AdminCustomersIndex({Key? key}) : super(key: key);

  @override
  State<AdminCustomersIndex> createState() => _AdminCustomersIndexState();
}

class _AdminCustomersIndexState extends State<AdminCustomersIndex> {
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showArchived = false;

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  List<CustomerModel> _allCustomers = [];

  // Cache user archive statuses
  final Map<String, bool> _userArchiveStatus = {};

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
  }

  Future<void> loadUserArchiveStatuses() async {
    final userSnapshot = await _authService.firestore.collection('users').get();
    for (var doc in userSnapshot.docs) {
      _userArchiveStatus[doc.id] = doc.data()['is_archived'] ?? false;
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
      });
    }
  }

  void _onPreviousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Widget
            ProductSearchWidget(
              controller: _searchController,
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),

            // Filter Widget
            ProductFilterWidget(
              filterStatus: _showArchived ? 'archived' : 'active',
              itemsPerPage: _itemsPerPage,
              onFilterChanged: _onFilterChanged,
              onItemsPerPageChanged: _onItemsPerPageChanged,
            ),
            const SizedBox(height: 16),

            // Customer List
            Expanded(
              child: StreamBuilder<List<CustomerModel>>(
                stream: getCustomersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
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
                      ),
                    );
                  }

                  final customers = snapshot.data!;

                  return Column(
                    children: [
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
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Pagination Widget
                      ProductPaginationWidget(
                        currentPage: _currentPage,
                        onPreviousPage: _onPreviousPage,
                        onNextPage: _onNextPage,
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
