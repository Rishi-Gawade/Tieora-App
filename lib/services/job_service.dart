import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';
import '../utils/location_helper.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CollectionReference jobsCollection =
      FirebaseFirestore.instance.collection('jobs');

  /// =========================================================
  /// 🔹 POST JOB
  /// =========================================================
  Future<void> postJob(JobModel job) async {
    try {
      await jobsCollection.add(
        job.toMap()..removeWhere((key, value) => value == null),
      );
    } catch (e) {
      throw Exception("Failed to post job: $e");
    }
  }

  /// =========================================================
  /// 🔹 OLD REALTIME (KEEP - DO NOT REMOVE)
  /// =========================================================
  Stream<List<JobModel>> getJobs() {
    return jobsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return JobModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// =========================================================
  /// 🔥 NEW: PAGINATION SYSTEM
  /// =========================================================

  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  /// 🔥 FIRST LOAD
  Future<List<JobModel>> getJobsPaginated({
    int limit = 10,
    bool isRefresh = false,
  }) async {
    try {
      if (isRefresh) {
        _lastDocument = null;
        _hasMore = true;
      }

      Query query = jobsCollection
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      if (snapshot.docs.length < limit) {
        _hasMore = false;
      }

      return snapshot.docs.map((doc) {
        return JobModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception("Pagination fetch failed: $e");
    }
  }

  /// =========================================================
  /// 🔹 GET JOB BY ID
  /// =========================================================
  Future<JobModel?> getJobById(String jobId) async {
    try {
      final doc = await jobsCollection.doc(jobId).get();

      if (!doc.exists) return null;

      return JobModel.fromMap(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception("Failed to fetch job: $e");
    }
  }

  /// =========================================================
  /// 🔹 GET JOBS BY EMPLOYER
  /// =========================================================
  Stream<List<JobModel>> getJobsByEmployer(String employerId) {
    return jobsCollection
        .where('postedBy', isEqualTo: employerId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return JobModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// =========================================================
  /// 🔹 DELETE JOB
  /// =========================================================
  Future<void> deleteJob(String jobId) async {
    try {
      await jobsCollection.doc(jobId).delete();
    } catch (e) {
      throw Exception("Failed to delete job: $e");
    }
  }

  /// =========================================================
  /// 🔹 UPDATE JOB
  /// =========================================================
  Future<void> updateJob(String jobId, Map<String, dynamic> data) async {
    try {
      await jobsCollection.doc(jobId).update(data);
    } catch (e) {
      throw Exception("Failed to update job: $e");
    }
  }

  /// =========================================================
  /// 🔥 FILTER SYSTEM (STREAM BASED)
  /// =========================================================
  Stream<List<JobModel>> getFilteredJobsStream({
    String? jobScope,
    bool? isUrgent,
    String? employerType,
  }) {
    Query query = jobsCollection;

    if (jobScope != null) {
      query = query.where('jobScope', isEqualTo: jobScope);
    }

    if (isUrgent != null) {
      query = query.where('isUrgent', isEqualTo: isUrgent);
    }

    if (employerType != null) {
      query = query.where('employerType', isEqualTo: employerType);
    }

    return query
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return JobModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  /// =========================================================
  /// 🔥 FILTER SYSTEM (FUTURE BASED)
  /// =========================================================
  Future<List<JobModel>> getFilteredJobs({
    String? category,
    String? jobScope,
  }) async {
    try {
      Query query = jobsCollection;

      if (category != null && category != "All") {
        query = query.where('category', isEqualTo: category);
      }

      if (jobScope != null) {
        query = query.where('jobScope', isEqualTo: jobScope);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        return JobModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception("Failed to fetch filtered jobs: $e");
    }
  }

  /// =========================================================
  /// 🔥 NEARBY JOBS
  /// =========================================================
  Future<List<JobModel>> getNearbyJobs({
    required GeoPoint userLocation,
    double radiusKm = 5,
  }) async {
    try {
      final snapshot = await jobsCollection.get();

      List<JobModel> nearbyJobs = [];

      for (var doc in snapshot.docs) {
        final job = JobModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        if (job.locationGeo == null) continue;

        final distance = LocationHelper.calculateDistance(
          userLocation,
          job.locationGeo!,
        );

        if (distance <= radiusKm) {
          nearbyJobs.add(job);
        }
      }

      return nearbyJobs;
    } catch (e) {
      throw Exception("Failed to fetch nearby jobs: $e");
    }
  }

  /// =========================================================
  /// 🔥 ADVANCED FILTER SYSTEM
  /// =========================================================
  Future<List<JobModel>> getFilteredJobsAdvanced({
    required GeoPoint userLocation,
    required String userCity,
    String filterType = "nearby",
    double radiusKm = 10,
  }) async {
    try {
      final snapshot = await jobsCollection.get();

      List<JobModel> filteredJobs = [];

      for (var doc in snapshot.docs) {
        final job = JobModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        if (filterType == "nearby") {
          if (job.locationGeo == null) continue;

          final distance = LocationHelper.calculateDistance(
            userLocation,
            job.locationGeo!,
          );

          if (distance <= radiusKm) {
            filteredJobs.add(job);
          }
        } else if (filterType == "city") {
          final location = (job.locationText ?? "").toLowerCase();

          if (location.contains(userCity.toLowerCase())) {
            filteredJobs.add(job);
          }
        } else if (filterType == "other") {
          final location = (job.locationText ?? "").toLowerCase();

          if (!location.contains(userCity.toLowerCase())) {
            filteredJobs.add(job);
          }
        } else if (filterType == "remote") {
          if (job.jobScope == "remote") {
            filteredJobs.add(job);
          }
        }
      }

      return filteredJobs;
    } catch (e) {
      throw Exception("Advanced filter error: $e");
    }
  }
}