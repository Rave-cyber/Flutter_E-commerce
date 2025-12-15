import 'package:flutter/material.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../layouts/super_admin_layout.dart';
import 'form.dart';
import '../../../widgets/user_search_widget.dart';
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

  Future<void> _handleMenuSelection(String value, UserModel user) async {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SuperAdminUsersForm(),
          ),
        );
        break;
      case 'archive':
      case 'unarchive':
        final action = user.is_archived ? 'unarchive' : 'archive';
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Confirm $action'),
            content: Text(
              'Are you sure you want to $action "${user.display_name ?? user.email}"?',
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
          // Handle archive/unarchive logic here
          // await _authService.toggleArchive(user);
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
              'Are you sure you want to delete "${user.display_name ?? user.email}"?',
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
          // Handle delete logic here
          // await _authService.deleteUser(user.id);
        }
        break;
    }
  }

  void _showUserDetailsModal(UserModel user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _getRoleColor(user.role).withOpacity(0.1),
                child: Icon(
                  _getRoleIcon(user.role),
                  size: 30,
                  color: _getRoleColor(user.role),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.display_name ?? 'No Name',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(user.email),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRoleColor(user.role).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _getRoleColor(user.role).withOpacity(0.3)),
                ),
                child: Text(
                  user.role.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getRoleColor(user.role),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
            UserSearchWidget(
              controller: _searchController,
              onChanged: () => setState(() {
                _currentPage = 1;
              }),
            ),
            const SizedBox(height: 16),

            // FILTER AND PER PAGE DROPDOWN - Horizontally Scrollable
            Material(
              elevation: 3,
              shadowColor: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
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
            ),
            const SizedBox(height: 16),

            // USERS LIST WITH BOTTOM CONTROLS
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // We are querying the 'users' collection
                stream: _authService.firestore
                    .collection('users')
                    .orderBy('created_at', descending: true)
                    .snapshots(),
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
                      // USER LIST
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedUsers.length,
                          itemBuilder: (context, index) {
                            final user = paginatedUsers[index];
                            return _buildUserCard(user);
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
                            onPreviousPage: _prevPage,
                            onNextPage: () => _nextPage(users.length),
                          ),

                          // ADD USER BUTTON - Right end
                          FloatingActionButtonWidget(
                            tooltip: 'Add User',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const SuperAdminUsersForm()),
                              );
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

                // Popup Menu Button
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                  onSelected: (value) => _handleMenuSelection(value, user),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'archive',
                      child: Row(
                        children: [
                          Icon(Icons.archive, size: 18),
                          SizedBox(width: 8),
                          Text('Archive'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
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
