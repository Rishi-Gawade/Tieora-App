import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String applicationId;
  final String jobId;
  final String jobTitle;
  final String seekerId;
  final String employerId;
  final String name;
  final String email;
  final String phone;
  final String skills;
  final String locationText;
  final String status;

  /// 🚀 EXISTING
  final String? workLocationLink;

  /// 🔥 NEW (RATINGS SYSTEM)
  final bool isCompleted;
  final bool seekerRated;
  final bool employerRated;

  final DateTime createdAt;

  ApplicationModel({
    required this.applicationId,
    required this.jobId,
    required this.jobTitle,
    required this.seekerId,
    required this.employerId,
    required this.name,
    required this.email,
    required this.phone,
    required this.skills,
    required this.locationText,
    required this.status,

    this.workLocationLink,

    /// 🔥 NEW
    this.isCompleted = false,
    this.seekerRated = false,
    this.employerRated = false,

    required this.createdAt,
  });

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ApplicationModel(
      applicationId: doc.id,
      jobId: data['jobId'] ?? '',
      jobTitle: data['jobTitle'] ?? '',
      seekerId: data['seekerId'] ?? '',
      employerId: data['employerId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      skills: data['skills'] ?? '',
      locationText: data['locationText'] ?? '',
      status: data['status'] ?? 'pending',

      workLocationLink: data['workLocationLink'],

      /// 🔥 SAFE READ
      isCompleted: data['isCompleted'] ?? false,
      seekerRated: data['seekerRated'] ?? false,
      employerRated: data['employerRated'] ?? false,

      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'seekerId': seekerId,
      'employerId': employerId,
      'name': name,
      'email': email,
      'phone': phone,
      'skills': skills,
      'locationText': locationText,
      'status': status,
      'workLocationLink': workLocationLink,

      /// 🔥 NEW
      'isCompleted': isCompleted,
      'seekerRated': seekerRated,
      'employerRated': employerRated,

      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ApplicationModel copyWith({
    String? applicationId,
    String? jobId,
    String? jobTitle,
    String? seekerId,
    String? employerId,
    String? name,
    String? email,
    String? phone,
    String? skills,
    String? locationText,
    String? status,
    String? workLocationLink,

    /// 🔥 NEW
    bool? isCompleted,
    bool? seekerRated,
    bool? employerRated,

    DateTime? createdAt,
  }) {
    return ApplicationModel(
      applicationId: applicationId ?? this.applicationId,
      jobId: jobId ?? this.jobId,
      jobTitle: jobTitle ?? this.jobTitle,
      seekerId: seekerId ?? this.seekerId,
      employerId: employerId ?? this.employerId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      skills: skills ?? this.skills,
      locationText: locationText ?? this.locationText,
      status: status ?? this.status,
      workLocationLink: workLocationLink ?? this.workLocationLink,

      /// 🔥 NEW
      isCompleted: isCompleted ?? this.isCompleted,
      seekerRated: seekerRated ?? this.seekerRated,
      employerRated: employerRated ?? this.employerRated,

      createdAt: createdAt ?? this.createdAt,
    );
  }
}