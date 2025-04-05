import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'tabs.dart'; // Your main app screen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late AnimationController _stripeController;
  List<_Stripe> _stripes = [];
  final int _numStripes = 25;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();

    _stripeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // Create stripes after first frame
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _stripeController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Tabs(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_stripes.isNotEmpty)
            AnimatedBuilder(
              animation: _stripeController,
              builder: (_, __) {
                final travelDistance = screenWidth * 1.2;
                return Stack(
                  children: _stripes.map((stripe) {
                    final offset = (_stripeController.value *
                                    travelDistance *
                                    stripe.speedFactor +
                                stripe.initialOffset) %
                            (travelDistance + stripe.height * 10) -
                        (stripe.height * 10);
                    return Positioned(
                      top: stripe.top,
                      left: offset,
                      child: Container(
                        height: stripe.height,
                        width: screenWidth * 0.4 +
                            _random.nextDouble() * (screenWidth * 0.4),
                        color: stripe.color,
                      ),
                    );
                  }).toList(),
                );
              },
            ),

          // Info Content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 80, color: Colors.blueGrey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "Blockr",
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey[200],
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info blocks
                      _infoBlock(
                        title: "Welcome to Blockr",
                        content:
                            "The all-in-one privacy app for your phone!",
                      ),
                      const SizedBox(height: 12),
                      _infoBlock(
                        title: "📊 Usage Stats",
                        content:
                            "Game-ified usage data with smart data warnings.",
                      ),
                      _infoBlock(
                        title: "🔐 Permission Control",
                        content:
                            "Swipe-based UI for reviewing and fixing permissions fast.",
                      ),
                      _infoBlock(
                        title: "🚫 App Blocking",
                        content:
                            "Flexible rules to stop procrastination, not productivity.",
                      ),
                      const SizedBox(height: 20),

                      Text(
                        "To get started, you must give some permissions.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _navigateToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          "Let’s Go!",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock({required String title, required String content}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[900]?.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey.shade700, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 6),
          Text(content,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[300], height: 1.4)),
        ],
      ),
    );
  }
}

// Stripe class
class _Stripe {
  final Color color;
  final double height;
  final double top;
  final double speedFactor;
  final double initialOffset;

  _Stripe({
    required this.color,
    required this.height,
    required this.top,
    required this.speedFactor,
    required this.initialOffset,
  });
}
