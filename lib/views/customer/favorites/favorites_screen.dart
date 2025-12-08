import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/user_model.dart';
import '../../../models/customer_model.dart';
import '../../../services/auth_service.dart';
import '../../auth/login_screen.dart';

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
    // TODO: Implement actual favorites logic
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
}
