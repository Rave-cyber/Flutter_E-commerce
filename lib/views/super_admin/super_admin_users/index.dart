import 'package:flutter/material.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../layouts/super_admin_layout.dart';
import 'form.dart';
import '../../../widgets/product_search_widget.dart';
import '../../../widgets/product_filter_widget.dart';
import '../../../widgets/product_pagination_widget.dart';
import '../../../widgets/floating_action_button_widget.dart';

class SuperAdminUsersScreen extends StatefulWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  State<SuperAdminUsersScreen> createState() => _SuperAdminUsersScreenState();
}

class _SuperAdminUsersScreenState extends State<SuperAdminUsersScreen> {
  final AuthService _authService = AuthService();

  final TextEditingController _searchController = TextEditingController();
  String _roleFilter = 'all'; // all, admin, delivery_staff, customer
  int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String? value) {
    if (value != null) {
      setState(() {
        _roleFilter = value;
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
    return SuperAdminLayout(
      title: 'Users Management',
      selectedRoute: '/super-admin/users',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
            // We use ProductFilterWidget but adapt it for our roles
            Material(
              elevation: 3,
              shadowColor: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _roleFilter,
                          items: const [
                            DropdownMenuItem(
                                value: 'all', child: Text('All Roles')),
                            DropdownMenuItem(
                                value: 'admin', child: Text('Admins')),
                            DropdownMenuItem(
                                value: 'delivery_staff',
                                child: Text('Delivery Staff')),
                            DropdownMenuItem(
                                value: 'customer', child: Text('Customers')),
                          ],
                          onChanged: _onFilterChanged,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _itemsPerPage,
                          items: const [
                            DropdownMenuItem(value: 10, child: Text('10')),
                            DropdownMenuItem(value: 25, child: Text('25')),
                            DropdownMenuItem(value: 50, child: Text('50')),
                            DropdownMenuItem(value: 100, child: Text('100')),
                          ],
                          onChanged: _onItemsPerPageChanged,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // USERS LIST
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // We are querying the 'users' collection
                stream: _authService.firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                                'No users found.',
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

                  // 1. Convert to List
                  var users = snapshot.data!.docs
                      .map((doc) =>
                          UserModel.fromMap(doc.data() as Map<String, dynamic>))
                      .toList();

                  // 2. Filter by role
                  if (_roleFilter != 'all') {
                    users = users.where((u) => u.role == _roleFilter).toList();
                  }

                  // 3. Filter by search (email or display name)
                  if (_searchController.text.isNotEmpty) {
                    final query = _searchController.text.toLowerCase();
                    users = users.where((u) {
                      final email = u.email.toLowerCase();
                      final name = (u.display_name ?? '').toLowerCase();
                      return email.contains(query) || name.contains(query);
                    }).toList();
                  }

                  // 4. Pagination Logic
                  final start = (_currentPage - 1) * _itemsPerPage;
                  final end = start + _itemsPerPage;
                  final paginatedUsers = (start >= users.length)
                      ? <UserModel>[]
                      : users.sublist(
                          start, end > users.length ? users.length : end);

                  if (paginatedUsers.isEmpty && users.isNotEmpty) {
                    // Reset to page 1 if current page is empty but results exist
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _currentPage = 1);
                    });
                  }

                  if (users.isEmpty) {
                    return Center(
                      child: Text('No matching users found',
                          style: TextStyle(color: Colors.grey[500])),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedUsers.length,
                          itemBuilder: (context, index) {
                            final user = paginatedUsers[index];
                            return _buildUserCard(user);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // PAGINATION CONTROLS
                      ProductPaginationWidget(
                        currentPage: _currentPage,
                        onPreviousPage: _prevPage,
                        onNextPage: () => _nextPage(users.length),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // FLOATING BUTTON
            FloatingActionButtonWidget(
              tooltip: 'Add User',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SuperAdminUsersForm()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
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
            child: Row(
              children: [
                // User Avatar
                Material(
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _getRoleColor(user.role).withOpacity(0.1),
                    ),
                    child: Icon(
                      _getRoleIcon(user.role),
                      size: 30,
                      color: _getRoleColor(user.role),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.display_name ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleColor(user.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _getRoleColor(user.role).withOpacity(0.3)),
                        ),
                        child: Text(
                          user.role.toUpperCase().replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 11,
                            color: _getRoleColor(user.role),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Action Button (View/Edit placeholder)
                IconButton(
                  icon: Icon(Icons.chevron_right, color: Colors.grey[400]),
                  onPressed: () {
                    // Future: Navigate to details or edit
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'delivery_staff':
        return Colors.orange;
      case 'customer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'super_admin':
        return Icons.admin_panel_settings;
      case 'admin':
        return Icons.security;
      case 'delivery_staff':
        return Icons.local_shipping;
      case 'customer':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }
}
