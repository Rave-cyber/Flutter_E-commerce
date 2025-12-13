import 'package:flutter/material.dart';

import '../widgets/super_admin_sidebar_widget.dart';

class SuperAdminLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final String? selectedRoute;

  const SuperAdminLayout({
    Key? key,
    required this.child,
    this.title = 'Super Admin',
    this.selectedRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SuperAdminSidebarWidget(selectedRoute: selectedRoute),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green.shade600,
        elevation: 0,
        foregroundColor: Colors.white,
        shadowColor: Colors.green.withOpacity(0.3),
      ),
      body: child,
    );
  }
}
