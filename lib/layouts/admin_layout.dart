import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../views/auth/login_screen.dart';

// Import admin pages
import '../views/admin/admin_dashboard.dart';
import '../views/admin/admin_customers.dart';
import '../views/admin/admin_products.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildSidebar(context),
      appBar: AppBar(
        title: const Text('Admin'),
        backgroundColor: Colors.blueGrey,
        elevation: 0,
        actions: [
          Consumer<AuthService>(
            builder: (context, authService, _) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _confirmLogout(context, authService),
              );
            },
          ),
        ],
      ),
      body: child,
    );
  }

  Drawer _buildSidebar(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blueGrey),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                "Admin Panel",
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Dashboard
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.blueGrey),
            title: const Text("Dashboard"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboard()),
              );
            },
          ),

          // Customers
          ListTile(
            leading: const Icon(Icons.people, color: Colors.blueGrey),
            title: const Text("Customers"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminCustomers()),
              );
            },
          ),

          // Products
          ListTile(
            leading: const Icon(Icons.shopping_bag, color: Colors.blueGrey),
            title: const Text("Products"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminProducts()),
              );
            },
          ),

          const Spacer(),

          // Logout
          Consumer<AuthService>(
            builder: (context, authService, _) {
              return ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title:
                    const Text("Logout", style: TextStyle(color: Colors.red)),
                onTap: () => _confirmLogout(context, authService),
              );
            },
          ),
        ],
      ),
    );
  }

  // Logout Dialog
  void _confirmLogout(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
