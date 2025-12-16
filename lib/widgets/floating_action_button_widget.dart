import 'package:flutter/material.dart';

class FloatingActionButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const FloatingActionButtonWidget({
    Key? key,
    required this.onPressed,
    this.tooltip = 'Add Product',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: Colors.green,
          elevation: 8,
          highlightElevation: 12,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
          tooltip: tooltip,
        ),
      ),
    );
  }
}
