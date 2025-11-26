import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/home_controller.dart';
import '../widgets/animated_bottom_nav_bar.dart';
import 'components/hero_banner.dart';
import 'components/category_section.dart';
import 'components/featured_products.dart';
import 'components/products_section.dart';
import '../widgets/top_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeController(),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: const _HomeScreenBody(),
        bottomNavigationBar: const _HomeBottomNavBar(),
      ),
    );
  }
}

class _HomeScreenBody extends StatelessWidget {
  const _HomeScreenBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scrollable Content
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add top padding equal to TopNavBar height
              const SizedBox(
                  height: 80), // Adjust based on your TopNavBar height
              const HeroBanner(),
              const SizedBox(height: 16),
              const CategorySection(),
              const SizedBox(height: 24),
              const FeaturedProducts(),
              const SizedBox(height: 24),
              const ProductsSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),

        // Fixed Top Navigation Bar with required title
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TopNavBar(title: 'Home'),
        ),
      ],
    );
  }
}

class _HomeBottomNavBar extends StatelessWidget {
  const _HomeBottomNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeController>(context);

    return AnimatedBottomNavBar(
      currentIndex: controller.currentIndex,
      onTap: (index) {
        controller.setCurrentIndex(index);
      },
    );
  }
}
