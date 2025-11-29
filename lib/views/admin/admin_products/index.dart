import 'package:flutter/material.dart';
import '../../../layouts/admin_layout.dart';

class AdminProducts extends StatelessWidget {
  const AdminProducts({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      child: Center(
        child: Text(
          "Products Page",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
