import 'package:firebase/models/category_model.dart';
import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../../../models/product.dart';
import '../../../firestore_service.dart';
import '../../../services/customer/category_service.dart';
import '../product/product_detail_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final UserModel user;

  const CategoriesScreen({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _selectedCategory = 'All';
  final Color primaryGreen = const Color(0xFF2C8610);
  late CustomerCategoryService _categoryService;
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _categoryService = CustomerCategoryService();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoryService.getActiveCategories().first;
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Categories',
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
            icon: Icon(Icons.refresh, color: primaryGreen),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Chips
          _buildCategoryChips(),
          Expanded(
            child: _buildProductsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    // Add "All" option
    final allCategories = [
      CategoryModel(
        id: 'all',
        name: 'All',
        is_archived: false,
        created_at: null,
        updated_at: null,
      ),
      ..._categories
    ];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allCategories.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemBuilder: (context, index) {
          final category = allCategories[index];
          final isSelected = _selectedCategory == category.id;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category.name),
              selected: isSelected,
              selectedColor: primaryGreen,
              backgroundColor: Colors.grey[200],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : primaryGreen,
                fontWeight: FontWeight.bold,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category.id;
                  });
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsGrid() {
    return StreamBuilder<List<ProductModel>>(
      stream: FirestoreService.getProductsByCategory(_selectedCategory),
      builder: (context, snapshot) {
        // Show loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid();
        }

        // Show error
        if (snapshot.hasError) {
          print('Products error: ${snapshot.error}');
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
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                  ),
                ),
              ],
            ),
          );
        }

        // Check data
        final products = snapshot.data ?? [];
        print('Products loaded: ${products.length}');

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: Colors.grey[400], size: 60),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _selectedCategory == 'all'
                      ? 'in any category'
                      : 'in this category',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'all';
                    });
                  },
                  child: Text('Show All Products'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
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
    );
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
                      if (product.base_price > product.sale_price) ...[
                        const SizedBox(width: 8),
                        Text(
                          '\$${product.base_price.toStringAsFixed(2)}',
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
                  if (product.stock_quantity <= 5 && product.stock_quantity > 0)
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

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.7,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 100,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 14,
                      width: 60,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
