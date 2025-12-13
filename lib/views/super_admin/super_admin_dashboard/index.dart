import 'package:flutter/material.dart';

import '../../../layouts/super_admin_layout.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SuperAdminLayout(
      title: 'Dashboard',
      selectedRoute: '/super-admin/dashboard',
      child: Center(
        child: Text('Super Admin Dashboard'),
      ),
    );
  }
}
