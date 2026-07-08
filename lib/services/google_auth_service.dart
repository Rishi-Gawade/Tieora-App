import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // 🔥 IMPORTANT

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔥 FIX: HANDLE WEB + MOBILE
final GoogleSignIn _googleSignIn = GoogleSignIn(
  clientId:
      "381372828858-evk3kmd38jd0u09uikis291q7l3fsoh7.apps.googleusercontent.com",
);

  Future<User?> signInWithGoogle(String role) async {
    try {
      final GoogleSignInAccount? googleUser =
          await _googleSignIn.signIn();

      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _auth.signInWithCredential(credential);

      final user = userCredential.user;

      if (user == null) return null;

      /// 🔥 CHECK IF USER EXISTS
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        /// 🔥 CREATE USER
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          "uid": user.uid,
          "fullName": user.displayName ?? "",
          "email": user.email ?? "",
          "phone": user.phoneNumber ?? "",
          "userType": role,
          "skills": [],
          "experienceLevel": "",
          "availability": "",
          "rating": 0,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      return user;

    } catch (e) {
      throw Exception("Google sign-in failed: $e");
    }
  }
}