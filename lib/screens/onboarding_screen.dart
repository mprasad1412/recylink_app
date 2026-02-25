import 'package:flutter/material.dart';
import 'package:recylink/screens/auth_screen.dart'; // Import the new AuthScreen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Define background color
  static const Color onboardingBackgroundColor = Color(0xFFF5FFED);
  static const Color primaryGreen = Color(0xFF2E7D32); // From existing colors

  final List<Map<String, String>> onboardingPages = [
    {
      'image': 'lib/assets/illus1.png',
      'title': 'Join the Green Movement',
      'description': 'Contribute to sustainability with easy, effective recycling.',
    },
    {
      'image': 'lib/assets/illus2.png',
      'title': 'Find Recycling Drop-off Points',
      'description': 'Find the nearest recycling drop-off points with real-time updates.',
    },
    {
      'image': 'lib/assets/illus3.png',
      'title': 'Smart Waste Identification',
      'description': 'Instantly identify your waste and get proper disposal instructions with AI.',
    },
    {
      'image': 'lib/assets/illus4.png',
      'title': 'Sell & Buy Upscale Items',
      'description': 'Browse the marketplace to post, buy and sell your upscale items',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: onboardingBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: onboardingPages.length,
              itemBuilder: (context, index) {
                return _buildOnboardingPage(onboardingPages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
            child: Column(
              children: [
                // Page Indicator Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingPages.length,
                        (index) => _buildDot(index),
                  ),
                ),
                const SizedBox(height: 30),
                // Navigation Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip Button
                    if (_currentPage < onboardingPages.length - 1)
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                          );
                        },
                        child: const Text(
                          'Skip',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    else // On the last page, show a "Back" button if not the first page
                      _currentPage > 0
                          ? TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                        child: const Text(
                          'Back',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                          : const SizedBox.shrink(), // Hide "Back" on first page

                    // Next/Get Started Button
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPage == onboardingPages.length - 1) {
                          // Last page, navigate to AuthScreen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                          );
                        } else {
                          // Go to next page
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
                      ),
                      child: Text(
                        _currentPage == onboardingPages.length - 1 ? 'Get started' : 'Next',
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(Map<String, String> pageData) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            pageData['image']!,
            height: 250, // Adjust image height as needed
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 40),
          Text(
            pageData['title']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            pageData['description']!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: _currentPage == index ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: _currentPage == index ? primaryGreen : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}