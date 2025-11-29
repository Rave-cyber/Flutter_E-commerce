import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';

class AdminCustomers extends StatelessWidget {
  const AdminCustomers({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      child: Center(
        child: Text(
          "Customers Page",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
