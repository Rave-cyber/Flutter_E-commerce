// product_detail_screen.dart
import 'dart:async';

import 'package:firebase/models/product.dart';
import 'package:firebase/models/product_variant_model.dart';
import 'package:firebase/views/customer/favorites/favorites_screen.dart';
import 'package:firebase/views/auth/login_screen.dart';
import 'package:intl/intl.dart';

import 'package:firebase/views/customer/checkout/checkout_screen.dart';
import 'package:firebase/views/customer/orders/orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase/services/auth_service.dart';
import 'package:firebase/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/services/local_cart_service.dart';
import 'package:firebase/widgets/image_slider_widget.dart';

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
  int _mainStock = 0;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _productSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _variantsSub;

  // Rating state
  int _selectedStars = 5;
  final TextEditingController _ratingController = TextEditingController();
  bool _submittingRating = false;
  bool _hasUserRated = false;
  Map<String, dynamic>? _userRating;

  List<ProductVariantModel> _variants = [];
  // Two possible selections: main product or variant
  dynamic _selectedOption; // Can be ProductModel or ProductVariantModel
  bool _isSelectingMainProduct = true; // Track if main product is selected
  String? _brandName;
  String? _categoryName;
  late Future<bool> _canRateFuture;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.product;
    _mainStock = widget.product.stock_quantity ?? 0;
    _checkIfFavorite();
    _loadProductDetails();
    _canRateFuture = _checkIfUserCanRate();
    _listenToProductStock();
  }

  @override
  void dispose() {
    _productSub?.cancel();
    _variantsSub?.cancel();
    _ratingController.dispose();
    super.dispose();
  }

  int _currentStock() {
    if (_isSelectingMainProduct) {
      return _mainStock;
    }
    if (_selectedOption is ProductVariantModel) {
      return (_selectedOption as ProductVariantModel).stock ?? 0;
    }
    return 0;
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

    final completer = Completer<void>();

    try {
      _variantsSub?.cancel();
      _variantsSub = FirebaseFirestore.instance
          .collection('product_variants')
          .where('product_id', isEqualTo: widget.product.id)
          .where('is_archived', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        final variantsList = snapshot.docs
            .map((doc) => ProductVariantModel.fromMap({
                  'id': doc.id,
                  ...doc.data(),
                }))
            .toList();

        final bool hadVariantSelected = _selectedOption is ProductVariantModel;
        final String? previousVariantId = hadVariantSelected
            ? (_selectedOption as ProductVariantModel).id
            : null;

        ProductVariantModel? updatedSelection;
        if (previousVariantId != null) {
          try {
            updatedSelection = variantsList
                .firstWhere((variant) => variant.id == previousVariantId);
          } catch (_) {
            updatedSelection =
                variantsList.isNotEmpty ? variantsList.first : null;
          }
        } else if (variantsList.isNotEmpty) {
          updatedSelection = variantsList.first;
        }

        if (mounted) {
          setState(() {
            _variants = variantsList;
            _loadingVariants = false;

            if (variantsList.isEmpty) {
              _selectedOption = widget.product;
              _isSelectingMainProduct = true;
            } else {
              // Don't auto-select variant - let user choose
              // Only update if a variant was previously selected
              if (hadVariantSelected) {
                _selectedOption = updatedSelection ?? variantsList.first;
                _isSelectingMainProduct = _selectedOption is! ProductVariantModel
                    ? true
                    : false;
              } else {
                // Keep main product selected by default
                _selectedOption = widget.product;
                _isSelectingMainProduct = true;
              }
            }

            // Safety: ensure there's always a selected option
            _selectedOption ??= widget.product;
            if (_selectedOption is! ProductVariantModel) {
              _isSelectingMainProduct = true;
            }
          });
        }

        if (!completer.isCompleted) completer.complete();
      }, onError: (error) {
        print('Error loading variants: $error');
        if (mounted) {
          setState(() {
            _loadingVariants = false;
            _selectedOption = widget.product;
            _isSelectingMainProduct = true;
          });
        }
        if (!completer.isCompleted) completer.complete();
      });
    } catch (e) {
      print('Error loading variants: $e');
      if (mounted) {
        setState(() {
          _loadingVariants = false;
          _selectedOption = widget.product;
          _isSelectingMainProduct = true;
        });
      }
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  void _listenToProductStock() {
    if (widget.product.id == null) return;

    _productSub?.cancel();
    _productSub = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.id!)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final data = doc.data();
      if (data == null) return;
      final newStock = (data['stock_quantity'] as num?)?.toInt() ?? 0;

      if (mounted) {
        setState(() {
          _mainStock = newStock;
        });
      }
    }, onError: (error) {
      print('Error listening to product stock: $error');
    });
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

    // Check if we're adding (not removing) before toggling
    final wasFavorite = _isFavorite;
    final willBeFavorite = !_isFavorite;

    try {
      await FirestoreService.toggleFavorite(user.uid, widget.product.id!);
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }

      if (mounted) {
        _showSnackBar(
          willBeFavorite ? 'Added to favorites!' : 'Removed from favorites',
          primaryGreen,
        );

        // Navigate to wishlist only when ADDING to favorites (not removing)
        if (willBeFavorite && !wasFavorite) {
          // Wait a bit to ensure the favorite is saved, then navigate
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            _navigateToFavorites();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating favorites', Colors.red);
      }
    }
  }

  void _addToCart() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    // if (user == null) {
    //   _showSnackBar('Please login to add to cart', Colors.orange);
    //   return;
    // }
    // ALLOW GUEST ADD TO CART

    if (widget.product.id == null) {
      _showSnackBar('Product error', Colors.red);
      return;
    }

    // Use the currently selected option (main product or variant)
    dynamic selectedOption = _selectedOption;
    bool isSelectingMain = _isSelectingMainProduct;

    // Determine stock based on selected option (live)
    int stock;
    if (isSelectingMain) {
      stock = _mainStock;
    } else if (selectedOption is ProductVariantModel) {
      stock = selectedOption.stock ?? 0;
    } else {
      stock = 0;
    }

    if (stock <= 0) {
      _showSnackBar('Cannot add to cart: This item is out of stock', Colors.red);
      return;
    }

    setState(() {
      _addingToCart = true;
    });

    try {
      String productName;
      String productImage;
      double price;

      String? variantId;
      if (isSelectingMain) {
        // Buying main product
        productName = widget.product.name;
        productImage = widget.product.image;
        price = widget.product.sale_price;
      } else {
        // Buying variant - show only variant name
        final variant = selectedOption as ProductVariantModel;
        productName = variant.name; // Show only variant name
        productImage =
            variant.image.isNotEmpty ? variant.image : widget.product.image;
        price = variant.sale_price;
        variantId = variant.id;
      }

      if (user != null) {
        await FirestoreService.addToCart(
          userId: user.uid,
          productId: widget.product.id!, // Always use original product ID
          productName: productName,
          productImage: productImage,
          price: price,
          quantity: 1, // Default quantity to 1
          variantId: variantId, // Pass variantId if it's a variant
        );
      } else {
        // Guest Cart
        final cartItem = {
          'productId': widget.product.id!, // Always use original product ID
          'productName': productName,
          'productImage': productImage,
          'price': price,
          'quantity': 1,
        };
        if (variantId != null) {
          cartItem['variantId'] = variantId;
        }
        await LocalCartService.addToCart(cartItem);
      }

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

  void _buyNow() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    if (user == null) {
      // For Buy Now, we should probably redirect to Login immediately because Checkout requires login
      // User said "when purchase direct to the log in"
      // So _buyNow IS a purchase intent.
      // We can add to cart then redirect to Login?
      // Or just redirect.
      // Let's Add to Local Cart then Redirect to Login?
      // Actually, let's keep it simple: Redirect to Login/Checkout.
      // But we need to add the item first so they don't lose it.
    }

    if (widget.product.id == null) {
      _showSnackBar('Product error', Colors.red);
      return;
    }

    // Use the currently selected option (main product or variant)
    dynamic selectedOption = _selectedOption;
    bool isSelectingMain = _isSelectingMainProduct;

    // Determine stock based on selected option (live)
    int stock;
    if (isSelectingMain) {
      stock = _mainStock;
    } else if (selectedOption is ProductVariantModel) {
      stock = selectedOption.stock ?? 0;
    } else {
      stock = 0;
    }

    if (stock <= 0) {
      _showSnackBar('Cannot proceed: This item is out of stock', Colors.red);
      return;
    }

    setState(() {
      _addingToCart = true;
    });

    try {
      String productName;
      String productImage;
      double price;

      String? variantId;
      if (isSelectingMain) {
        // Buying main product
        productName = widget.product.name;
        productImage = widget.product.image;
        price = widget.product.sale_price;
      } else {
        // Buying variant - show only variant name
        final variant = selectedOption as ProductVariantModel;
        productName = variant.name; // Show only variant name
        productImage =
            variant.image.isNotEmpty ? variant.image : widget.product.image;
        price = variant.sale_price;
        variantId = variant.id;
      }

      // Add to cart first
      if (user != null) {
        await FirestoreService.addToCart(
          userId: user.uid,
          productId: widget.product.id!, // Always use original product ID
          productName: productName,
          productImage: productImage,
          price: price,
          quantity: 1,
          variantId: variantId, // Pass variantId if it's a variant
        );
      } else {
        final cartItem = {
          'productId': widget.product.id!, // Always use original product ID
          'productName': productName,
          'productImage': productImage,
          'price': price,
          'quantity': 1,
        };
        if (variantId != null) {
          cartItem['variantId'] = variantId;
        }
        await LocalCartService.addToCart(cartItem);
      }

      // Navigate directly to checkout
      if (mounted) {
        // Navigate directly to checkout
        if (mounted) {
          if (user != null) {
            // Use variantId as document ID if it exists, otherwise use productId
            final cartItemId = variantId ?? widget.product.id!;
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CheckoutScreen(
                  cartItems: [
                    {
                      'productId': widget.product.id!,
                      'productName': productName,
                      'productImage': productImage,
                      'price': price,
                      'quantity': 1,
                    }
                  ],
                  isSelectedItems: false,
                  selectedItemIds: [cartItemId],
                ),
              ),
            );
          } else {
            // If guest, go to Login
            _showSnackBar('Please login to continue checkout', Colors.orange);
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      const LoginScreen()), // Use fully qualified if needed or add import
            ).then((_) {
              // Maybe verify login?
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e', Colors.red);
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
        'Check out ${widget.product.name} for ₱${widget.product.sale_price.toStringAsFixed(2)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share: $shareText'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildImageCarousel() {
    List<String> images = [];

    if (_isSelectingMainProduct) {
      // Use multiple images if available, otherwise fallback to single image
      if (widget.product.images != null && widget.product.images!.isNotEmpty) {
        images = widget.product.images!;
      } else if (widget.product.image.isNotEmpty) {
        images = [widget.product.image];
      }
    } else if (_selectedOption is ProductVariantModel) {
      final variant = _selectedOption as ProductVariantModel;
      // Use multiple images if available, otherwise fallback to single image or main product image
      if (variant.images != null && variant.images!.isNotEmpty) {
        images = variant.images!;
      } else if (variant.image.isNotEmpty) {
        images = [variant.image];
      } else if (widget.product.image.isNotEmpty) {
        images = [widget.product.image];
      }
    }

    return Stack(
      children: [
        ImageSliderWidget(
          images: images,
          height: 420,
          primaryColor: primaryGreen,
        ),
        _buildOverlayButtons(),
      ],
    );
  }

  Widget _buildImageCarouselOld() {
    String imageUrl = '';

    if (_isSelectingMainProduct) {
      imageUrl = widget.product.image;
    } else if (_selectedOption is ProductVariantModel) {
      final variant = _selectedOption as ProductVariantModel;
      imageUrl =
          variant.image.isNotEmpty ? variant.image : widget.product.image;
    }

    if (imageUrl.isEmpty) {
      return Container(
        height: 420,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[200]!, Colors.grey[100]!],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            size: 80,
            color: Colors.grey[400],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 420,
          color: Colors.black,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey[300]!, Colors.grey[200]!],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: primaryGreen,
                ),
              );
            },
          ),
        ),
        _buildOverlayButtons(),
      ],
    );
  }

  Widget _buildOverlayButtons() {
    return Stack(
      children: [
        // Modern favorite button with animation
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.grey[700],
                size: 26,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
        ),

        // Share button
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 76,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.share_outlined,
                color: Colors.grey[700],
                size: 22,
              ),
              onPressed: _shareProduct,
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

    final discountPercent = originalPrice > price
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 0;
    final stock = _currentStock();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryGreen.withOpacity(0.05), Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sale price
                Text(
                  '₱${NumberFormat('#,##0.00').format(price)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                    height: 1.2,
                  ),
                ),
                // Original price (crossed out) if there's a discount
                if (originalPrice > price)
                  Text(
                    '₱${NumberFormat('#,##0.##').format(originalPrice)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                      decoration: TextDecoration.lineThrough,
                      height: 1.2,
                    ),
                  ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 18, color: Colors.grey[700]),
                        const SizedBox(width: 6),
                        Text(
                          stock > 0 ? '$stock in stock' : 'Out of stock',
                          style: TextStyle(
                            fontSize: 13,
                            color: stock > 0 ? Colors.grey[700] : Colors.red,
                            fontWeight:
                                stock > 0 ? FontWeight.w600 : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
          if (discountPercent > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '-$discountPercent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
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

    // Only show variants when they exist
    if (_variants.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style_outlined, size: 18, color: primaryGreen),
              const SizedBox(width: 8),
              Text(
                'Select Option',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Original Product Option
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedOption = widget.product;
                    _isSelectingMainProduct = true;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: _isSelectingMainProduct
                        ? LinearGradient(
                            colors: [
                              primaryGreen,
                              primaryGreen.withOpacity(0.8)
                            ],
                          )
                        : null,
                    color: _isSelectingMainProduct ? null : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSelectingMainProduct ? primaryGreen : Colors.grey[300]!,
                      width: _isSelectingMainProduct ? 2 : 1,
                    ),
                    boxShadow: _isSelectingMainProduct
                        ? [
                            BoxShadow(
                              color: primaryGreen.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    'Original',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isSelectingMainProduct ? Colors.white : Colors.grey[800],
                      fontWeight:
                          _isSelectingMainProduct ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Variant Options
              ...List.generate(_variants.length, (index) {
                final variant = _variants[index];
                final isSelected = (_selectedOption is ProductVariantModel &&
                    variant.id == (_selectedOption as ProductVariantModel).id);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOption = variant;
                      _isSelectingMainProduct = false;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                primaryGreen,
                                primaryGreen.withOpacity(0.8)
                              ],
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? primaryGreen : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryGreen.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          variant.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoSection() {
    if (_loadingBrandCategory) {
      return const Center(child: CircularProgressIndicator());
    }

    // Get stock based on selected option
    final stock = _currentStock();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: primaryGreen),
              const SizedBox(width: 8),
              Text(
                'Product Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Info grid
          Row(
            children: [
              Expanded(
                child: _buildModernInfoCard(
                  icon: Icons.sell_outlined,
                  label: 'Brand',
                  value: _brandName ?? 'No brand',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernInfoCard(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: _categoryName ?? 'No category',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModernInfoCard(
                  icon: Icons.verified_outlined,
                  label: 'Status',
                  value: widget.product.is_archived ? 'Archived' : 'Active',
                  valueColor:
                      widget.product.is_archived ? Colors.orange : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModernInfoCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Stock',
                  value: stock > 0 ? '$stock available' : 'Out of stock',
                  valueColor: stock > 0 ? primaryGreen : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primaryGreen.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.grey[800],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating() async {
    final authUser =
        Provider.of<AuthService>(context, listen: false).currentUser;
    if (authUser == null) {
      _showSnackBar('Please login to submit a rating', Colors.orange);
      return;
    }

    if (widget.product.id == null || widget.product.id!.isEmpty) {
      _showSnackBar('Product error', Colors.red);
      return;
    }

    setState(() {
      _submittingRating = true;
    });

    try {
      await FirestoreService.addOrUpdateProductRating(
        productId: widget.product.id!,
        userId: authUser.uid,
        stars: _selectedStars,
        comment: _ratingController.text.trim(),
      );

      final activated = await FirestoreService.hasUserDeliveredOrderForProduct(
          authUser.uid, widget.product.id!);

      if (mounted) {
        _showSnackBar(
          activated
              ? 'Thanks! Your rating is now active.'
              : 'Thanks! Your rating will be activated after delivery.',
          primaryGreen,
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error submitting rating', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _submittingRating = false;
        });
      }
    }
  }

  Widget _buildRatingsSection() {
    final productId = widget.product.id ?? '';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, size: 22, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Ratings & Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Average + count (activated ratings only)
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService.getProductRatingsStream(productId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final ratings = snapshot.data!;
              final count = ratings.length;
              final avg = count > 0
                  ? (ratings
                          .map((r) => (r['stars'] as num).toDouble())
                          .reduce((a, b) => a + b) /
                      count)
                  : 0.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern rating summary card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.amber.withOpacity(0.1),
                          Colors.orange.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Rating number
                        Column(
                          children: [
                            Text(
                              avg.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[700],
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  Icons.star_rounded,
                                  color: i < avg.round()
                                      ? Colors.amber
                                      : Colors.grey[300],
                                  size: 20,
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$count ${count == 1 ? "review" : "reviews"}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        // Rating bars (optional - can be added later)
                        Expanded(
                          child: Column(
                            children: ratings.isEmpty
                                ? [
                                    Text(
                                      'No reviews yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ]
                                : [
                                    Text(
                                      'Be the first to share your experience!',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reviews list header
                  if (ratings.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customer Reviews',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Modern review cards
                        ...ratings
                            .take(3)
                            .map((r) => _buildModernReviewCard(r)),
                        if (ratings.length > 3)
                          TextButton(
                            onPressed: () {
                              // Could navigate to full reviews page
                              _showSnackBar(
                                  'View all reviews feature coming soon',
                                  primaryGreen);
                            },
                            child: Text(
                              'View all ${ratings.length} reviews',
                              style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Check if user can rate
          FutureBuilder<bool>(
            future: _canRateFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: SizedBox(
                        height: 50,
                        child: CircularProgressIndicator(strokeWidth: 2)));
              }

              final user = Provider.of<AuthService>(context).currentUser;
              final canRate = snapshot.data ?? false;
              final isLoggedIn = user != null;

              // If user is not logged in, show login prompt
              if (!isLoggedIn) {
                return _buildLoginToRateSection();
              }

              // If user is logged in but hasn't ordered/delivered
              if (!canRate) {
                return _buildCannotRateSection();
              }

              // User can rate - show rating form
              return _buildRatingForm();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernReviewCard(Map<String, dynamic> review) {
    final stars = (review['stars'] ?? 0) as int;
    final comment = (review['comment'] ?? '') as String;
    final ts = review['createdAt'] as Timestamp?;
    final date = ts != null ? ts.toDate() : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User avatar placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGreen, primaryGreen.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Customer',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.verified, size: 16, color: primaryGreen),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: i < stars ? Colors.amber : Colors.grey[300],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              if (date != null)
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
          if (comment.isNotEmpty) const SizedBox(height: 12),
          if (comment.isNotEmpty)
            Text(
              comment,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> _checkIfUserCanRate() async {
    final authUser =
        Provider.of<AuthService>(context, listen: false).currentUser;

    if (authUser == null) {
      return false;
    }

    if (widget.product.id == null || widget.product.id!.isEmpty) {
      return false;
    }

    try {
      // Check if user has delivered order for this product
      final canRate = await FirestoreService.hasUserDeliveredOrderForProduct(
        authUser.uid,
        widget.product.id!,
      );

      // Also check if user has already rated this product
      final existingRating = await FirestoreService.getUserRatingForProduct(
        authUser.uid,
        widget.product.id!,
      );

      if (mounted) {
        setState(() {
          _hasUserRated = existingRating != null;
          _userRating = existingRating;
          if (existingRating != null) {
            _selectedStars = existingRating['stars'] ?? 5;
            _ratingController.text = existingRating['comment'] ?? '';
          }
        });
      }

      return canRate;
    } catch (e) {
      print('Error checking if user can rate: $e');
      return false;
    }
  }

  Widget _buildLoginToRateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.orange[800]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Login to Rate',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please login to submit your rating for this product',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // You'll need to implement navigation to login screen
            _showSnackBar('Please login to continue', Colors.orange);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 20),
              SizedBox(width: 8),
              Text('Login to Rate'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCannotRateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primaryGreen.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.shopping_bag, color: primaryGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchase Required',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rate this product after your order is delivered',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Opacity(
          opacity: 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Leave a rating',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    Icons.star,
                    color: Colors.grey[300],
                    size: 30,
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                enabled: false,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write a comment (optional)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: null, // Disabled
                      style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                      ),
                      child: Text(
                        'Submit Rating',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _hasUserRated ? 'Edit your rating' : 'Leave a rating',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        if (_hasUserRated)
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.amber[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You have already rated this product. You can update your rating below.',
                    style: TextStyle(
                      color: Colors.amber[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) {
            return IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _selectedStars = i + 1;
                });
              },
              icon: Icon(
                Icons.star,
                color: i < _selectedStars ? Colors.amber : Colors.grey[300],
                size: 30,
              ),
            );
          }),
        ),
        TextField(
          controller: _ratingController,
          maxLines: 3,
          style: TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: 'Write a comment (optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _submittingRating ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: primaryGreen,
                  disabledBackgroundColor: Colors.grey,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: _submittingRating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Text(
                        _hasUserRated ? 'Update Rating' : 'Submit Rating',
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.check_circle, color: primaryGreen, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Your order was delivered. You can rate this product now.',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get stock based on selected option (live)
    final stock = _currentStock();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildImageCarousel(),
            ),
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: primaryGreen),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back, color: primaryGreen),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      widget.product.name,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: Colors.grey[900],
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price Section
                    _buildPriceSection(),

                    // Variant Selector
                    _buildVariantSelector(),

                    // Product Information
                    _buildProductInfoSection(),

                    // Description
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 20, color: primaryGreen),
                              const SizedBox(width: 8),
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.product.description,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.7,
                              color: Colors.grey[700],
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Ratings Section
                    _buildRatingsSection(),

                    const SizedBox(height: 100), // Space for bottom bar
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
          // Cart Icon Button (small, outlined)
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryGreen,
                width: 2,
              ),
            ),
            child: IconButton(
              onPressed: stock > 0 && !_addingToCart ? _addToCart : null,
              icon: _addingToCart
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    )
                  : const Icon(Icons.shopping_cart_outlined),
              color: primaryGreen,
              disabledColor: Colors.grey,
              splashRadius: 20,
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 12),

          // Buy Now Button (big, green, full width)
          Expanded(
            child: ElevatedButton(
              onPressed: stock > 0 && !_addingToCart ? _buyNow : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: primaryGreen,
                disabledBackgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                shadowColor: primaryGreen.withOpacity(0.3),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flash_on, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Buy Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}