import 'package:firebase/models/customer_model.dart';
import 'package:flutter/material.dart';

class CustomerCardWidget extends StatelessWidget {
  final CustomerModel customer;
  final bool isArchived;
  final Function(String) onMenuSelected;
  final VoidCallback? onTap;

  const CustomerCardWidget({
    Key? key,
    required this.customer,
    required this.isArchived,
    required this.onMenuSelected,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isArchived ? Colors.grey[400]! : Colors.green[400]!,
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
                            color: isArchived
                                ? Colors.grey[100]
                                : Colors.green[50],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: isArchived
                                  ? Colors.grey[600]
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
                            // Customer Name with Status Indicator (like products)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${customer.firstname} ${customer.middlename} ${customer.lastname}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isArchived
                                          ? Colors.grey[600]
                                          : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Animated Status Circle Icon (like products)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isArchived
                                        ? Colors.grey.shade400
                                        : Colors.green.shade500,
                                    boxShadow: [
                                      BoxShadow(
                                        color: isArchived
                                            ? Colors.grey.withOpacity(0.3)
                                            : Colors.green.withOpacity(0.4),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                        spreadRadius: 0.5,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Status Text (like products)
                                Text(
                                  isArchived ? 'archived' : 'active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isArchived
                                        ? Colors.grey.shade600
                                        : Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Contact Information with overflow handling
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    customer.contact,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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

                      // Menu Button
                      PopupMenuButton<String>(
                        onSelected: onMenuSelected,
                        itemBuilder: (context) => [
                          // const PopupMenuItem(
                          //   value: 'view',
                          //   child: ListTile(
                          //     leading: Icon(Icons.visibility),
                          //     title: Text('View Details'),
                          //     contentPadding: EdgeInsets.zero,
                          //   ),
                          // ),
                          // const PopupMenuItem(
                          //   value: 'edit',
                          //   child: ListTile(
                          //     leading: Icon(Icons.edit),
                          //     title: Text('Edit'),
                          //     contentPadding: EdgeInsets.zero,
                          //   ),
                          // ),
                          PopupMenuItem(
                            value: isArchived ? 'unarchive' : 'archive',
                            child: ListTile(
                              leading: Icon(
                                isArchived ? Icons.unarchive : Icons.archive,
                              ),
                              title: Text(isArchived ? 'Unarchive' : 'Archive'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          // const PopupMenuItem(
                          //   value: 'delete',
                          //   child: ListTile(
                          //     leading: Icon(Icons.delete, color: Colors.black),
                          //     title: Text('Delete',
                          //         style: TextStyle(color: Colors.black)),
                          //     contentPadding: EdgeInsets.zero,
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
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
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Registered',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Customer ID - Elevated
                      Material(
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }
}
