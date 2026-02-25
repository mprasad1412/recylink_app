import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recylink/screens/main_screen.dart';
import 'package:recylink/screens/signup_screen.dart';
import 'package:recylink/screens/forgot_password_screen.dart';

import '../services/firestore_init_helper.dart'; // Add this import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Define common colors
  static const Color backgroundColor = Color(0xFFF5FFED);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreenText = Color(0xFF4D8000);

  // Initialize Firebase Auth and Google Sign-In
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(
    scopes: <String>['email', 'profile'],
  );

  // Email/Password Sign In
  Future<void> _handleEmailPasswordSignIn() async {
    // Validate email format
    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      _showSnackBar(emailError);
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showSnackBar('Please enter password');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Sign in with Firebase Auth
      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      debugPrint('✅ Email Sign-In successful');
      debugPrint('User: ${userCredential.user?.email}');
      debugPrint('UID: ${userCredential.user?.uid}');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(cameras: const []),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password';
          break;
        default:
          errorMessage = 'Sign in failed: ${e.message}';
      }
      _showSnackBar(errorMessage);
      debugPrint('❌ Email Sign-in failed: ${e.code} - ${e.message}');
    } catch (e) {
      _showSnackBar('An error occurred: $e');
      debugPrint('❌ Email Sign-in error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Google Sign In
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _showSnackBar('Google Sign-in cancelled');
        setState(() => _isLoading = false);
        return;
      }

      // Obtain auth details
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.serverAuthCode,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credential
      // Sign in to Firebase with Google credential
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

// Check if this is a new user and create Firestore profile
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      if (isNewUser) {
        try {
          await FirestoreInitHelper.createUserProfile(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            username: userCredential.user?.displayName ?? 'User',
            profilePicture: userCredential.user?.photoURL, // Pass Google photo URL
          );
        } catch (firestoreError) {
          debugPrint('⚠️ Firestore write failed: $firestoreError');
          // Continue anyway - user is created in Auth
        }
      }

      debugPrint('✅ Google Sign-In successful');
      debugPrint('User: ${userCredential.user?.displayName}');
      debugPrint('Email: ${userCredential.user?.email}');
      debugPrint('UID: ${userCredential.user?.uid}');
      debugPrint('Is New User: $isNewUser');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(cameras: const []),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Google Sign-in failed: ${e.message}');
      debugPrint('❌ Google Sign-in failed: ${e.code} - ${e.message}');
    } catch (error) {
      _showSnackBar('Google Sign-in failed: $error');
      debugPrint('❌ Google Sign-in error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Please enter your email';
    }
    // Email format regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign in to your RecyLink account',
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 40),
                // Email Input
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.email_outlined),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),
                // Password Input
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 10),
                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: _isLoading
                              ? null
                              : (bool? value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                          activeColor: primaryGreen,
                        ),
                        const Text('Remember me'),
                      ],
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        // Navigate to Forgot Password Screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                            color: primaryGreen, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailPasswordSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      disabledBackgroundColor: primaryGreen.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Or continue with separator
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[400])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text('Or continue with',
                          style: TextStyle(color: Colors.grey[700])),
                    ),
                    Expanded(child: Divider(color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 30),
                // Social Sign-in Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSocialButton(FontAwesomeIcons.google, 'Google',
                        _isLoading ? null : _handleGoogleSignIn),
                    // const SizedBox(width: 15),
                    // _buildSocialButton(FontAwesomeIcons.facebook, 'Facebook',
                    //     _isLoading
                    //         ? null
                    //         : () {
                    //       _showSnackBar(
                    //           'Facebook Sign-in coming soon!');
                    //     }),
                  ],
                ),
                const SizedBox(height: 40),
                // Don't have an account? Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                              const SignUpScreen()),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: _isLoading
                              ? primaryGreen.withOpacity(0.5)
                              : primaryGreen,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryGreen),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Social Button Builder
  Widget _buildSocialButton(
      IconData iconData, String text, VoidCallback? onPressed) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!, width: 1),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData,
                size: 24,
                color: onPressed == null
                    ? Colors.grey
                    : (text == 'Google' ? Colors.red : Colors.blue)),
            const SizedBox(width: 10),
            Text(text,
                style: TextStyle(
                    color: onPressed == null ? Colors.grey : Colors.black,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}