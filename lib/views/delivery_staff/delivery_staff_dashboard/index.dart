import 'package:flutter/material.dart';

import '../../../layouts/delivery_staff_layout.dart';

class DeliveryStaffDashboardScreen extends StatelessWidget {
  const DeliveryStaffDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DeliveryStaffLayout(
      title: 'Dashboard',
      selectedRoute: '/delivery-staff/dashboard',
      child: Center(
        child: Text('Delivery Staff Dashboard'),
      ),
    );
  }
}
