import 'package:flutter/material.dart';

class StockPaginationWidget extends StatelessWidget {
  final int currentPage;
  final int? totalPages;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  const StockPaginationWidget({
    Key? key,
    required this.currentPage,
    this.totalPages,
    required this.onPreviousPage,
    required this.onNextPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              elevation: 0,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onPreviousPage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.arrow_back_ios_new,
                      size: 18, color: Colors.blue[700]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                totalPages != null
                    ? 'Page $currentPage of $totalPages'
                    : 'Page $currentPage',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Material(
              elevation: 0,
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onNextPage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.arrow_forward_ios,
                      size: 18, color: Colors.blue[700]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
