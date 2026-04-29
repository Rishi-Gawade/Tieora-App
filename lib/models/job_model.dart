import 'package:cloud_firestore/cloud_firestore.dart';

class JobModel {
  final String id; // ✅ FIXED (non-null)

  final String title;
  final String shortDescription;
  final String description;
  final String category;
  final String wage;

  final String postedBy;
  final String postedByName;

  final String? locationText;
  final GeoPoint? locationGeo;

  final DateTime? timestamp;
  final DateTime? updatedAt;

  // 🔥 EXISTING
  final String? jobScope; // local | city | remote
  final bool? isUrgent;
  final String? employerType;
  final double? salary;

  // 🚀 NEW FIELDS
  final String? city;
  final String? domain;

  JobModel({
    required this.id, // ✅ REQUIRED NOW
    required this.title,
    required this.shortDescription,
    required this.description,
    required this.category,
    required this.wage,
    required this.postedBy,
    required this.postedByName,
    this.locationText,
    this.locationGeo,
    this.timestamp,
    this.updatedAt,
    this.jobScope,
    this.isUrgent,
    this.employerType,
    this.salary,
    this.city,
    this.domain,
  });

  Map<String, dynamic> toMap() {
    return {
      "title": title,
      "shortDescription": shortDescription,
      "description": description,
      "category": category,
      "wage": wage,
      "postedBy": postedBy,
      "postedByName": postedByName,
      "locationText": locationText,
      "locationGeo": locationGeo,

      "timestamp": timestamp ?? FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),

      "jobScope": jobScope ?? "local",
      "isUrgent": isUrgent ?? false,
      "employerType": employerType ?? "individual",
      "salary": salary,

      "city": city,
      "domain": domain,
    };
  }

  factory JobModel.fromMap(Map<String, dynamic> map, String id) {
    return JobModel(
      id: id, // ✅ ALWAYS AVAILABLE FROM FIRESTORE
      title: map['title'] ?? '',
      shortDescription: map['shortDescription'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      wage: map['wage'] ?? '',
      postedBy: map['postedBy'] ?? '',
      postedByName: map['postedByName'] ?? '',
      locationText: map['locationText'],
      locationGeo: map['locationGeo'],

      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,

      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,

      jobScope: map['jobScope'] ?? 'local',
      isUrgent: map['isUrgent'] ?? false,
      employerType: map['employerType'] ?? 'individual',
      salary: map['salary'] != null
          ? (map['salary'] as num).toDouble()
          : null,

      city: map['city'],
      domain: map['domain'],
    );
  }

  JobModel copyWith({
    String? id,
    String? title,
    String? shortDescription,
    String? description,
    String? category,
    String? wage,
    String? postedBy,
    String? postedByName,
    String? locationText,
    GeoPoint? locationGeo,
    DateTime? timestamp,
    DateTime? updatedAt,
    String? jobScope,
    bool? isUrgent,
    String? employerType,
    double? salary,
    String? city,
    String? domain,
  }) {
    return JobModel(
      id: id ?? this.id,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      category: category ?? this.category,
      wage: wage ?? this.wage,
      postedBy: postedBy ?? this.postedBy,
      postedByName: postedByName ?? this.postedByName,
      locationText: locationText ?? this.locationText,
      locationGeo: locationGeo ?? this.locationGeo,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      jobScope: jobScope ?? this.jobScope,
      isUrgent: isUrgent ?? this.isUrgent,
      employerType: employerType ?? this.employerType,
      salary: salary ?? this.salary,
      city: city ?? this.city,
      domain: domain ?? this.domain,
    );
  }
}