import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recylink/screens/main_screen.dart';
import 'package:recylink/screens/login_screen.dart';

import '../services/firestore_init_helper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Define common colors
  static const Color backgroundColor = Color(0xFFF5FFED);
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color darkGreenText = Color(0xFF4D8000);

  // Initialize Firebase Auth, Firestore and Google Sign-In
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(
    scopes: <String>['email', 'profile'],
  );

  // Email/Password Sign Up
  Future<void> _handleEmailPasswordSignUp() async {
    // Validation with detailed error messages
    final nameError = _validateUsername(_nameController.text);
    if (nameError != null) {
      _showSnackBar(nameError);
      return;
    }

    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      _showSnackBar(emailError);
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showSnackBar('Please enter a password');
      return;
    }
    if (_passwordController.text.length < 6) {
      _showSnackBar('Password must be at least 6 characters');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackBar('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user with email and password
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // Store additional user data in Firestore
      try {
        await FirestoreInitHelper.createUserProfile(
          uid: userCredential.user!.uid,
          email: _emailController.text.trim(),
          username: _nameController.text.trim(),
        );
      } catch (firestoreError) {
        debugPrint('⚠️ Firestore write failed: $firestoreError');
        // Continue anyway - user is created in Auth
      }

      debugPrint('✅ Email Sign-Up successful');
      debugPrint('User: ${userCredential.user?.email}');
      debugPrint('UID: ${userCredential.user?.uid}');

      if (mounted) {
        _showSnackBar('Account created successfully!');
        // Navigate to main screen
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
        case 'email-already-in-use':
          errorMessage = 'This email is already registered';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        default:
          errorMessage = 'Sign up failed: ${e.message}';
      }
      _showSnackBar(errorMessage);
      debugPrint('❌ Email Sign-up failed: ${e.code} - ${e.message}');
    } catch (e) {
      _showSnackBar('An error occurred: $e');
      debugPrint('❌ Email Sign-up error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Google Sign Up
  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);

    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _showSnackBar('Google Sign-up cancelled');
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

      // Sign up/Sign in to Firebase with Google credential
      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      // Check if this is a new user
      final bool isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      // Store user data in Firestore (only if new user)
      // Store user data in Firestore (only if new user)
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

      debugPrint('✅ Google Sign-Up successful');
      debugPrint('User: ${userCredential.user?.displayName}');
      debugPrint('Email: ${userCredential.user?.email}');
      debugPrint('UID: ${userCredential.user?.uid}');
      debugPrint('Is New User: $isNewUser');

      if (mounted) {
        _showSnackBar(isNewUser
            ? 'Account created successfully!'
            : 'Signed in successfully!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(cameras: const []),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Google Sign-up failed: ${e.message}');
      debugPrint('❌ Google Sign-up failed: ${e.code} - ${e.message}');
    } catch (error) {
      _showSnackBar('Google Sign-up failed: $error');
      debugPrint('❌ Google Sign-up error: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ========== VALIDATION METHODS ==========

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

  String? _validateUsername(String username) {
    if (username.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (username.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (username.trim().length > 30) {
      return 'Username must not exceed 30 characters';
    }
    // Allow letters, numbers, spaces, underscores
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_ ]+$');
    if (!usernameRegex.hasMatch(username.trim())) {
      return 'Username can only contain letters, numbers, spaces, and underscores';
    }
    return null;
  }

  String? _validatePhone(String phone) {
    if (phone.trim().isEmpty) {
      return null; // Phone is optional
    }
    // Remove spaces and dashes for validation
    final cleanPhone = phone.replaceAll(RegExp(r'[\s-]'), '');
    // Malaysian phone: 10-11 digits, can start with 0 or 60
    if (cleanPhone.length < 10 || cleanPhone.length > 11) {
      return 'Phone number must be 10-11 digits';
    }
    // Check if all characters are digits
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanPhone)) {
      return 'Phone number can only contain digits';
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
                  'Create account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Sign up to get started!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 40),
                // Name Input
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.person_outline),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 20),
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
                    hintText: 'Create a password (min 6 characters)',
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
                const SizedBox(height: 20),
                // Confirm Password Input
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter your password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 40),
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailPasswordSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      disabledBackgroundColor: primaryGreen.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
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
                // Google Sign-up Button
                _buildGoogleButton(),
                const SizedBox(height: 40),
                // Already have an account? Sign In
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'Sign In',
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

  // Google Button (full width)
  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignUp,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!, width: 1),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.google,
                size: 24,
                color: _isLoading ? Colors.grey : Colors.red),
            const SizedBox(width: 10),
            Text('Google',
                style: TextStyle(
                    color: _isLoading ? Colors.grey : Colors.black,
                    fontSize: 16)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}