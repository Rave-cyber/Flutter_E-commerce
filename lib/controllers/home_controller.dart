import 'package:flutter/material.dart';

class HomeController with ChangeNotifier {
  int _currentIndex = 0;
  String _selectedCategory = 'All';

  final List<String> categories = [
    'All',
    'Sofa',
    'Chair',
    'Table',
    'Bed',
    'Electronics'
  ];

  // Getters
  int get currentIndex => _currentIndex;
  String get selectedCategory => _selectedCategory;
  List<String> get allCategories => categories;

  // Setters
  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
