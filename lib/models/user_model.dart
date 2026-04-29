import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String email;

  final String userType;
  final String role;

  final String? phone;

  final List<String> skills;
  final String? experienceLevel;
  final String? availability;
  final double rating;

  final GeoPoint locationGeo;
  final String locationText;

  // 🚀 NEW FIELDS
  final List<String> preferredDomains;
  final int radiusPreference; // km
  final String? city;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.userType,
    required this.role,
    this.phone,
    this.skills = const [],
    this.experienceLevel,
    this.availability,
    this.rating = 0.0,
    required this.locationGeo,
    required this.locationText,

    /// 🚀 NEW
    this.preferredDomains = const [],
    this.radiusPreference = 10,
    this.city,

    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'userType': userType,
      'role': role,
      'phone': phone,
      'skills': skills,
      'experienceLevel': experienceLevel,
      'availability': availability,
      'rating': rating,
      'locationGeo': locationGeo,
      'locationText': locationText,

      /// 🚀 NEW
      'preferredDomains': preferredDomains,
      'radiusPreference': radiusPreference,
      'city': city,

      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      userType: map['userType'] ?? '',
      role: map['role'] ?? map['userType'] ?? 'seeker',
      phone: map['phone'],
      skills: map['skills'] != null
          ? List<String>.from(map['skills'])
          : [],
      experienceLevel: map['experienceLevel'],
      availability: map['availability'],
      rating: map['rating'] != null
          ? (map['rating'] as num).toDouble()
          : 0.0,

      locationGeo: map['locationGeo'] ??
          map['location'] ??
          const GeoPoint(0, 0),

      locationText: map['locationText'] ?? "Unknown",

      /// 🚀 NEW SAFE READ
      preferredDomains: map['preferredDomains'] != null
          ? List<String>.from(map['preferredDomains'])
          : [],
      radiusPreference: map['radiusPreference'] ?? 10,
      city: map['city'],

      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,

      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? userType,
    String? role,
    String? phone,
    List<String>? skills,
    String? experienceLevel,
    String? availability,
    double? rating,
    GeoPoint? locationGeo,
    String? locationText,
    List<String>? preferredDomains,
    int? radiusPreference,
    String? city,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      userType: userType ?? this.userType,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      skills: skills ?? this.skills,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      availability: availability ?? this.availability,
      rating: rating ?? this.rating,
      locationGeo: locationGeo ?? this.locationGeo,
      locationText: locationText ?? this.locationText,

      /// 🚀 NEW
      preferredDomains: preferredDomains ?? this.preferredDomains,
      radiusPreference: radiusPreference ?? this.radiusPreference,
      city: city ?? this.city,

      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}