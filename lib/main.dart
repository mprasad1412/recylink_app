// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // Import camera
import 'package:recylink/screens/onboarding_screen.dart';
import 'screens/splash_screen.dart'; // Import the new SplashScreen
import 'screens/main_screen.dart'; // Keep MainScreen import for AuthScreen navigation
import 'package:recylink/services/firestore_init_helper.dart';


List<CameraDescription> cameras = []; // Global variable to store cameras

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }

  await Firebase.initializeApp();

  // Initialize sample data (only runs once)
  final isInitialized = await FirestoreInitHelper.isDatabaseInitialized();
  if (!isInitialized) {
    print('📦 Initializing Firestore with sample data...');
    await FirestoreInitHelper.initializeSampleData();
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecyLink App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const OnboardingScreen(), // Start with the SplashScreen
    );
  }
}