import 'package:flutter/material.dart';
import '/models/stock_checker_model.dart';

class StockCheckerCardWidget extends StatelessWidget {
  final StockCheckerModel checker;
  final Function(String) onMenuSelected;
  final VoidCallback? onTap;

  const StockCheckerCardWidget({
    Key? key,
    required this.checker,
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
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                  // Header Row with Icon, Title, and Menu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stock Checker Icon - Elevated
                      Material(
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey[50],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: const Icon(
                              Icons.person_search,
                              size: 40,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Stock Checker Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Full Name with Status Icon
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${checker.firstname} ${checker.middlename} ${checker.lastname}",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: checker.is_archived
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Animated Status Circle Icon
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: checker.is_archived
                                        ? Colors.grey.shade400
                                        : Colors.green.shade500,
                                    boxShadow: [
                                      BoxShadow(
                                        color: checker.is_archived
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
                                // Status Text
                                Text(
                                  checker.is_archived ? 'archived' : 'active',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: checker.is_archived
                                        ? Colors.grey.shade600
                                        : Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Contact
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    checker.contact,
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
                          ],
                        ),
                      ),

                      // 3-Dots Menu
                      GestureDetector(
                        onTap: () {}, // Prevent tap from propagating to card
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.grey[700],
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          onSelected: onMenuSelected,
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
                              value:
                                  checker.is_archived ? 'unarchive' : 'archive',
                              child: Row(
                                children: [
                                  Icon(
                                    checker.is_archived
                                        ? Icons.unarchive
                                        : Icons.archive,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(checker.is_archived
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
                            //           style: TextStyle(color: Colors.red)),
                            //     ],
                            //   ),
                            // ),
                          ],
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

                  // Address
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
                          checker.address,
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
          ),
        ),
      ),
    );
  }
}
