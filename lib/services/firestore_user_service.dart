import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUserService {
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> createUser({
    required String uid,
    required String fullName,
    required String email,
    required String userType,

    /// 🔥 NEW REQUIRED
    required GeoPoint locationGeo,
    required String locationText,

    String? phone,
  }) async {
    try {
      await usersCollection.doc(uid).set({
        "uid": uid,

        /// 🔥 STANDARD NAME (REMOVE CONFUSION)
        "fullName": fullName,

        "email": email,

        /// 🔥 KEEP OLD + NEW
        "userType": userType,
        "role": userType,

        "phone": phone ?? "",

        /// 🔥 PROFILE DEFAULTS
        "skills": [],
        "experienceLevel": "",
        "availability": "",
        "rating": 0.0,

        /// 🔥 LOCATION (MANDATORY)
        "locationGeo": locationGeo,
        "locationText": locationText,

        /// 🔥 TIMESTAMPS
        "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error creating user: $e");
      rethrow;
    }
  }
}