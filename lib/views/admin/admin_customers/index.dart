import 'package:firebase/models/customer_model.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';

class AdminCustomersIndex extends StatefulWidget {
  const AdminCustomersIndex({Key? key}) : super(key: key);

  @override
  State<AdminCustomersIndex> createState() => _AdminCustomersIndexState();
}

class _AdminCustomersIndexState extends State<AdminCustomersIndex> {
  final AuthService _authService = AuthService();
  String _searchQuery = '';
  bool _showArchived = false;

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

        return customers;
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
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadUserArchiveStatuses();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search by name',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    const Text('Show Archived'),
                    Switch(
                      value: _showArchived,
                      onChanged: (val) {
                        setState(() => _showArchived = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<CustomerModel>>(
                stream: getCustomersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No customers found.'));
                  }

                  final customers = snapshot.data!;

                  return ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      final isArchived =
                          _userArchiveStatus[customer.user_id] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(
                              '${customer.firstname} ${customer.middlename} ${customer.lastname}'),
                          subtitle: Text(
                              'Address: ${customer.address}\nContact: ${customer.contact}'),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: Icon(
                              isArchived ? Icons.unarchive : Icons.archive,
                              color: Colors.orange,
                            ),
                            tooltip: 'Archive/Unarchive',
                            onPressed: () => toggleArchive(customer),
                          ),
                        ),
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
}
