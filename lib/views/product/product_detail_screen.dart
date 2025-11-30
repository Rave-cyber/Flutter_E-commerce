// product_detail_screen.dart
import 'package:firebase/models/product.dart';
import 'package:firebase/views/favorites/favorites_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/firestore_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isFavorite = false;
  bool _addingToCart = false;
  bool _loadingFavorites = false;
  final Color primaryGreen = const Color(0xFF2C8610);

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  void _checkIfFavorite() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null && widget.product.id != null) {
      final isFav = await FirestoreService.isProductInFavorites(
          user.uid, widget.product.id!);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    }
  }

  void _toggleFavorite() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    if (user == null) {
      _showSnackBar('Please login to add favorites', Colors.orange);
      return;
    }

    if (widget.product.id == null) {
      _showSnackBar('Product error', Colors.red);
      return;
    }

    try {
      await FirestoreService.toggleFavorite(user.uid, widget.product.id!);
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
      _showSnackBar(
        _isFavorite ? 'Added to favorites!' : 'Removed from favorites',
        primaryGreen,
      );
    } catch (e) {
      _showSnackBar('Error updating favorites', Colors.red);
    }
  }

  void _addToCart() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    if (user == null) {
      _showSnackBar('Please login to add to cart', Colors.orange);
      return;
    }

    if (widget.product.id == null) {
      _showSnackBar('Product error', Colors.red);
      return;
    }

    if (widget.product.stock_quantity <= 0) {
      _showSnackBar('Product is out of stock', Colors.red);
      return;
    }

    setState(() {
      _addingToCart = true;
    });

    try {
      await FirestoreService.addToCart(
        userId: user.uid,
        productId: widget.product.id!,
        productName: widget.product.name,
        productImage: widget.product.image,
        price: widget.product.sale_price,
        quantity: 1,
      );

      if (mounted) {
        _showSnackBar('Added to cart!', primaryGreen);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error adding to cart', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _addingToCart = false;
        });
      }
    }
  }

  void _navigateToFavorites() async {
    final authUser =
        Provider.of<AuthService>(context, listen: false).currentUser;
    if (authUser != null) {
      setState(() {
        _loadingFavorites = true;
      });

      try {
        // Get user data from Firestore
        final userModel = await FirestoreService.getUserData(authUser.uid);

        if (userModel != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FavoritesScreen(
                user: userModel,
              ),
            ),
          );
        } else {
          _showSnackBar('User data not found', Colors.red);
        }
      } catch (e) {
        _showSnackBar('Error loading favorites', Colors.red);
      } finally {
        if (mounted) {
          setState(() {
            _loadingFavorites = false;
          });
        }
      }
    } else {
      _showSnackBar('Please login to view favorites', Colors.orange);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _shareProduct() {
    final shareText =
        'Check out ${widget.product.name} for \$${widget.product.sale_price.toStringAsFixed(2)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share: $shareText'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product-${widget.product.id}',
                child: widget.product.image.isNotEmpty
                    ? Image.network(
                        widget.product.image,
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
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: _shareProduct,
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
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${widget.product.sale_price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.product.sale_price < widget.product.base_price)
                        Text(
                          '\$${widget.product.base_price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.product.stock_quantity > 0
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.product.stock_quantity > 0
                              ? 'In Stock'
                              : 'Out of Stock',
                          style: TextStyle(
                            color: widget.product.stock_quantity > 0
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.inventory_2,
                        text: '${widget.product.stock_quantity} available',
                        color: widget.product.stock_quantity > 0
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      if (widget.product.category_id != null &&
                          widget.product.category_id!.isNotEmpty)
                        _buildInfoChip(
                          icon: Icons.category,
                          text: widget.product.category_id!,
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
              onPressed: widget.product.stock_quantity > 0 && !_addingToCart
                  ? _addToCart
                  : null,
              icon: _addingToCart
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.shopping_cart),
              label: Text(
                _addingToCart
                    ? 'Adding...'
                    : (widget.product.stock_quantity > 0
                        ? 'Add to Cart'
                        : 'Out of Stock'),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: primaryGreen,
                disabledBackgroundColor: Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _loadingFavorites ? null : _navigateToFavorites,
            icon: _loadingFavorites
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                    ),
                  )
                : Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.grey,
                  ),
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
