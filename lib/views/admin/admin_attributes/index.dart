import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';
import '/models/attribute_model.dart';
import '/models/attribute_value_model.dart';
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

  int _getTotalPages(List<AttributeModel> attributes) {
    // Apply filters
    List<AttributeModel> filtered = attributes.where((attr) {
      if (_filterStatus == 'active') return !attr.is_archived;
      if (_filterStatus == 'archived') return attr.is_archived;
      return true;
    }).toList();

    // Apply search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((attr) => attr.name
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
      String value, AttributeModel attribute) async {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminAttributeForm(attribute: attribute),
          ),
        );
        break;
      case 'archive':
      case 'unarchive':
        final action = attribute.is_archived ? 'unarchive' : 'archive';
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text('Confirm $action'),
            content: Text(
              'Are you sure you want to $action "${attribute.name}"?',
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
          if (action == 'archive') {
            await _attributeService.archiveAttribute(attribute.id);
          } else {
            await _attributeService.unarchiveAttribute(attribute.id);
          }
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
              'Are you sure you want to delete "${attribute.name}"?',
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
          await _attributeService.archiveAttribute(attribute.id);
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

  void _showAttributeDetailsModal(AttributeModel attribute) async {
    // Load attribute values
    final attributeValues =
        await _attributeService.getAttributeValues(attribute.id);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attribute Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 20),
                _buildDetailRow('Attribute Name', attribute.name),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Status',
                  attribute.is_archived ? 'Archived' : 'Active',
                  valueColor:
                      attribute.is_archived ? Colors.grey : Colors.green,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Created',
                  _formatDateTime(attribute.created_at),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Last Updated',
                  _formatDateTime(attribute.updated_at),
                ),
                const SizedBox(height: 20),
                Text(
                  'Attribute Values',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                if (attributeValues.isEmpty)
                  Text(
                    'No values defined',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  ...attributeValues.map((value) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.label_outlined,
                              size: 16,
                              color: Colors.green[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                value.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      selectedRoute: '/admin/attributes',
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

            // ATTRIBUTE LIST WITH BOTTOM CONTROLS
            Expanded(
              child: StreamBuilder<List<AttributeModel>>(
                stream: _attributeService.getAttributesStream(
                    includeArchived: true),
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
                              Icon(Icons.tune_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No attributes found.',
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

                  final attributes = snapshot.data!;
                  final paginatedAttributes =
                      _applyFilterSearchPagination(attributes);
                  final totalPages = _getTotalPages(attributes);

                  return Column(
                    children: [
                      // ATTRIBUTE LIST
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
                                    onTap: () =>
                                        _showAttributeDetailsModal(attribute),
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
                                    trailing: PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: Colors.grey[700],
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 8,
                                      onSelected: (value) =>
                                          _handleMenuSelection(
                                              value, attribute),
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
                                        // const PopupMenuItem(
                                        //   value: 'delete',
                                        //   child: Row(
                                        //     children: [
                                        //       Icon(Icons.delete,
                                        //           size: 20, color: Colors.red),
                                        //       SizedBox(width: 8),
                                        //       Text('Delete',
                                        //           style: TextStyle(
                                        //               color: Colors.red)),
                                        //     ],
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
                            onNextPage: () => _nextPage(attributes.length),
                          ),

                          // ADD ATTRIBUTE BUTTON - Right end
                          FloatingActionButtonWidget(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminAttributeForm()),
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
}
