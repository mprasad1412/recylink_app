import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Verify user is admin
      if (credential.user != null) {
        final adminDoc = await _firestore
            .collection('admins')
            .doc(credential.user!.uid)
            .get();

        if (!adminDoc.exists || adminDoc.data()?['role'] != 'admin') {
          await _auth.signOut();
          throw Exception('Unauthorized: Not an admin user');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found with this email');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if current user is admin
  Future<bool> isAdmin() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      return adminDoc.exists && adminDoc.data()?['role'] == 'admin';
    } catch (e) {
      return false;
    }
  }
}