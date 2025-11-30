import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/models/customer_model.dart';
import 'package:firebase/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../firestore_service.dart';
import '../../services/auth_service.dart';
import '../product/product_detail_screen.dart';
import '../auth/login_screen.dart';

// Custom Animated Bottom Nav
import '../widgets/animated_bottom_nav_bar.dart';

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
  int _currentIndex = 0;

  final List<String> categories = [
    'All',
    'Sofa',
    'Chair',
    'Table',
    'Bed',
    'Electronics'
  ];

  String _selectedCategory = 'All';
  final Color primaryGreen = const Color(0xFF2C8610);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

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
          IconButton(
            icon: Icon(Icons.shopping_cart, color: primaryGreen),
            onPressed: () {
              _showGuestMessage(context, 'Shopping Cart');
            },
          ),
          // User profile menu
          if (currentUser != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.person, color: primaryGreen),
              onSelected: (value) {
                _handleMenuSelection(value, authService, context);
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: primaryGreen),
                      const SizedBox(width: 8),
                      const Text('Profile'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Logout'),
                    ],
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: Icon(Icons.login, color: primaryGreen),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(),
            _buildCategorySection(),
            const SizedBox(height: 20),
            _buildFeaturedProductsSection(),
            const SizedBox(height: 20),
            _buildProductsSection(),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  void _showGuestMessage(BuildContext context, String feature) {
    final authService = Provider.of<AuthService>(context, listen: false);

    if (authService.currentUser == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Login Required'),
            content: Text('Please login to access $feature'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text('Login'),
              ),
            ],
          );
        },
      );
    }
  }

  void _handleMenuSelection(
      String value, AuthService authService, BuildContext context) {
    switch (value) {
      case 'profile':
        _showUserProfile(context, authService);
        break;
      case 'logout':
        _showLogoutConfirmation(context, authService);
        break;
    }
  }

  void _showUserProfile(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Use the existing user data instead of fetching again
        final currentUser = authService.currentUser;

        if (currentUser == null) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text("No user is currently logged in."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          );
        }

        // Build profile using the current user data we already have
        final userModel = currentUser as UserModel?;
        return _buildProfileDialog(userModel, userModel?.email ?? 'User');
      },
    );
  }

  Widget _buildProfileDialog(UserModel? user, String displayName) {
    return AlertDialog(
      title: const Text('User Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Name'),
            subtitle: Text(displayName),
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email'),
            subtitle: Text(user?.email ?? 'Not provided'),
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Role'),
            subtitle: Text(
              user?.role.toUpperCase() ?? 'USER',
              style: TextStyle(
                color: user?.role == 'admin' ? Colors.orange : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        )
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                await authService.signOut(); // Sign out

                // Navigate to login screen and remove all previous routes
                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryGreen.withOpacity(0.2),
            primaryGreen.withOpacity(0.1)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -20,
            child: Lottie.asset(
              'assets/animations/furniture-banner.json',
              height: 250,
              width: 250,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Summer Sale',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                Text(
                  'Up to 50% off on premium furniture',
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryGreen.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Browse as Guest',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: ChoiceChip(
                  label: Text(categories[index]),
                  selected: _selectedCategory == categories[index],
                  selectedColor: primaryGreen,
                  backgroundColor: Colors.grey[200],
                  labelStyle: TextStyle(
                    color: _selectedCategory == categories[index]
                        ? Colors.white
                        : primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = categories[index];
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Featured Products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<ProductModel>>(
          stream: FirestoreService.getFeaturedProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildFeaturedShimmer();
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error loading featured products',
                    style: TextStyle(color: Colors.red)),
              );
            }

            final products = snapshot.data ?? [];
            if (products.isEmpty) {
              return const Center(child: Text('No featured products found'));
            }

            return CarouselSlider.builder(
              itemCount: products.length,
              options: CarouselOptions(
                height: 280,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.8,
              ),
              itemBuilder: (context, index, realIndex) {
                return _buildProductCard(products[index]);
              },
            );
          },
        ),
      ],
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<ProductModel>>(
          stream: FirestoreService.getProductsByCategory(_selectedCategory),
          builder: (context, snapshot) {
            print('=== STREAMBUILDER STATE ===');
            print('Connection state: ${snapshot.connectionState}');
            print('Has data: ${snapshot.hasData}');
            print('Has error: ${snapshot.hasError}');
            print('Error: ${snapshot.error}');

            if (snapshot.connectionState == ConnectionState.waiting) {
              print('StreamBuilder: Waiting for data...');
              return _buildProductsShimmer();
            }

            if (snapshot.hasError) {
              print('StreamBuilder: Error occurred - ${snapshot.error}');
              return Center(
                child: Column(
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      'Error loading products',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              print('StreamBuilder: No data available');
              return const Center(
                child: Text('No products data available'),
              );
            }

            final products = snapshot.data!;
            print('StreamBuilder: Received ${products.length} products');

            for (var product in products) {
              print('Product: ${product.name}');
              print('  - Image URL: ${product.image}');
              print('  - Price: ${product.sale_price}');
              print('  - In Stock: ${product.stock_quantity}');
            }

            if (products.isEmpty) {
              return const Center(
                child: Text('No products found in this category'),
              );
            }

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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product)),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12)),
                  image: DecorationImage(
                    image: product.image.isNotEmpty
                        ? NetworkImage(product.image)
                        : const AssetImage('assets/placeholder.png')
                            as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
                child: product.image.isEmpty
                    ? Center(
                        child: Icon(Icons.image,
                            color: Colors.grey[400], size: 40),
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.sale_price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      const SizedBox(width: 4),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedShimmer() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
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
