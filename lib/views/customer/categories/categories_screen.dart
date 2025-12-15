import 'package:firebase/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../models/user_model.dart';
import '../../../models/product.dart';
import '../../../firestore_service.dart';
import '../../../services/customer/category_service.dart';
import '../product/product_detail_screen.dart';
<<<<<<< HEAD
=======
import '../search/search_screen.dart';
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

class CategoriesScreen extends StatefulWidget {
  final UserModel? user;
  final String? initialCategoryId;

  const CategoriesScreen({
    Key? key,
    this.user,
    this.initialCategoryId,
  }) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _selectedCategory = 'All';
  String? _selectedBrandId;
  RangeValues _currentPriceRange = const RangeValues(0, 5000);

  final Color primaryGreen = const Color(0xFF2C8610);
  late CustomerCategoryService _categoryService;
  List<CategoryModel> _categories = [];
  List<Map<String, dynamic>> _brands = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryId != null) {
      _selectedCategory = widget.initialCategoryId!;
    }
    _categoryService = CustomerCategoryService();
    _loadCategories();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    FirestoreService.getAllBrands().listen((brands) {
      if (mounted) {
        setState(() {
          _brands = brands;
        });
      }
    });
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

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedBrandId = null;
                            _currentPriceRange = const RangeValues(0, 5000);
                          });
                          setModalState(() {});
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Clear All',
                          style: TextStyle(color: Colors.red[400]),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'Brand',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _brands.length,
                      itemBuilder: (context, index) {
                        final brand = _brands[index];
                        final isSelected = _selectedBrandId == brand['id'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(brand['name'] ?? ''),
                            selected: isSelected,
                            selectedColor: primaryGreen,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                _selectedBrandId =
                                    selected ? brand['id'] : null;
                              });
                              setState(() {}); // Update main screen as well
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Price Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  RangeSlider(
                    values: _currentPriceRange,
                    min: 0,
                    max: 5000,
                    divisions: 50,
                    activeColor: primaryGreen,
                    labels: RangeLabels(
                      '\$${_currentPriceRange.start.round()}',
                      '\$${_currentPriceRange.end.round()}',
                    ),
                    onChanged: (values) {
                      setModalState(() {
                        _currentPriceRange = values;
                      });
                      setState(() {});
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$${_currentPriceRange.start.round()}'),
                      Text('\$${_currentPriceRange.end.round()}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
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
            icon: Icon(Icons.filter_list, color: primaryGreen),
            onPressed: _showFilterModal,
          ),
          IconButton(
            icon: Icon(Icons.search, color: primaryGreen),
<<<<<<< HEAD
            onPressed: () {},
=======
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
            },
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: primaryGreen),
            onPressed: () {
              // Reset filters on refresh
              setState(() {
                _selectedBrandId = null;
                _currentPriceRange = const RangeValues(0, 5000);
              });
              _loadCategories();
            },
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
        id: 'All',
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
                  child: Text('Retry', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                  ),
                ),
              ],
            ),
          );
        }

        // Check data
        var products = snapshot.data ?? [];

        // Apply Filters
        if (_selectedBrandId != null) {
          products =
              products.where((p) => p.brand_id == _selectedBrandId).toList();
        }

        products = products
            .where((p) =>
                p.sale_price >= _currentPriceRange.start &&
                p.sale_price <= _currentPriceRange.end)
            .toList();

        print('Products loaded: ${products.length} (Filtered)');

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/animations/Empty Cart.json',
                  height: 200,
                  width: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.inventory_2_outlined,
                        color: Colors.grey[400], size: 60);
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'No products found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Try adjusting your filters',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedBrandId = null;
                      _currentPriceRange = const RangeValues(0, 5000);
                      _selectedCategory = 'All';
                    });
                  },
                  child: Text('Reset Filters',
                      style: TextStyle(color: Colors.white)),
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
<<<<<<< HEAD
                  if (product.stock_quantity! <= 5 &&
=======
                  if (product.stock_quantity! < 5 &&
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
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
