import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../models/customer_model.dart';
import '../../../models/product.dart';
import '../../../services/auth_service.dart';
<<<<<<< HEAD
=======
import '../../../firestore_service.dart';
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
import '../../auth/login_screen.dart';
import '../product/product_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final UserModel? user;
  final CustomerModel? customer;

  const FavoritesScreen({
    Key? key,
    this.user,
    this.customer,
  }) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final Color primaryGreen = const Color(0xFF2C8610);
<<<<<<< HEAD
=======
  String _selectedCategoryId = 'All';
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return _buildGuestView();
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        title: Text(
          'My Wishlist',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
      ),
      body: _buildFavoritesContent(),
    );
  }

  Widget _buildGuestView() {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        title: Text(
          'Wishlist',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Please login to view your wishlist',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesContent() {
    final currentUser = Provider.of<AuthService>(context).currentUser;

    if (currentUser == null) {
      return _buildGuestView();
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('favorites')
          .orderBy('addedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'productId': doc['productId'],
            'addedAt': doc['addedAt'],
          };
        }).toList();
      }).handleError((error) {
        print('Error fetching user favorites: $error');
        return Stream.value(<Map<String, dynamic>>[]);
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 50),
                const SizedBox(height: 10),
                Text(
                  'Error loading favorites',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final favorites = snapshot.data ?? [];

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'No favorites yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Start adding products to your wishlist',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<List<ProductModel?>>(
          future: _fetchFavoriteProducts(favorites),
          builder: (context, productSnapshot) {
            if (productSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 10),
                    Text(
                      'Error loading products',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final products = productSnapshot.data
                    ?.where((p) => p != null)
                    .cast<ProductModel>()
                    .toList() ??
                [];

            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No favorites available',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

<<<<<<< HEAD
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(products[index]);
              },
=======
            final filtered = _selectedCategoryId == 'All'
                ? products
                : products
                    .where((p) => p.category_id == _selectedCategoryId)
                    .toList();

            if (filtered.isEmpty) {
              return Column(
                children: [
                  _buildCategoryFilter(),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_list, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No favorites in this category',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildCategoryFilter(),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildProductCard(filtered[index]);
                    },
                  ),
                ),
              ],
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
            );
          },
        );
      },
    );
  }

  Future<List<ProductModel?>> _fetchFavoriteProducts(
      List<Map<String, dynamic>> favorites) async {
    final productIds = favorites.map((f) => f['productId'] as String).toList();
    final products = <ProductModel?>[];

    for (final productId in productIds) {
      try {
        final product = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
        if (product.exists && !(product.data()?['is_archived'] ?? false)) {
          products.add(ProductModel.fromMap({
            'id': product.id,
            ...product.data()!,
          }));
        } else {
          products.add(null); // Product not found or archived
        }
      } catch (e) {
        print('Error fetching product $productId: $e');
        products.add(null);
      }
    }

    return products;
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
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
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  color: Colors.grey[200],
                ),
                child: product.image.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderIcon();
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: primaryGreen,
                              ),
                            );
                          },
                        ),
                      )
                    : _buildPlaceholderIcon(),
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
<<<<<<< HEAD
                        '\$${product.sale_price.toStringAsFixed(2)}',
=======
                        '\₱${product.sale_price.toStringAsFixed(2)}',
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryGreen,
                        ),
                      ),
                      if (product.base_price > product.sale_price) ...[
                        const SizedBox(width: 8),
                        Text(
<<<<<<< HEAD
                          '\$${product.base_price.toStringAsFixed(2)}',
=======
                          '\₱${product.base_price.toStringAsFixed(2)}',
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (product.stock_quantity! < 5 &&
                      product.stock_quantity! > 0)
                    Text(
                      'Only ${product.stock_quantity} left',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
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

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey[400],
        size: 40,
      ),
    );
  }
<<<<<<< HEAD
=======

  Widget _buildCategoryFilter() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreService.getAllCategories(),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? [];
        final options = [
          {'id': 'All', 'name': 'All'},
          ...categories.map((c) => {
                'id': c['id'] ?? '',
                'name': c['name'] ?? 'Unnamed',
              }),
        ];

        return SizedBox(
          height: 56,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final cat = options[index];
              final isSelected = cat['id'] == _selectedCategoryId;
              return ChoiceChip(
                label: Text(cat['name']),
                selected: isSelected,
                selectedColor: primaryGreen.withOpacity(0.15),
                labelStyle: TextStyle(
                  color: isSelected ? primaryGreen : Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) {
                  setState(() {
                    _selectedCategoryId = cat['id'] as String;
                  });
                },
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? primaryGreen : Colors.grey[300]!,
                ),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: options.length,
          ),
        );
      },
    );
  }
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
}
