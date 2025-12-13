import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/attribute_model.dart';
import '/services/admin/attribute_service.dart';
import '/views/admin/admin_attributes/form.dart';
import '/widgets/product_search_widget.dart';
import '/widgets/product_filter_widget.dart';
import '/widgets/product_pagination_widget.dart';
import '/widgets/floating_action_button_widget.dart';

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
            // SEARCH FIELD - Using ProductSearchWidget
            ProductSearchWidget(
              controller: _searchController,
              onChanged: () {
                setState(() {
                  _currentPage = 1;
                });
              },
            ),
            const SizedBox(height: 16),

            // FILTER WIDGET - Using ProductFilterWidget
            ProductFilterWidget(
              filterStatus: _filterStatus,
              itemsPerPage: _itemsPerPage,
              onFilterChanged: (val) {
                if (val != null) {
                  setState(() {
                    _filterStatus = val;
                    _currentPage = 1;
                  });
                }
              },
              onItemsPerPageChanged: (val) {
                if (val != null) {
                  setState(() {
                    _itemsPerPage = val;
                    _currentPage = 1;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

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
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
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
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(
                                      attribute.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: attribute.is_archived
                                            ? Colors.grey
                                            : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      attribute.is_archived
                                          ? 'Archived'
                                          : 'Active',
                                      style: TextStyle(
                                        color: attribute.is_archived
                                            ? Colors.grey[600]
                                            : Colors.green[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    trailing: Material(
                                      elevation: 2,
                                      shadowColor:
                                          Colors.black.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[50],
                                      child: PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert,
                                          color: Colors.grey[700],
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 8,
                                        onSelected: (value) async {
                                          if (value == 'edit') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    AdminAttributeForm(
                                                  attribute: attribute,
                                                ),
                                              ),
                                            );
                                          } else if (value == 'archive' ||
                                              value == 'unarchive') {
                                            final action = value;
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                title: Text('Confirm $action'),
                                                content: Text(
                                                  'Are you sure you want to $action "${attribute.name}"?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.orange,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                    child: Text(
                                                      '${action[0].toUpperCase()}${action.substring(1)}',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await _attributeService
                                                  .archiveAttribute(
                                                      attribute.id);
                                            }
                                          } else if (value == 'delete') {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                                title: const Text(
                                                    'Confirm Delete'),
                                                content: Text(
                                                    'Are you sure you want to delete "${attribute.name}"?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.red,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              // Optional: implement delete method
                                              // await _attributeService.deleteAttribute(attribute.id);
                                              await _attributeService
                                                  .archiveAttribute(
                                                      attribute.id);
                                            }
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(Icons.edit, size: 20),
                                                SizedBox(width: 8),
                                                Text('Edit'),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: attribute.is_archived
                                                ? 'unarchive'
                                                : 'archive',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  attribute.is_archived
                                                      ? Icons.unarchive
                                                      : Icons.archive,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(attribute.is_archived
                                                    ? 'Unarchive'
                                                    : 'Archive'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    size: 20,
                                                    color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Delete',
                                                    style: TextStyle(
                                                        color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // PAGINATION CONTROLS - Using ProductPaginationWidget
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ProductPaginationWidget(
                          currentPage: _currentPage,
                          onPreviousPage: _prevPage,
                          onNextPage: () => _nextPage(attributes.length),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // FLOATING BUTTON - Using FloatingActionButtonWidget
            FloatingActionButtonWidget(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAttributeForm(),
                  ),
                );
              },
              tooltip: 'Add Attribute',
            ),
          ],
        ),
      ),
    );
  }
}
