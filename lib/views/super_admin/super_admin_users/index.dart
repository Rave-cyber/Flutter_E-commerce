import 'package:flutter/material.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../layouts/super_admin_layout.dart';
import 'form.dart';

class SuperAdminUsersScreen extends StatefulWidget {
  const SuperAdminUsersScreen({super.key});

  @override
  State<SuperAdminUsersScreen> createState() => _SuperAdminUsersScreenState();
}

class _SuperAdminUsersScreenState extends State<SuperAdminUsersScreen> {
  final AuthService _authService = AuthService();

  // Pagination & Filtering
  String _searchQuery = '';
  String _roleFilter = 'all'; // all, admin, delivery_staff, customer

  @override
  Widget build(BuildContext context) {
    return SuperAdminLayout(
      title: 'Users Management',
      selectedRoute: '/super-admin/users',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Top Action Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: _roleFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Roles')),
                    DropdownMenuItem(value: 'admin', child: Text('Admins')),
                    DropdownMenuItem(
                        value: 'delivery_staff', child: Text('Delivery Staff')),
                    DropdownMenuItem(
                        value: 'customer', child: Text('Customers')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _roleFilter = val);
                  },
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SuperAdminUsersForm()));
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Add User',
                      style: TextStyle(color: Colors.white)),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // We are querying the 'users' collection to get the base user info (role, email)
                stream: _authService.firestore.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  }

                  // Filter logic on client side for search/role
                  // (Firestore complex querying limits OR conditions)
                  var users = snapshot.data!.docs
                      .map((doc) =>
                          UserModel.fromMap(doc.data() as Map<String, dynamic>))
                      .toList();

                  // Filter by role
                  if (_roleFilter != 'all') {
                    users = users.where((u) => u.role == _roleFilter).toList();
                  }

                  // Filter by search (email or display name)
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    users = users.where((u) {
                      final email = u.email.toLowerCase();
                      final name = (u.display_name ?? '').toLowerCase();
                      return email.contains(query) || name.contains(query);
                    }).toList();
                  }

                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRoleColor(user.role),
                          child: Icon(_getRoleIcon(user.role),
                              color: Colors.white),
                        ),
                        title: Text(user.display_name ?? user.email),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    _getRoleColor(user.role).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border:
                                    Border.all(color: _getRoleColor(user.role)),
                              ),
                              child: Text(
                                user.role.toUpperCase().replaceAll('_', ' '),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: _getRoleColor(user.role),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        // Actions could be added here (Edit/Delete)
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // View details or edit
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
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
