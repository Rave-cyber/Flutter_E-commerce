import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/product_variant_model.dart';
import '../models/attribute_model.dart';
import '../models/attribute_value_model.dart';
import '../services/admin/product_sevice.dart';

class ProductDetailsModal extends StatefulWidget {
  final ProductModel product;
  final String Function(String) getCategoryName;
  final String Function(String) getBrandName;

  const ProductDetailsModal({
    Key? key,
    required this.product,
    required this.getCategoryName,
    required this.getBrandName,
  }) : super(key: key);

  @override
  State<ProductDetailsModal> createState() => _ProductDetailsModalState();
}

class _ProductDetailsModalState extends State<ProductDetailsModal> {
  final ProductService _productService = ProductService();
  List<ProductVariantModel> _variants = [];
  List<AttributeModel> _attributes = [];
  Map<String, List<Map<String, dynamic>>> _variantAttributesMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      // Load variants and attributes concurrently
      final results = await Future.wait([
        _productService.fetchVariants(widget.product.id),
        _productService.fetchAttributes(),
      ]);

      setState(() {
        _variants = results[0] as List<ProductVariantModel>;
        _attributes = results[1] as List<AttributeModel>;
      });

      // Load attribute values for each variant
      await _loadVariantAttributes();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading product details: $e')),
      );
    }
  }

  Future<void> _loadVariantAttributes() async {
    for (final variant in _variants) {
      try {
        final variantAttributes =
            await _productService.fetchVariantAttributes(variant.id);

        // Get attribute and value details for each variant attribute
        List<Map<String, dynamic>> detailedAttributes = [];
        for (final attr in variantAttributes) {
          final attributeId = attr['attribute_id'] as String;
          final attributeValueId = attr['attribute_value_id'] as String;

          final attribute = _attributes.firstWhere(
            (a) => a.id == attributeId,
            orElse: () =>
                AttributeModel(id: '', name: 'Unknown', is_archived: false),
          );

          // Fetch attribute value details
          final attributeValues =
              await _productService.fetchAttributeValues(attributeId);
          final attributeValue = attributeValues.firstWhere(
            (av) => av.id == attributeValueId,
            orElse: () => AttributeValueModel(
                id: '', attribute_id: '', name: 'Unknown', is_archived: false),
          );

          detailedAttributes.add({
            'attribute': attribute,
            'value': attributeValue,
          });
        }

        setState(() {
          _variantAttributesMap[variant.id] = detailedAttributes;
        });
      } catch (e) {
        setState(() {
          _variantAttributesMap[variant.id] = [];
        });
      }
    }
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match match) => '${match[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
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
                      'Product Details',
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Basic Info
                          _buildProductBasicInfo(),
                          const SizedBox(height: 20),

                          // Variants Section
                          if (_variants.isNotEmpty) ...[
                            _buildVariantsSection(),
                          ] else ...[
                            _buildNoVariantsSection(),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image - Centered and Larger
          Center(
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.product.image.isNotEmpty
                      ? Image.network(
                          widget.product.image,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported,
                              size: 60,
                              color: Colors.grey,
                            );
                          },
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

          const SizedBox(height: 16),

          // Product Name - Centered
          Center(
            child: Text(
              widget.product.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12),

          // Product Description - Full Width Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              widget.product.description.isEmpty
                  ? 'No description available'
                  : widget.product.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.left,
            ),
          ),

          const SizedBox(height: 16),

          // Product Meta Info - Clean Layout
          _buildInfoRow(
            icon: Icons.category,
            label: 'Category',
            value: widget.getCategoryName(widget.product.category_id),
          ),

          const SizedBox(height: 8),

          _buildInfoRow(
            icon: Icons.storefront,
            label: 'Brand',
            value: widget.getBrandName(widget.product.brand_id),
          ),

          const SizedBox(height: 16),

          // Pricing and Stock - Clean Layout
          _buildInfoRow(
            icon: Icons.attach_money,
            label: 'Base Price',
            value: '₱${_formatPrice(widget.product.base_price)}',
          ),

          const SizedBox(height: 8),

          _buildInfoRow(
            icon: Icons.sell,
            label: 'Sale Price',
            value: '₱${_formatPrice(widget.product.sale_price)}',
          ),

          const SizedBox(height: 8),

          _buildStockInfo(),

          const SizedBox(height: 16),

          // Additional Info - Clean Layout
          if (widget.product.sku != null) ...[
            _buildInfoRow(
              icon: Icons.tag,
              label: 'SKU',
              value: widget.product.sku!,
            ),
            const SizedBox(height: 8),
          ],

          _buildInfoRow(
            icon:
                widget.product.is_archived ? Icons.archive : Icons.check_circle,
            label: 'Status',
            value: widget.product.is_archived ? 'Archived' : 'Active',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
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
            color: iconColor ?? Colors.grey[600],
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
      ),
    );
  }

  Widget _buildStockInfo() {
    final stockQuantity = widget.product.stock_quantity ?? 0;
    Color stockColor;
    IconData stockIcon;

    if (stockQuantity > 10) {
      stockColor = Colors.green.shade600;
      stockIcon = Icons.inventory_2;
    } else if (stockQuantity > 0) {
      stockColor = Colors.orange.shade600;
      stockIcon = Icons.warning;
    } else {
      stockColor = Colors.red.shade600;
      stockIcon = Icons.error;
    }

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
            stockIcon,
            size: 20,
            color: stockColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$stockQuantity units',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: stockColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.layers,
              size: 20,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'Product Variants (${_variants.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _variants.length,
          itemBuilder: (context, index) {
            final variant = _variants[index];
            return _buildVariantCard(variant);
          },
        ),
      ],
    );
  }

  Widget _buildVariantCard(ProductVariantModel variant) {
    final variantAttributes = _variantAttributesMap[variant.id] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Variant Image - Centered
          Center(
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: variant.image.isNotEmpty
                      ? Image.network(
                          variant.image,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey,
                            );
                          },
                        )
                      : const Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey,
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Variant Details
          Center(
            child: Text(
              variant.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 8),

          // Variant SKU
          if (variant.sku != null)
            _buildVariantInfoRow(
              icon: Icons.tag,
              label: 'SKU',
              value: variant.sku!,
            ),

          const SizedBox(height: 8),

          // Variant Pricing
          _buildVariantInfoRow(
            icon: Icons.attach_money,
            label: 'Price',
            value: '₱${_formatPrice(variant.sale_price)}',
          ),

          const SizedBox(height: 8),

          // Variant Stock
          _buildVariantStockRow(variant),

          // Variant Attributes
          if (variantAttributes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildVariantAttributes(variantAttributes),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantStockRow(ProductVariantModel variant) {
    final stockQuantity = variant.stock ?? 0;
    Color stockColor;
    IconData stockIcon;

    if (stockQuantity > 10) {
      stockColor = Colors.green.shade600;
      stockIcon = Icons.inventory_2;
    } else if (stockQuantity > 0) {
      stockColor = Colors.orange.shade600;
      stockIcon = Icons.warning;
    } else {
      stockColor = Colors.red.shade600;
      stockIcon = Icons.error;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: stockColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: stockColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            stockIcon,
            size: 16,
            color: stockColor,
          ),
          const SizedBox(width: 8),
          Text(
            'Stock: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              '$stockQuantity units',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: stockColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantAttributes(List<Map<String, dynamic>> variantAttributes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.label,
                size: 16,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Attributes:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...variantAttributes.map((attr) {
            final attribute = attr['attribute'] as AttributeModel;
            final value = attr['value'] as AttributeValueModel;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      '${attribute.name}: ${value.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildNoVariantsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No Variants Available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This product does not have any variants.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
