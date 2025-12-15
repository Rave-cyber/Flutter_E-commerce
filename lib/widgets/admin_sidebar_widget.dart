import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../views/admin/admin_dashboard/index.dart';
import '../views/admin/admin_customers/index.dart';
import '../views/admin/admin_orders/index.dart';
import '../views/admin/admin_orders/sales_report_screen.dart';
import '../views/admin/admin_banners/admin_banners_screen.dart';
import '../views/admin/admin_products/index.dart';
import '../views/admin/admin_categories/index.dart';
import '../views/admin/admin_brands/index.dart';
import '../views/admin/admin_attributes/index.dart';
import '../views/admin/admin_warehouses/index.dart';
import '../views/admin/admin_suppliers/index.dart';
import '../views/admin/admin_stock_checker/index.dart';
import '../views/admin/admin_stock_ins/index.dart';
import '../views/admin/admin_stock_outs/index.dart';
import '../views/admin/admin_inventory_reports/index.dart';
import '../services/auth_service.dart';
import '../views/auth/login_screen.dart';

class AdminSidebarWidget extends StatelessWidget {
  final String? selectedRoute;

  const AdminSidebarWidget({
    Key? key,
    this.selectedRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header with gradient background - Flexible height
          _buildHeader(),

          // Menu sections
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade50,
                    Colors.white,
                  ],
                ),
              ),
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  _buildSectionHeader('Overview'),
                  _buildMenuItem(
                    context,
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    route: '/admin/dashboard',
                    isSelected: selectedRoute == '/admin/dashboard',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.image,
                    title: 'Banners',
                    route: '/admin/banners',
                    isSelected: selectedRoute == '/admin/banners',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Sales & Customers'),
                  _buildMenuItem(
                    context,
                    icon: Icons.people,
                    title: 'Customers',
                    route: '/admin/customers',
                    isSelected: selectedRoute == '/admin/customers',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.shopping_cart,
                    title: 'Orders',
                    route: '/admin/orders',
                    isSelected: selectedRoute == '/admin/orders',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.assessment,
                    title: 'Sales Report',
                    route: '/admin/sales-report',
                    isSelected: selectedRoute == '/admin/sales-report',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Products'),
                  _buildMenuItem(
                    context,
                    icon: Icons.shopping_bag,
                    title: 'Products',
                    route: '/admin/products',
                    isSelected: selectedRoute == '/admin/products',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.category,
                    title: 'Categories',
                    route: '/admin/categories',
                    isSelected: selectedRoute == '/admin/categories',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.branding_watermark,
                    title: 'Brands',
                    route: '/admin/brands',
                    isSelected: selectedRoute == '/admin/brands',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.label,
                    title: 'Attributes',
                    route: '/admin/attributes',
                    isSelected: selectedRoute == '/admin/attributes',
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Inventory Management'),
                  _buildMenuItem(
                    context,
                    icon: Icons.analytics,
                    title: 'Inventory Reports',
                    route: '/admin/inventory-reports',
                    isSelected: selectedRoute == '/admin/inventory-reports',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.warehouse,
                    title: 'Warehouses',
                    route: '/admin/warehouses',
                    isSelected: selectedRoute == '/admin/warehouses',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.local_shipping,
                    title: 'Suppliers',
                    route: '/admin/suppliers',
                    isSelected: selectedRoute == '/admin/suppliers',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.inventory_2,
                    title: 'Stock Checkers',
                    route: '/admin/stock-checkers',
                    isSelected: selectedRoute == '/admin/stock-checkers',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.add_shopping_cart,
                    title: 'Stock-In',
                    route: '/admin/stock-ins',
                    isSelected: selectedRoute == '/admin/stock-ins',
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.remove_shopping_cart,
                    title: 'Stock-Out',
                    route: '/admin/stock-outs',
                    isSelected: selectedRoute == '/admin/stock-outs',
                  ),
                ],
              ),
            ),
          ),

          // Logout section
          _buildLogoutSection(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate appropriate height based on available space
        final headerHeight = constraints.maxHeight.clamp(80.0, 120.0);

        return Material(
          elevation: 4,
          shadowColor: Colors.green.withOpacity(0.3),
          child: Container(
            height: headerHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade600,
                  Colors.green.shade800,
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Admin Panel",
                              style: TextStyle(
                                fontSize: 21,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                    color: Colors.black26,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "E-Commerce Management",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w300,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
          textBaseline: TextBaseline.alphabetic,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                  spreadRadius: 0,
                ),
              ],
      ),
      child: Material(
        elevation: isSelected ? 3 : 1,
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.green.shade50 : Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToRoute(context, route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.green.shade200 : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.green.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.green.shade800
                          : Colors.grey.shade800,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            color: Colors.red.shade50,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showLogoutDialog(context, authService),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.red.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.logout,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToRoute(BuildContext context, String route) {
    Navigator.pop(context);

    Widget targetWidget;
    switch (route) {
      case '/admin/dashboard':
        targetWidget = const AdminDashboard();
        break;
      case '/admin/customers':
        targetWidget = const AdminCustomersIndex();
        break;
      case '/admin/orders':
        targetWidget = const AdminOrdersIndex();
        break;
      case '/admin/sales-report':
        targetWidget = const SalesReportScreen();
        break;
      case '/admin/banners':
        targetWidget = const AdminBannersScreen();
        break;
      case '/admin/products':
        targetWidget = const AdminProductsIndex();
        break;
      case '/admin/categories':
        targetWidget = const AdminCategoriesIndex();
        break;
      case '/admin/brands':
        targetWidget = const AdminBrandsIndex();
        break;
      case '/admin/attributes':
        targetWidget = const AdminAttributesIndex();
        break;
      case '/admin/warehouses':
        targetWidget = const AdminWarehousesIndex();
        break;
      case '/admin/suppliers':
        targetWidget = const AdminSuppliersIndex();
        break;
      case '/admin/stock-checkers':
        targetWidget = const AdminStockCheckersIndex();
        break;
      case '/admin/stock-ins':
        targetWidget = const AdminStockInIndex();
        break;
      case '/admin/stock-outs':
        targetWidget = const AdminStockOutIndex();
        break;
      case '/admin/inventory-reports':
        targetWidget = const AdminInventoryReports();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetWidget),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
