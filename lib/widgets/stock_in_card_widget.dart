import 'package:flutter/material.dart';
import '/models/stock_in_model.dart';

class StockInCardWidget extends StatelessWidget {
  final StockInModel stockIn;
  final void Function(String) onMenuSelected;
  final VoidCallback? onTap;
  final VoidCallback? onViewDetails;

  const StockInCardWidget({
    Key? key,
    required this.stockIn,
    required this.onMenuSelected,
    this.onTap,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deductedQuantity = stockIn.quantity - stockIn.remaining_quantity;
    final isDepleted = stockIn.remaining_quantity == 0;
    final remainingPercentage =
        (stockIn.remaining_quantity / stockIn.quantity * 100).round();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shadowColor: Colors.green.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                isDepleted ? Colors.red.shade50 : Colors.green.shade50,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with product info and status
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDepleted
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDepleted ? Colors.red : Colors.green,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isDepleted ? Icons.close : Icons.check_circle,
                      color: isDepleted ? Colors.red : Colors.green,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stockIn.product_variant_id != null
                              ? 'Variant: ${stockIn.product_variant_id!.substring(0, 8).toUpperCase()}'
                              : 'Product: ${stockIn.product_id ?? "No Product Assigned"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: stockIn.is_archived
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDepleted ? Colors.red : Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$remainingPercentage%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (stockIn.is_archived)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'ARCHIVED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Menu button
                  PopupMenuButton<String>(
                    onSelected: onMenuSelected,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 18),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
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
                      PopupMenuItem(
                        value: stockIn.is_archived ? 'unarchive' : 'archive',
                        child: Row(
                          children: [
                            Icon(
                              stockIn.is_archived
                                  ? Icons.unarchive
                                  : Icons.archive,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(stockIn.is_archived ? 'Unarchive' : 'Archive'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quantity information
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total: ${stockIn.quantity} units',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Remaining: ${stockIn.remaining_quantity} units',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDepleted ? Colors.red : Colors.green,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Deducted: $deductedQuantity units',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.orange,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: stockIn.remaining_quantity / stockIn.quantity,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDepleted ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDepleted
                              ? 'Depleted'
                              : '${((stockIn.remaining_quantity / stockIn.quantity) * 100).toInt()}% Left',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDepleted ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reason: ${stockIn.reason}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Batch: ${stockIn.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            stockIn.created_at?.toString().substring(0, 10) ??
                                "N/A",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${stockIn.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
