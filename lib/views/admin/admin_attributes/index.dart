import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/attribute_model.dart';
import '/services/admin/attribute_service.dart';
import '/views/admin/admin_attributes/form.dart';

class AdminAttributesIndex extends StatefulWidget {
  const AdminAttributesIndex({Key? key}) : super(key: key);

  @override
  State<AdminAttributesIndex> createState() => _AdminAttributesIndexState();
}

class _AdminAttributesIndexState extends State<AdminAttributesIndex> {
  final AttributeService _attributeService = AttributeService();
  final TextEditingController _searchController = TextEditingController();

  String _filterStatus = 'active';
  int _itemsPerPage = 10;
  int _currentPage = 1;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AttributeModel> _applyFilterSearchPagination(
      List<AttributeModel> attributes) {
    // FILTER
    List<AttributeModel> filtered = attributes.where((attr) {
      if (_filterStatus == 'active') return !attr.is_archived;
      if (_filterStatus == 'archived') return attr.is_archived;
      return true;
    }).toList();

    // SEARCH
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((attr) => attr.name
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
    return AdminLayout(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SEARCH FIELD
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Attributes',
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

            // ATTRIBUTE LIST
            Expanded(
              child: StreamBuilder<List<AttributeModel>>(
                stream: _attributeService.getAttributesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No attributes found.'));
                  }

                  final attributes = snapshot.data!;
                  final paginatedAttributes =
                      _applyFilterSearchPagination(attributes);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: paginatedAttributes.length,
                          itemBuilder: (context, index) {
                            final attribute = paginatedAttributes[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text(
                                  attribute.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: attribute.is_archived
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                subtitle: Text(attribute.is_archived
                                    ? 'Archived'
                                    : 'Active'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Archive / Unarchive
                                    IconButton(
                                      icon: Icon(
                                        attribute.is_archived
                                            ? Icons.unarchive
                                            : Icons.archive,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () async {
                                        final action = attribute.is_archived
                                            ? 'unarchive'
                                            : 'archive';
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text('Confirm $action'),
                                            content: Text(
                                              'Are you sure you want to $action "${attribute.name}"?',
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
                                                    '${action[0].toUpperCase()}${action.substring(1)}'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          await _attributeService
                                              .archiveAttribute(attribute.id);
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
                                            builder: (_) => AdminAttributeForm(
                                              attribute: attribute,
                                            ),
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
                                                'Are you sure you want to delete "${attribute.name}"?'),
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
                                          // Optional: implement delete method
                                          // await _attributeService.deleteAttribute(attribute.id);
                                          await _attributeService
                                              .archiveAttribute(attribute.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

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
                            onPressed: () => _nextPage(attributes.length),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),

            // FLOATING BUTTON
            Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminAttributeForm(),
                    ),
                  );
                },
                child: const Icon(Icons.add),
                tooltip: 'Add Attribute',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
