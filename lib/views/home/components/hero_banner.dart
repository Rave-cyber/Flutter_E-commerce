import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class HeroBanner extends StatelessWidget {
  const HeroBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF2C8610);

    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryGreen.withOpacity(0.2),
            primaryGreen.withOpacity(0.1)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -20,
            child: Lottie.asset(
              'assets/animations/furniture-banner.json',
              height: 250,
              width: 250,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Summer Sale',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                Text(
                  'Up to 50% off on premium furniture',
                  style: TextStyle(
                    fontSize: 16,
                    color: primaryGreen.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Browse as Guest',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
