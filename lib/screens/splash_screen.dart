import 'package:flutter/material.dart';
import 'package:recylink/screens/onboarding_screen.dart'; // Import the new OnboardingScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the OnboardingScreen after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define background color
    const Color splashBackgroundColor = Color(0xFFF5FFED);

    return Scaffold(
      backgroundColor: splashBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/logo.png', // Your logo asset
              height: 500, // Adjust size as needed
              width: 500,
            ),

          ],
        ),
      ),
    );
  }
}