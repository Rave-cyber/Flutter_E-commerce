// product_detail_screen.dart
import 'package:firebase/models/product.dart';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;

  const ProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${product.id}',
                child: product.image.isNotEmpty
                    ? Image.network(
                        product.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 100,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 100,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${product.sale_price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.sale_price < product.base_price)
                        Text(
                          '\$${product.base_price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.inventory_2,
                        text: '${product.stock_quantity} in stock',
                        color: product.stock_quantity > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: Icons.category,
                        text: product.category_id ?? 'Uncategorized',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        text,
        style: TextStyle(fontSize: 12, color: color),
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: product.stock_quantity > 0
                  ? () {
                      // Add to cart functionality
                    }
                  : null,
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                product.stock_quantity > 0 ? 'Add to Cart' : 'Out of Stock',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF2C8610),
                disabledBackgroundColor: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey[200],
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}
