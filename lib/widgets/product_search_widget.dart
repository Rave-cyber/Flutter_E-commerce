import 'package:flutter/material.dart';

class ProductSearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;
<<<<<<< HEAD
  final String? placeholder;
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663

  const ProductSearchWidget({
    Key? key,
    required this.controller,
    this.onChanged,
<<<<<<< HEAD
    this.placeholder,
=======
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: Colors.green.withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
<<<<<<< HEAD
          labelText: placeholder ?? 'Search Products',
=======
          labelText: 'Search Products',
>>>>>>> 3add35312551b90752a2c004e342857fcb126663
          prefixIcon: const Icon(Icons.search, color: Colors.green),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
        ),
        onChanged: (_) => onChanged?.call(),
      ),
    );
  }
}
