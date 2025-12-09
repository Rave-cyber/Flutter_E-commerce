import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase/models/product.dart';
import 'package:firebase/views/customer/product/product_detail_screen.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _search(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(value.trim());
    });
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

      // Name prefix query using startAt/endAt
      final snap = await productsRef
          .orderBy('name')
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .limit(50)
          .get();

      final docs = snap.docs;
      final List<ProductModel> fetched = docs.map((d) {
        final data = d.data();
        return ProductModel.fromMap({
          'id': d.id,
          ...data,
        });
      }).toList();

      // Client-side additional filters:
      // - Remove archived
      // - If user typed a category token, filter by category_name if present on doc
      final qLower = query.toLowerCase();
      final filtered = fetched.where((p) {
        final isActive = !p.is_archived;
        // Try to read category_name if present in the doc by looking into the raw map
        // Since we lost the raw map, do a naive filter: if the product has a field category_name on doc, it would've been in fetched map.
        // To keep performance simple, we'll rely on name matching for now, as query already does prefix by name.
        return isActive;
      }).toList();

      if (!mounted) return;
      setState(() {
        _results = filtered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search products',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) => _search(value.trim()),
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _controller.clear();
                    _onChanged('');
                  },
                ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(
                  child: Text(
                    _controller.text.isEmpty
                        ? 'Start typing to search'
                        : 'No results',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.separated(
                  itemBuilder: (context, index) {
                    final p = _results[index];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: p.image.isNotEmpty
                            ? Image.network(
                                p.image,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                      title: Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '\$${p.sale_price.toStringAsFixed(2)}',
                        style: TextStyle(color: primaryGreen),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(product: p),
                          ),
                        );
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: _results.length,
                ),
    );
  }
}
