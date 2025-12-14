import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/models/customer_model.dart';
import 'package:firebase/models/user_model.dart';
import 'package:firebase/views/customer/cart/cart_screen.dart';
import 'package:firebase/views/customer/orders/orders_screen.dart';
import 'package:firebase/views/widgets/animated_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/product.dart';
import '../../models/category_model.dart';
import '../../firestore_service.dart';
import '../../services/navigation_service.dart';
import '../../services/customer/category_service.dart';
import '../customer/product/product_detail_screen.dart';
import '../customer/categories/categories_screen.dart';
import '../customer/favorites/favorites_screen.dart';
import '../customer/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  final CustomerModel? customer;

  const HomeScreen({
    Key? key,
    required this.user,
    this.customer,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NavigationService _navService = NavigationService();

  String _selectedCategory = 'All';
  final Color primaryGreen = const Color(0xFF2C8610);
  int _currentBannerIndex = 0;

  // Banner data with online images for furniture and appliances
  // Dynamic banners loaded from Firestore

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    final screens = [
      _buildHomeContent(), // Home content
      CategoriesScreen(user: widget.user),
      FavoritesScreen(user: widget.user),
      ProfileScreen(user: widget.user, customer: widget.customer),
    ];

    _navService.initializeScreens(screens);
  }

  void _onTabTapped(int index) {
    setState(() {
      _navService.changeScreen(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Dimdi Home',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: primaryGreen),
            onPressed: () {},
          ),
          // Orders with Badge
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirestoreService.getUserOrders(widget.user.id),
            builder: (context, snapshot) {
              final orderCount = snapshot.data?.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.receipt_long, color: primaryGreen),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrdersScreen(),
                        ),
                      );
                    },
                    tooltip: 'Order History',
                  ),
                  if (orderCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$orderCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Cart with Badge
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.getCartStream(widget.user.id),
            builder: (context, snapshot) {
              final cartCount = snapshot.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart, color: primaryGreen),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CartScreen()),
                      );
                    },
                    tooltip: 'Shopping Cart',
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _navService.currentScreen,
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _navService.currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroBanner(),
          const SizedBox(height: 20),
          _buildProductsSection(),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getBanners(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final banners = snapshot.data ?? [];
        if (banners.isEmpty) return const SizedBox();

        return Column(
          children: [
            CarouselSlider(
              items: banners.map((banner) {
                return _buildBannerItem(banner);
              }).toList(),
              options: CarouselOptions(
                height: 200,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                viewportFraction: 0.9,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                },
              ),
            ),
            const SizedBox(height: 10),
            _buildBannerIndicator(banners.length),
          ],
        );
      },
    );
  }

  Widget _buildBannerItem(Map<String, dynamic> banner) {
    return GestureDetector(
      onTap: () {
        if (banner['categoryId'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoriesScreen(
                user: widget.user,
                initialCategoryId: banner['categoryId'],
              ),
            ),
          );
        } else {
          // Default behavior: go to Categories tab
          _onTabTapped(1);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image
              Image.network(
                banner['image'],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  );
                },
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Content - with constrained height and padding
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0, // Take full height but with proper constraints
                child: Padding(
                  padding: const EdgeInsets.all(16.0), // Reduced padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title with max lines
                      Text(
                        banner['title'],
                        style: const TextStyle(
                          fontSize: 20, // Slightly smaller font
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6), // Reduced spacing
                      // Subtitle with max lines
                      Text(
                        banner['subtitle'],
                        style: const TextStyle(
                          fontSize: 14, // Slightly smaller font
                          color: Colors.white,
                        ),
                        maxLines: 2, // Allow 2 lines for subtitle
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12), // Reduced spacing
                      // Button
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, // Reduced padding
                          vertical: 8, // Reduced padding
                        ),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          banner['buttonText'],
                          style: const TextStyle(
                            fontSize: 12, // Smaller font
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primaryGreen.withOpacity(
              _currentBannerIndex == index ? 1.0 : 0.4,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Products',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<ProductModel>>(
          stream: FirestoreService.getProductsByCategory(_selectedCategory),
          builder: (context, snapshot) {
            // Keep previous data visible while loading to prevent blinking
            final products = snapshot.data ?? [];

            if (snapshot.hasError && products.isEmpty) {
              return Center(
                child: Column(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      'Error loading products',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            if (products.isEmpty &&
                snapshot.connectionState != ConnectionState.waiting) {
              return const Center(
                child: Text('No products found in this category'),
              );
            }

            // Show products with a subtle loading overlay if still loading
            return Stack(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(products[index]);
                  },
                ),
                // Show loading overlay only if no products yet and still loading
                if (snapshot.connectionState == ConnectionState.waiting &&
                    products.isEmpty)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withOpacity(0.9),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    // Calculate discount percentage outside widget tree
    final hasDiscount = product.base_price > product.sale_price;
    final discountPercent = hasDiscount
        ? ((product.base_price - product.sale_price) / product.base_price * 100)
            .toStringAsFixed(0)
        : '0';
    final discountValue = hasDiscount ? int.parse(discountPercent) : 0;
    final showDiscountBadge = hasDiscount && discountValue > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product)),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: Colors.black.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: product.image.isNotEmpty
                        ? NetworkImage(product.image)
                        : const AssetImage('assets/placeholder.png')
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    if (product.image.isEmpty)
                      Center(
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                      ),
                    // Discount badge - top left
                    if (showDiscountBadge)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red,
                                Colors.red.shade700,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Price
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '\$${product.sale_price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (product.base_price > product.sale_price)
                        Text(
                          '\$${product.base_price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),

                  // Rating
                  const SizedBox(height: 8),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream:
                        FirestoreService.getProductRatingsStream(product.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Row(
                          children: [
                            Row(
                              children: List.generate(
                                  5,
                                  (i) => Icon(Icons.star,
                                      color: Colors.grey[300], size: 14)),
                            ),
                            const SizedBox(width: 4),
                            Text('0.0',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 2),
                            Text('(0)',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        );
                      }

                      final ratings = snapshot.data!;
                      final count = ratings.length;
                      final avg = count > 0
                          ? (ratings
                                  .map((r) => (r['stars'] as num).toDouble())
                                  .reduce((a, b) => a + b) /
                              count)
                          : 0.0;

                      return Row(
                        children: [
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                Icons.star,
                                color: i < avg.round()
                                    ? Colors.amber
                                    : Colors.grey[300],
                                size: 14,
                              );
                            }),
                          ),
                          const SizedBox(width: 4),
                          Text(avg.toStringAsFixed(1),
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 2),
                          Text('(${count.toString()})',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      );
                    },
                  ),

                  // Stock indicator
                  const SizedBox(height: 6),
                  if (product.stock_quantity! > 0)
                    Text(
                      'In Stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Text(
                      'Out of Stock',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
