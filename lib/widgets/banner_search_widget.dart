import 'package:flutter/material.dart';

class BannerSearchWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onChanged;

  const BannerSearchWidget({
    Key? key,
    required this.controller,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: const Color(0xFF2C8610).withOpacity(0.3),
      borderRadius: BorderRadius.circular(12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: 'Search Banners',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF2C8610)),
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
            borderSide: const BorderSide(color: Color(0xFF2C8610), width: 2),
          ),
        ),
        onChanged: (_) => onChanged?.call(),
      ),
    );
  }
}
