import 'package:firebase/views/admin/admin_attributes/index.dart';
import 'package:firebase/views/admin/admin_brands/index.dart';
import 'package:firebase/views/admin/admin_categories/index.dart';
import 'package:firebase/views/admin/admin_stock_checker/index.dart';
import 'package:firebase/views/admin/admin_stock_ins/form.dart';
import 'package:firebase/views/admin/admin_stock_ins/index.dart';
import 'package:firebase/views/admin/admin_stock_outs/index.dart';
import 'package:firebase/views/admin/admin_suppliers/index.dart';
import 'package:firebase/views/admin/admin_warehouses/index.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../views/auth/login_screen.dart';

// Updated Import Paths
import '../views/admin/admin_dashboard/index.dart';
import '../views/admin/admin_customers/index.dart';
import '../views/admin/admin_products/index.dart';
import '../views/admin/admin_orders/index.dart';
import '../views/admin/admin_orders/sales_report_screen.dart';

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
      ),
      body: child,
    );
  }

  Drawer _buildSidebar(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.blueGrey),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                "Admin Panel",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Scrollable menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
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
                      MaterialPageRoute(
                          builder: (_) => const AdminCustomersIndex()),
                    );
                  },
                ),

                // Orders
                ListTile(
                  leading:
                      const Icon(Icons.shopping_cart, color: Colors.blueGrey),
                  title: const Text("Orders"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminOrdersIndex()),
                    );
                  },
                ),

                // Sales Report
                ListTile(
                  leading: const Icon(Icons.assessment, color: Colors.blueGrey),
                  title: const Text("Sales Report"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SalesReportScreen()),
                    );
                  },
                ),

                // Products
                ListTile(
                  leading:
                      const Icon(Icons.shopping_bag, color: Colors.blueGrey),
                  title: const Text("Products"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminProductsIndex()),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.category, color: Colors.blueGrey),
                  title: const Text("Categories"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminCategoriesIndex()),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.branding_watermark,
                      color: Colors.blueGrey),
                  title: const Text("Brands"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminBrandsIndex()),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.label, color: Colors.blueGrey),
                  title: const Text("Attributes"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminAttributesIndex()),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.warehouse, color: Colors.blueGrey),
                  title: const Text("Warehouses"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminWarehousesIndex()),
                    );
                  },
                ),

                ListTile(
                  leading:
                      const Icon(Icons.local_shipping, color: Colors.blueGrey),
                  title: const Text("Suppliers"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminSuppliersIndex()),
                    );
                  },
                ),

                ListTile(
                  leading:
                      const Icon(Icons.inventory_2, color: Colors.blueGrey),
                  title: const Text("Stock Checkers"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminStockCheckersIndex()),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.add_shopping_cart,
                      color: Colors.blueGrey),
                  title: const Text("Stock-In"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminStockInIndex()),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.remove_shopping_cart,
                      color: Colors.blueGrey),
                  title: const Text("Stock-Out"),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AdminStockOutIndex()),
                    );
                  },
                ),
              ],
            ),
          ),

          // Logout - Sticks to bottom
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
