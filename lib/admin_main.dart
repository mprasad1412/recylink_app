import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin/admin_home.dart';
import 'admin/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDMDt9Gn7_AxfqnY2rfsvB6mGgWuNNM94M",
      authDomain: "recylink-d64da.firebaseapp.com",
      projectId: "recylink-d64da",
      storageBucket: "recylink-d64da.firebasestorage.app",
      messagingSenderId: "371763927921",
      appId: "1:371763927921:web:25ba165c2c09ce5388b4d0",
      measurementId: "G-FH43QKYJJ4",
    ),
  );

  runApp(const RecyLinkAdminApp());
}

class RecyLinkAdminApp extends StatelessWidget {
  const RecyLinkAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecyLink Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins', // Optional
        scaffoldBackgroundColor: const Color(0xFFF5F9F6), // Mint-ish White
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Primary Green
          primary: const Color(0xFF2E7D32),
          secondary: const Color(0xFFAEE55B), // Accent Green
          error: const Color(0xFFD32F2F),
          surface: const Color(0xFFF5F9F6),
        ),
        useMaterial3: true,

        // FIXED: Use CardThemeData instead of CardTheme
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        // AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF2E7D32)),
          titleTextStyle: TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const AdminHome();
          }

          return const AdminLoginScreen();
        },
      ),
    );
  }
}