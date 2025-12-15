import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerDetailsModal extends StatelessWidget {
  final Map<String, dynamic> banner;

  const BannerDetailsModal({
    Key? key,
    required this.banner,
  }) : super(key: key);

  void _showImageFullScreen(
      BuildContext context, String imageUrl, String imageLabel) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              imageLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.grey,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    try {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        // Try parsing as milliseconds
        final intValue = int.tryParse(timestamp);
        if (intValue != null) {
          return DateTime.fromMillisecondsSinceEpoch(intValue);
        }
      }
    } catch (e) {
      // Return null if parsing fails
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = banner['image'] ?? '';
    final title = banner['title'] ?? 'No Title';
    final subtitle = banner['subtitle'] ?? 'No Subtitle';
    final buttonText = banner['buttonText'] ?? 'No Button Text';
    final order = banner['order'] ?? 0;
    final isActive = banner['isActive'] ?? true;
    final categoryId = banner['categoryId'];
    final createdAt = _parseTimestamp(banner['createdAt']);
    final updatedAt = _parseTimestamp(banner['updatedAt']);

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
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C8610), Color(0xFF4CAF50)],
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
                      'Banner Details',
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
                    // Banner Basic Info
                    _buildBannerBasicInfo(
                      imageUrl: imageUrl,
                      title: title,
                      subtitle: subtitle,
                      context: context,
                    ),
                    const SizedBox(height: 20),

                    // Banner Action Info
                    _buildBannerActionInfo(
                      buttonText: buttonText,
                      order: order,
                      isActive: isActive,
                    ),
                    const SizedBox(height: 20),

                    // Category Link Info
                    if (categoryId != null) ...[
                      _buildCategoryInfo(categoryId: categoryId),
                      const SizedBox(height: 20),
                    ],

                    // Timestamps
                    _buildTimestampInfo(
                      createdAt: createdAt,
                      updatedAt: updatedAt,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerBasicInfo({
    required String imageUrl,
    required String title,
    required String subtitle,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2C8610).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image - Clickable
          Center(
            child: GestureDetector(
              onTap: imageUrl.isNotEmpty
                  ? () => _showImageFullScreen(context, imageUrl, title)
                  : null,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 120,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Stack(
                            children: [
                              Image.network(
                                imageUrl,
                                width: 120,
                                height: 90,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.image_not_supported,
                                    size: 60,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Colors.grey,
                          ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Banner Title - Centered
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12),

          // Banner Subtitle - Full Width Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              subtitle.isEmpty ? 'No subtitle available' : subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerActionInfo({
    required String buttonText,
    required int order,
    required bool isActive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.touch_app,
              size: 20,
              color: const Color(0xFF2C8610),
            ),
            const SizedBox(width: 8),
            const Text(
              'Action Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.touch_app,
          label: 'Button Text',
          value: buttonText.isEmpty ? 'No button text' : buttonText,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: Icons.sort,
          label: 'Display Order',
          value: '$order (lower numbers appear first)',
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          icon: isActive ? Icons.check_circle : Icons.pause_circle,
          label: 'Status',
          value: isActive ? 'Active' : 'Inactive',
          valueColor: isActive ? Colors.green : Colors.orange,
        ),
      ],
    );
  }

  Widget _buildCategoryInfo({required String categoryId}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category,
              size: 20,
              color: const Color(0xFF2C8610),
            ),
            const SizedBox(width: 8),
            const Text(
              'Category Link',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          icon: Icons.link,
          label: 'Linked Category',
          value: 'Category ID: $categoryId',
        ),
      ],
    );
  }

  Widget _buildTimestampInfo({
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 20,
              color: const Color(0xFF2C8610),
            ),
            const SizedBox(width: 8),
            const Text(
              'Timestamps',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (createdAt != null) ...[
          _buildInfoRow(
            icon: Icons.add_circle,
            label: 'Created',
            value: _formatDate(createdAt),
          ),
          const SizedBox(height: 8),
        ],
        if (updatedAt != null) ...[
          _buildInfoRow(
            icon: Icons.update,
            label: 'Updated',
            value: _formatDate(updatedAt),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
