// product_detail_screen.dart
import 'package:firebase/models/product.dart';
import 'package:firebase/models/product_variant_model.dart';
import 'package:firebase/views/customer/favorites/favorites_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/firestore_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  bool _loadingVariants = true;
  bool _loadingBrandCategory = true;
  final Color primaryGreen = const Color(0xFF2C8610);

  List<ProductVariantModel> _variants = [];
  // Two possible selections: main product or variant
  dynamic _selectedOption; // Can be ProductModel or ProductVariantModel
  bool _isSelectingMainProduct = true; // Track if main product is selected
  String? _brandName;
  String? _categoryName;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
    _loadProductDetails();
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

  void _loadProductDetails() async {
    await Future.wait([
      _loadVariants(),
      _loadBrandAndCategory(),
    ]);
  }

  Future<void> _loadVariants() async {
    if (widget.product.id == null) {
      if (mounted) {
        setState(() {
          _loadingVariants = false;
          // By default, select the main product
          _selectedOption = widget.product;
          _isSelectingMainProduct = true;
        });
      }
      return;
    }

    try {
      final variants = await FirebaseFirestore.instance
          .collection('product_variants')
          .where('product_id', isEqualTo: widget.product.id)
          .where('is_archived', isEqualTo: false)
          .get();

      final variantsList = variants.docs
          .map((doc) => ProductVariantModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      if (mounted) {
        setState(() {
          _variants = variantsList;
          _loadingVariants = false;

          // Default: main product is selected
          _selectedOption = widget.product;
          _isSelectingMainProduct = true;
        });
      }
    } catch (e) {
      print('Error loading variants: $e');
      if (mounted) {
        setState(() {
          _loadingVariants = false;
          _selectedOption = widget.product;
          _isSelectingMainProduct = true;
        });
      }
    }
  }

  Future<void> _loadBrandAndCategory() async {
    try {
      if (widget.product.brand_id != null &&
          widget.product.brand_id!.isNotEmpty) {
        final brand =
            await FirestoreService.getBrandById(widget.product.brand_id!);
        if (brand != null && mounted) {
          setState(() {
            _brandName = brand['name'];
          });
        }
      }

      if (widget.product.category_id != null &&
          widget.product.category_id!.isNotEmpty) {
        final category =
            await FirestoreService.getCategoryById(widget.product.category_id!);
        if (category != null && mounted) {
          setState(() {
            _categoryName = category['name'];
          });
        }
      }
    } catch (e) {
      print('Error loading brand/category: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loadingBrandCategory = false;
        });
      }
    }
  }

  List<String> _getAllImages() {
    final images = <String>[];

    // Add main product image
    if (widget.product.image.isNotEmpty) {
      images.add(widget.product.image);
    }

    // Add variant images
    for (final variant in _variants) {
      if (variant.image.isNotEmpty && !images.contains(variant.image)) {
        images.add(variant.image);
      }
    }

    // If no images, return empty
    return images;
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

    // Determine stock based on selected option
    final stock = _isSelectingMainProduct
        ? widget.product.stock_quantity
        : (_selectedOption as ProductVariantModel).stock;

    if (stock <= 0) {
      _showSnackBar('Selected option is out of stock', Colors.red);
      return;
    }

    setState(() {
      _addingToCart = true;
    });

    try {
      String productName;
      String productImage;
      double price;
      String productId;

      if (_isSelectingMainProduct) {
        // Buying main product
        productName = widget.product.name;
        productImage = widget.product.image;
        price = widget.product.sale_price;
        productId = widget.product.id!;
      } else {
        // Buying variant
        final variant = _selectedOption as ProductVariantModel;
        productName = '${widget.product.name} - ${variant.name}';
        productImage =
            variant.image.isNotEmpty ? variant.image : widget.product.image;
        price = variant.sale_price;
        productId = variant.id; // Use variant ID for cart
      }

      await FirestoreService.addToCart(
        userId: user.uid,
        productId: productId,
        productName: productName,
        productImage: productImage,
        price: price,
        quantity: 1, // Default quantity to 1
      );

      if (mounted) {
        _showSnackBar('Added to cart!', primaryGreen);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error adding to cart: $e', Colors.red);
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

  Widget _buildImageCarousel() {
    final images = _getAllImages();

    if (images.isEmpty) {
      return Container(
        height: 400,
        color: Colors.grey[100],
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            size: 100,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Stack(
      children: [
        CarouselSlider(
          items: images.map((image) {
            return Image.network(
              image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 400,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[100],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            );
          }).toList(),
          options: CarouselOptions(
            height: 400,
            aspectRatio: 16 / 9,
            viewportFraction: 1.0,
            initialPage: 0,
            enableInfiniteScroll: true,
            reverse: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: images.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(
                    _currentImageIndex == entry.key ? 1.0 : 0.5,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top,
          right: 10,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.2),
            ),
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    // Get price based on selected option
    final price = _isSelectingMainProduct
        ? widget.product.sale_price
        : (_selectedOption as ProductVariantModel).sale_price;

    final originalPrice = _isSelectingMainProduct
        ? widget.product.base_price
        : (_selectedOption as ProductVariantModel).base_price;

    final hasDiscount = price < originalPrice;

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
            if (hasDiscount)
              Text(
                '\$${originalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
          ],
        ),
        if (hasDiscount)
          Container(
            margin: const EdgeInsets.only(left: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryGreen,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${((originalPrice - price) / originalPrice * 100).toStringAsFixed(0)}% OFF',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVariantSelector() {
    if (_loadingVariants) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    // Combine main product and variants
    final allOptions = <dynamic>[widget.product, ..._variants];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Select Variant',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allOptions.length,
            itemBuilder: (context, index) {
              final option = allOptions[index];
              final isMainProduct = index == 0;
              final isSelected = _isSelectingMainProduct
                  ? index == 0
                  : (option is ProductVariantModel &&
                      _selectedOption is ProductVariantModel &&
                      (option as ProductVariantModel).id ==
                          (_selectedOption as ProductVariantModel).id);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (index == 0) {
                      _selectedOption = widget.product;
                      _isSelectingMainProduct = true;
                    } else {
                      _selectedOption = option as ProductVariantModel;
                      _isSelectingMainProduct = false;
                    }
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: index == allOptions.length - 1 ? 0 : 12,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryGreen : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? primaryGreen : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isMainProduct
                            ? 'Standard'
                            : (option as ProductVariantModel).name,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isMainProduct)
                        const SizedBox(height: 2)
                      else
                        Text(
                          '\$${(option as ProductVariantModel).sale_price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : primaryGreen,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfoSection() {
    if (_loadingBrandCategory) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get stock based on selected option
    final stock = _isSelectingMainProduct
        ? widget.product.stock_quantity
        : (_selectedOption as ProductVariantModel).stock;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoItem('Brand', _brandName ?? 'No brand'),
              const SizedBox(width: 32),
              _buildInfoItem('Category', _categoryName ?? 'No category'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoItem('Stock', '$stock available'),
              const SizedBox(width: 32),
              _buildInfoItem(
                'Condition',
                widget.product.is_archived ? 'Archived' : 'Active',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get stock based on selected option
    final stock = _isSelectingMainProduct
        ? widget.product.stock_quantity
        : (_selectedOption as ProductVariantModel).stock;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageCarousel(),
            ),
            pinned: true,
            floating: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, -5),
                    blurRadius: 10,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Price Section
                    _buildPriceSection(),

                    const SizedBox(height: 16),

                    // Variant Selector
                    _buildVariantSelector(),

                    // Stock Status
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Icon(
                            stock > 0
                                ? Icons.check_circle
                                : Icons.remove_circle,
                            color: stock > 0 ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            stock > 0
                                ? '$stock items available'
                                : 'Out of stock',
                            style: TextStyle(
                              color: stock > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Product Information
                    _buildProductInfoSection(),

                    // Description
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.product.description,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80), // Space for bottom bar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(stock),
    );
  }

  Widget _buildBottomBar(int stock) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 10,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: stock > 0 && !_addingToCart ? _addToCart : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: primaryGreen,
                disabledBackgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _addingToCart
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: IconButton(
              onPressed: _loadingFavorites ? null : _navigateToFavorites,
              icon: _loadingFavorites
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : primaryGreen,
                      size: 24,
                    ),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
