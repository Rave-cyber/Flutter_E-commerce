import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../firestore_service.dart';

class OrderDetailsModal extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsModal({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<OrderDetailsModal> createState() => _OrderDetailsModalState();
}

class _OrderDetailsModalState extends State<OrderDetailsModal> {
  Map<String, dynamic>? _deliveryStaffData;
  bool _isLoadingDeliveryStaff = false;

  @override
  void initState() {
    super.initState();
    _loadDeliveryStaffData();
  }

  Future<void> _loadDeliveryStaffData() async {
    final deliveryStaffId = widget.order['deliveryStaffId'];
    if (deliveryStaffId != null && widget.order['status'] == 'delivered') {
      setState(() {
        _isLoadingDeliveryStaff = true;
      });

      try {
        final userData = await FirestoreService.getUserData(deliveryStaffId);
        if (userData != null) {
          setState(() {
            _deliveryStaffData = userData.toMap();
          });
        }
      } catch (e) {
        print('Error loading delivery staff data: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoadingDeliveryStaff = false;
          });
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.order['items'] as List<dynamic>?) ?? [];
    final totalAmount = widget.order['total']?.toDouble() ?? 0.0;
    final shipping = widget.order['shipping']?.toDouble() ?? 0.0;
    final subtotal = widget.order['subtotal']?.toDouble() ?? 0.0;
    final createdAt = widget.order['createdAt'] as Timestamp?;
    final updatedAt = widget.order['updatedAt'] as Timestamp?;
    final deliveredAt = widget.order['deliveredAt'] as Timestamp?;
    final shippingAddress =
        widget.order['shippingAddress'] ?? 'No address provided';
    final contactNumber = widget.order['contactNumber'] ?? 'No contact number';
    final status = widget.order['status'] ?? 'pending';
    final deliveryProofImage = widget.order['deliveryProofImage'];
    final deliveryNotes = widget.order['deliveryNotes'];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade400, Colors.green.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${widget.order['id'].toString().substring(0, 8)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _getStatusColor(status), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${status.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Customer Details
                    _buildSectionTitle('Customer Details'),
                    _buildInfoContainer([
                      _buildInfoRow(
                        icon: Icons.person_outline,
                        label: 'Contact Number',
                        value: contactNumber,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Shipping Address',
                        value: shippingAddress,
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Order Items
                    _buildSectionTitle('Order Items (${items.length})'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item['productImage'] ?? '',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error,
                                            stackTrace) =>
                                        const Icon(Icons.image_not_supported,
                                            size: 30, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['productName'] ?? 'Unknown Product',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Quantity: ${item['quantity']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₱${NumberFormat('#,###.00').format(item['price'] * item['quantity'])}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Payment Summary
                    _buildSectionTitle('Payment Summary'),
                    _buildInfoContainer([
                      _buildPaymentRow('Subtotal', subtotal),
                      const SizedBox(height: 8),
                      _buildPaymentRow('Shipping Fee', shipping),
                      const Divider(height: 24),
                      _buildPaymentRow('Total Amount', totalAmount,
                          isTotal: true),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.payment,
                        label: 'Payment Method',
                        value: (widget.order['paymentMethod'] ?? 'COD')
                            .toUpperCase(),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Delivery Information (only for delivered orders)
                    if (status == 'delivered') ...[
                      _buildSectionTitle('Delivery Information'),
                      _buildDeliveryInfo(),
                      const SizedBox(height: 20),
                    ],

                    // Timestamps
                    _buildSectionTitle('Timeline'),
                    _buildInfoContainer([
                      if (createdAt != null)
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          label: 'Ordered Date',
                          value: _formatDate(createdAt.toDate()),
                        ),
                      if (updatedAt != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.update,
                          label: 'Last Updated',
                          value: _formatDate(updatedAt.toDate()),
                        ),
                      ],
                      if (deliveredAt != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.check_circle,
                          label: 'Delivered Date',
                          value: _formatDate(deliveredAt.toDate()),
                        ),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo() {
    final deliveryProofImage = widget.order['deliveryProofImage'];
    final deliveryNotes = widget.order['deliveryNotes'];

    return _buildInfoContainer([
      // Delivery Staff Information
      if (_isLoadingDeliveryStaff)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_deliveryStaffData != null) ...[
        _buildInfoRow(
          icon: Icons.person,
          label: 'Delivery Staff',
          value: _deliveryStaffData!['name'] ?? 'Unknown Staff',
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.phone,
          label: 'Contact',
          value: _deliveryStaffData!['contactNumber'] ?? 'No contact',
        ),
        if (deliveryNotes != null && deliveryNotes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.note,
            label: 'Delivery Notes',
            value: deliveryNotes,
          ),
        ],
      ] else ...[
        // Fallback if no delivery staff data
        _buildInfoRow(
          icon: Icons.local_shipping,
          label: 'Delivery Staff',
          value: 'Assigned',
        ),
      ],

      // Delivery Proof Image
      if (deliveryProofImage != null && deliveryProofImage.isNotEmpty) ...[
        const SizedBox(height: 16),
        const Text(
          'Delivery Proof:',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              deliveryProofImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image not available',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ]);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          '₱${NumberFormat('#,###.00').format(amount)}',
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }
}
