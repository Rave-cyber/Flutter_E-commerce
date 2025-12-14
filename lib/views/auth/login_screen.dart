import 'package:firebase/models/delivery_staff_model.dart';
import 'package:firebase/views/admin/admin_dashboard/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/local_cart_service.dart';

import '../../models/user_model.dart';
import '../../models/customer_model.dart';
import '../delivery_staff/delivery_staff_dashboard/index.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';
import '../super_admin/super_admin_dashboard/index.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Instantiate AuthService directly
      final authService = AuthService();

      // Firebase login
      final firebaseUser = await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (firebaseUser == null) throw 'Login failed';

      // Load UserModel
      final UserModel? user = await authService.getCurrentUserData();
      if (user == null) throw 'User data not found';

      // Merge guest cart if any
      await LocalCartService.mergeGuestCart(user.id);

      if (!mounted) return;

      // Check role and navigate accordingly
      if (user.role == 'super_admin') {
        // Navigate to SuperAdminDashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminDashboardScreen()),
        );
      } else if (user.role == 'admin') {
        // Navigate to AdminScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else if (user.role == 'customer') {
        // Load CustomerModel for customers
        final CustomerModel? customer = await authService.getCustomerData();
        if (customer == null) throw 'Customer profile not found';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              user: user,
              customer: customer,
            ),
          ),
        );
      } else if (user.role == 'delivery_staff') {
        // Load DeliveryStaffModel for delivery staff
        final deliveryStaffQuery = await authService.firestore
            .collection('delivery_staff')
            .where('user_id', isEqualTo: user.id)
            .limit(1)
            .get();

        if (deliveryStaffQuery.docs.isEmpty)
          throw 'Delivery Staff profile not found';

        final deliveryStaff =
            DeliveryStaffModel.fromMap(deliveryStaffQuery.docs.first.data());

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DeliveryStaffDashboardScreen(),
          ),
        );
      } else {
        throw 'Invalid user role';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      // Instantiate AuthService directly
      final authService = AuthService();

      // Google sign-in
      final user = await authService.signInWithGoogle();

      if (user == null) {
        // User cancelled sign-in
        setState(() => _isLoading = false);
        return;
      }

      // Merge guest cart if any
      await LocalCartService.mergeGuestCart(user.id);

      if (!mounted) return;

      // Check role and navigate accordingly
      if (user.role == 'super_admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SuperAdminDashboardScreen()),
        );
      } else if (user.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboard()),
        );
      } else if (user.role == 'customer') {
        final CustomerModel? customer = await authService.getCustomerData();
        if (customer == null) throw 'Customer profile not found';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(
              user: user,
              customer: customer,
            ),
          ),
        );
      } else if (user.role == 'delivery_staff') {
        final deliveryStaffQuery = await authService.firestore
            .collection('delivery_staff')
            .where('user_id', isEqualTo: user.id)
            .limit(1)
            .get();

        if (deliveryStaffQuery.docs.isEmpty)
          throw 'Delivery Staff profile not found';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const DeliveryStaffDashboardScreen(),
          ),
        );
      } else {
        throw 'Invalid user role';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue shopping',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),

                // Email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C8610),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // Google Sign-In button (FIXED - using network image)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    icon: Image.network(
                      'https://cdn-icons-png.flaticon.com/512/2991/2991148.png',
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if network image fails
                        return Icon(Icons.g_mobiledata, size: 24);
                      },
                    ),
                    label: const Text(
                      'Sign in with Google',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: TextStyle(color: Colors.grey[600])),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(color: Color(0xFF2C8610)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
