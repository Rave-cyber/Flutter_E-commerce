import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    // You can control the animation duration here
    // For example, make the animation loop for 3 seconds
    _controller.duration = const Duration(seconds: 7);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/shopping.json',
              controller: _controller,
              onLoaded: (composition) {
                // Set the duration and play the animation
                _controller
                  ..duration = composition.duration
                  ..forward();

                // OR if you want to loop the animation for a specific time:
                // _controller.repeat(); // This will loop indefinitely
              },
              height: 300,
              width: 300,
            ),
            const SizedBox(height: 20),
            Text(
              'Dimdi Home',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
                fontFamily: 'Georgia',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Furniture & Appliances',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
