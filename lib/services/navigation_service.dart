import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  int _currentIndex = 0;

  final List<Widget> _screens = [];

  // Getters
  int get currentIndex => _currentIndex;
  List<Widget> get screens => _screens;

  // Initialize screens
  void initializeScreens(List<Widget> screens) {
    _screens.clear();
    _screens.addAll(screens);
  }

  // Change screen
  void changeScreen(int index) {
    if (index >= 0 && index < _screens.length) {
      _currentIndex = index;
    }
  }

  // Get current screen
  Widget get currentScreen {
    if (_screens.isEmpty) {
      return const Scaffold(body: Center(child: Text('No screens available')));
    }
    return _screens[_currentIndex];
  }
}
