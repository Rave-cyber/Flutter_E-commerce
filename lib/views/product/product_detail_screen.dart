import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../widgets/top_nav_bar.dart';
import '../widgets/animated_bottom_nav_bar.dart';

import 'package:carousel_slider/carousel_slider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product})
      : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavBar(title: widget.product.name),
      body: CustomScrollView(
        slivers: [
          // Your SliverAppBar & content
        ],
      ),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // Navigate to selected screen
        },
      ),
    );
  }
}
