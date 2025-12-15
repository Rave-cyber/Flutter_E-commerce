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
import '../../services/local_cart_service.dart';
import '../customer/product/product_detail_screen.dart';
import '../customer/categories/categories_screen.dart';
import '../customer/favorites/favorites_screen.dart';
import '../customer/profile/profile_screen.dart';
import '../customer/search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel? user;
  final CustomerModel? customer;

  const HomeScreen({
    Key? key,
    this.user,
    this.customer,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NavigationService _navService = NavigationService();
  String _selectedCategory = 'All';
  final Color primaryGreen = const Color(0xFF2C8610);
  final Color accentGreen = const Color(0xFF4CAF50);
  final Color lightGreen = const Color(0xFFE8F5E9);
  int _currentBannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    final screens = [
      _buildHomeContent(),
      CategoriesScreen(user: widget.user),
      widget.user != null
          ? FavoritesScreen(user: widget.user!)
          : const Center(child: Text('Please Login to view Favorites')),
      widget.user != null
          ? ProfileScreen(user: widget.user!, customer: widget.customer)
          : const Center(child: Text('Please Login to view Profile')),
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
      appBar: _buildAppBar(),
      body: _navService.currentScreen,
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _navService.currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'DIMDI Store',
        style: TextStyle(
          color: primaryGreen,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Notification Icon

        // Orders Icon with dynamic badge
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: widget.user != null
              ? FirestoreService.getUserOrders(widget.user!.id)
              : const Stream.empty(),
          builder: (context, snapshot) {
            final orderCount = snapshot.data?.length ?? 0;
            return _buildActionButton(
              Icons.receipt_long_outlined,
              'My Orders',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrdersScreen(),
                  ),
                );
              },
              showBadge: orderCount > 0,
              badgeCount: orderCount,
            );
          },
        ),
        const SizedBox(width: 4),

        // Cart Icon with dynamic badge
        StreamBuilder<int>(
          stream: widget.user != null
              ? FirestoreService.getCartStream(widget.user!.id)
                  .map((snapshot) => snapshot.docs.length)
              : LocalCartService.getCartStream().map((items) => items.length),
          builder: (context, snapshot) {
            final cartCount = snapshot.data ?? 0;
            return _buildActionButton(
              Icons.shopping_cart_outlined,
              'Shopping Cart',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CartScreen(),
                  ),
                );
              },
              showBadge: cartCount > 0,
              badgeCount: cartCount,
            );
          },
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String tooltip, {
    required VoidCallback onPressed,
    bool showBadge = false,
    int badgeCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lightGreen,
      ),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(icon, color: primaryGreen),
            onPressed: onPressed,
            tooltip: tooltip,
          ),
          if (showBadge)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          _buildSearchBar(),
          const SizedBox(height: 16),

          // Hero Banner Carousel
          _buildHeroBanner(),
          const SizedBox(height: 24),

          // Categories Section
          _buildCategoriesSection(),
          const SizedBox(height: 24),

          // Featured Products Section
          _buildFeaturedProductsSection(),
          const SizedBox(height: 24),

          // All Products Section
          _buildProductsSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SearchScreen(),
            ),
          );
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.search,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search for products...',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryGreen,
                ),
                child: Icon(
                  Icons.filter_list,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getBanners(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildBannerShimmer();
        }

        final banners = snapshot.data ?? [];
        if (banners.isEmpty) return _buildDefaultBanner();

        return Column(
          children: [
            CarouselSlider(
              items: banners.map((banner) {
                return _buildBannerCard(banner);
              }).toList(),
              options: CarouselOptions(
                height: 160,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                viewportFraction: 0.85,
                autoPlayInterval: const Duration(seconds: 5),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentBannerIndex = index;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildBannerIndicator(banners.length),
          ],
        );
      },
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> banner) {
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
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
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
                    child: Center(
                      child: Icon(Icons.error, color: Colors.grey[400]),
                    ),
                  );
                },
              ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      banner['title'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      banner['subtitle'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        banner['buttonText'] ?? 'Shop Now',
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _currentBannerIndex == index ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: primaryGreen.withOpacity(
              _currentBannerIndex == index ? 1.0 : 0.4,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildBannerShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryGreen, accentGreen],
        ),
      ),
      child: const Center(
        child: Text(
          'Welcome to Dimdi Home',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
              GestureDetector(
                onTap: () => _onTabTapped(1),
                child: Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 14,
                    color: primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: StreamBuilder<List<CategoryModel>>(
            stream: CustomerCategoryService().getActiveCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildCategoriesShimmer();
              }

              final categories = snapshot.data ?? [];
              if (categories.isEmpty) return const SizedBox();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return _buildCategoryItem(categories[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(CategoryModel category) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category.name),
        selected: false,
        selectedColor: primaryGreen,
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: primaryGreen,
          fontWeight: FontWeight.bold,
        ),
        onSelected: (selected) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoriesScreen(
                user: widget.user,
                initialCategoryId: category.id,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 12,
                  color: Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedProductsSection() {
    return StreamBuilder<List<ProductModel>>(
      stream: FirestoreService.getFeaturedProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        if (products.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Trending',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return _buildFeaturedProductCard(products[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedProductCard(ProductModel product) {
    double discountVal = 0;
    if (product.base_price > product.sale_price) {
      discountVal =
          ((product.base_price - product.sale_price) / product.base_price) *
              100;
    }
    final hasDiscount = discountVal >= 1;
    final discountPercent = discountVal.toStringAsFixed(0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                image: product.image.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(product.image),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: product.image.isEmpty ? Colors.grey[100] : null,
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
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-$discountPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Product Details
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.sale_price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryGreen,
                    ),
                  ),
                  if (hasDiscount)
                    Text(
                      '\$${product.base_price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
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

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'All Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<ProductModel>>(
          stream: FirestoreService.getProductsByCategory(_selectedCategory),
          builder: (context, snapshot) {
            final products = snapshot.data ?? [];

            if (snapshot.connectionState == ConnectionState.waiting &&
                products.isEmpty) {
              return _buildProductsShimmer();
            }

            if (products.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No products found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildProductCard(ProductModel product) {
    double discountVal = 0;
    if (product.base_price > product.sale_price) {
      discountVal =
          ((product.base_price - product.sale_price) / product.base_price) *
              100;
    }
    final hasDiscount = discountVal >= 1;
    final discountPercent = discountVal.toStringAsFixed(0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  image: product.image.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(product.image),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: product.image.isEmpty ? Colors.grey[100] : null,
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
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-$discountPercent%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
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
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\₱${product.sale_price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryGreen,
                      ),
                    ),
                    if (hasDiscount)
                      Text(
                        '\₱${product.base_price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    _buildRatingRow(product),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(ProductModel product) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getProductRatingsStream(product.id),
      builder: (context, snapshot) {
        final ratings = snapshot.data ?? [];
        double avg = 0;
        if (ratings.isNotEmpty) {
          avg = ratings
                  .map((r) => (r['stars'] as num?)?.toDouble() ?? 0)
                  .fold<double>(0, (a, b) => a + b) /
              ratings.length;
        }

        final display = ratings.isEmpty ? 'New' : avg.toStringAsFixed(1);

        return Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 14),
            const SizedBox(width: 4),
            Text(
              display,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            if (ratings.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                '(${ratings.length})',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
            const Spacer(),
            Icon(
              product.stock_quantity! > 0
                  ? Icons.check_circle_outline
                  : Icons.remove_circle_outline,
              color: product.stock_quantity! > 0 ? Colors.green : Colors.red,
              size: 14,
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductsShimmer() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}
