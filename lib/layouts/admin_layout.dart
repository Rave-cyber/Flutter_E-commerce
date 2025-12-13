import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../views/auth/login_screen.dart';
import '../widgets/admin_sidebar_widget.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminSidebarWidget(),
      appBar: AppBar(
        title: const Text('Admin'),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        foregroundColor: Colors.white,
        shadowColor: Colors.green.withOpacity(0.3),
      ),
      body: child,
    );
  }
}
