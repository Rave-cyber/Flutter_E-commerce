import 'package:flutter/material.dart';

import '../widgets/delivery_staff_sidebar_widget.dart';

class DeliveryStaffLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final String? selectedRoute;

  const DeliveryStaffLayout({
    Key? key,
    required this.child,
    this.title = 'Delivery Staff',
    this.selectedRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: DeliveryStaffSidebarWidget(selectedRoute: selectedRoute),
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
