import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:recall/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  
  // 1. Get the reference to the singleton instance
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  // 2. Initialize the configuration in the constructor
  AuthRepositoryImpl() {
    googleSignIn.initialize(
      serverClientId: '967862201042-7u5qt51jk66tou96pln4jhg8q3fh7bq2.apps.googleusercontent.com',
    );
  }

  // Stream to listen to auth state changes
  @override
  Stream<User?> get user => firebaseAuth.authStateChanges();

  // Get the current user immediately
  @override
  User? get currentUser => firebaseAuth.currentUser;

  @override
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // 3. Trigger the authentication flow
      // Note: In the new SDK, this throws an exception if cancelled by user
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
      
      // Obtain the auth details (Wait for the Future to complete)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: null,
      );

      // Once signed in, return the UserCredential
      return await firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await googleSignIn.signOut();
    await firebaseAuth.signOut();
  }
}