import 'package:flutter/material.dart';
import 'package:firebase/views/customer/orders/orders_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2C8610);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: TextStyle(
            color: primaryGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: primaryGreen),
        actions: [
          // Orders Icon Button
          IconButton(
            icon: Icon(
              Icons.shopping_bag_outlined,
              color: primaryGreen,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OrdersScreen(),
                ),
              );
            },
            tooltip: 'My Orders',
          ),

          // Cart Icon Button
          IconButton(
            icon: Icon(
              Icons.shopping_cart_outlined,
              color: primaryGreen,
            ),
            onPressed: () {
              // Navigate to cart screen
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => CartScreen(),
              //   ),
              // );
            },
            tooltip: 'Shopping Cart',
          ),
        ],
      ),
      body: const Center(
        child: Text('Home Page Content'),
      ),
    );
  }
}
