import 'package:flutter/material.dart';

import '../../../layouts/delivery_staff_layout.dart';

class DeliveryStaffOrdersScreen extends StatelessWidget {
  const DeliveryStaffOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DeliveryStaffLayout(
      title: 'Orders',
      selectedRoute: '/delivery-staff/orders',
      child: Center(
        child: Text('Delivery Staff Orders'),
      ),
    );
  }
}
