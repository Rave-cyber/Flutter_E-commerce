import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/models/product.dart';
import 'package:firebase/views/customer/product/product_detail_screen.dart';
import 'package:firebase/models/category_model.dart';
import 'package:firebase/services/customer/category_service.dart';
import 'package:firebase/views/customer/categories/categories_screen.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({Key? key, this.initialQuery}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final Color primaryGreen = const Color(0xFF2C8610);
  Timer? _debounce;
  bool _loading = false;
  List<ProductModel> _results = [];
  List<String> _searchHistory = [];
  List<ProductModel> _recentProducts = [];
  List<ProductModel> _featuredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _search(widget.initialQuery!);
    }
  }

  Future<void> _loadSuggestions() async {
    try {
      // Load search history from local storage (you can use shared_preferences)
      // _searchHistory = await _getSearchHistory();

      // Load recent products
      final recentSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('is_archived', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .limit(5)
          .get();

      _recentProducts = recentSnapshot.docs.map((doc) {
        return ProductModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();

      // Load featured products
      final featuredSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('is_archived', isEqualTo: false)
          .where('is_featured', isEqualTo: true)
          .limit(5)
          .get();

      _featuredProducts = featuredSnapshot.docs.map((doc) {
        return ProductModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error loading suggestions: $e');
    }
  }

  Future<void> _search(String query) async {
    if (!mounted) return;

    if (query.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final productsRef = FirebaseFirestore.instance.collection('products');

      // Search by name (prefix)
      final nameQuery = productsRef
          .where('is_archived', isEqualTo: false)
          .orderBy('name')
          .startAt([query]).endAt(['$query\uf8ff']).limit(20);

      // Search by category name (you need to store category_name in products)
      final categoryQuery = productsRef
          .where('is_archived', isEqualTo: false)
          .where('category_name', isEqualTo: query)
          .limit(10);

      // Execute queries in parallel
      final [nameSnap, categorySnap] = await Future.wait([
        nameQuery.get(),
        categoryQuery.get(),
      ]);

      // Combine results
      final allDocs = {...nameSnap.docs, ...categorySnap.docs};

      final List<ProductModel> fetched = allDocs.map((d) {
        final data = d.data();
        return ProductModel.fromMap({
          'id': d.id,
          ...data,
        });
      }).toList();

      // Remove duplicates
      final uniqueProducts = <String, ProductModel>{};
      for (final product in fetched) {
        uniqueProducts[product.id] = product;
      }

      if (!mounted) return;
      setState(() {
        _results = uniqueProducts.values.toList();
        _loading = false;
      });

      // Save to search history
      if (query.isNotEmpty) {
        _addToSearchHistory(query);
      }
    } catch (e) {
      print('Search error: $e');
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
      });

      // Fallback to simpler search if complex query fails
      await _simpleSearch(query);
    }
  }

  Future<void> _simpleSearch(String query) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('is_archived', isEqualTo: false)
          .get();

      final allProducts = snapshot.docs.map((doc) {
        return ProductModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();

      // Filter locally
      final filtered = allProducts.where((product) {
        final nameMatch =
            product.name.toLowerCase().contains(query.toLowerCase());
        final descMatch =
            product.description.toLowerCase().contains(query.toLowerCase());
        return nameMatch || descMatch;
      }).toList();

      if (mounted) {
        setState(() {
          _results = filtered;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _loading = false;
        });
      }
    }
  }

  void _addToSearchHistory(String query) {
    // Add to beginning of list
    _searchHistory.insert(0, query);

    // Keep only last 10 searches
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }

    // Save to local storage (implement with shared_preferences)
    // _saveSearchHistory();

    if (mounted) {
      setState(() {});
    }
  }

  void _clearSearchHistory() {
    _searchHistory.clear();
    // _saveSearchHistory();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildProductItem(ProductModel product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: product.image.isNotEmpty
              ? Image.network(
                  product.image,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    );
                  },
                )
              : Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
        ),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '\$${product.sale_price.toStringAsFixed(2)}',
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (product.stock_quantity != null &&
                product.stock_quantity! <= 5 &&
                product.stock_quantity! > 0)
              Text(
                'Only ${product.stock_quantity} left',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search History
        if (_searchHistory.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((query) {
                return ActionChip(
                  label: Text(query),
                  onPressed: () {
                    _controller.text = query;
                    _search(query);
                  },
                  backgroundColor: Colors.grey[100],
                );
              }).toList(),
            ),
          ),
        ],

        // Featured Products
        if (_featuredProducts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Featured Products',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
          ),
          ..._featuredProducts.map(_buildProductItem).toList(),
        ],

        // Recent Products
        if (_recentProducts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Recently Added',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),
          ),
          ..._recentProducts.map(_buildProductItem).toList(),
        ],

        // Categories
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            'Popular Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
        ),
        StreamBuilder<List<CategoryModel>>(
          stream: CustomerCategoryService().getActiveCategories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();

            final categories = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
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
                              initialCategoryId: category.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        titleSpacing: 0,
        title: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search products, categories...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[600]),
                  ),
                  onSubmitted: (value) => _search(value.trim()),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600]),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _results = [];
                    });
                  },
                ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _results.isNotEmpty
              ? ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = _results[index];
                    return _buildProductItem(p);
                  },
                )
              : SingleChildScrollView(
                  child: _controller.text.isEmpty
                      ? _buildSuggestionsSection()
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No products found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Try searching with different keywords',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() {});
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryGreen,
                                  ),
                                  child: const Text('Clear Search'),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
    );
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _search(value.trim());
    });
  }
}
