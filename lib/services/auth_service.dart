import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'face_auth_service.dart';
import '../config/firebase_config.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _faceAuthService = FaceAuthService();

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user profile in Firestore
    await _firestore
        .collection(FirebaseConfig.usersCollection)
        .doc(userCredential.user!.uid)
        .set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return userCredential;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<(bool, String)> registerFace({
    required String userId,
    required String imagePath,
  }) async {
    return await _faceAuthService.registerFace(
      userId,
      File(imagePath),
    );
  }

  Future<bool> signInWithFace({
    required String email,
    required String imagePath,
  }) async {
    try {
      // First, get the user ID associated with the email
      final querySnapshot = await _firestore
          .collection(FirebaseConfig.usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return false;
      }

      final userId = querySnapshot.docs.first.id;
      
      // Verify face
      final (success, _) = await _faceAuthService.verifyFace(
        userId,
        File(imagePath),
      );
      
      if (success) {
        // If face matches, get the user's auth token
        final userDoc = await _firestore
            .collection(FirebaseConfig.usersCollection)
            .doc(userId)
            .get();
            
        if (userDoc.exists) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error signing in with face: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  bool get isAuthenticated => _auth.currentUser != null;
  
  String? get currentUserId => _auth.currentUser?.uid;

  void dispose() {
    _faceAuthService.dispose();
  }
} 