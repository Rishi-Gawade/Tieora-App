import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/application_model.dart';
import 'notification_write_service.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationWriteService _notificationService =
      NotificationWriteService();

  /// 🔥 APPLY TO JOB
  Future<void> applyToJob(
    ApplicationModel application, {
    required String employerId,
    required String jobTitle,
  }) async {
    try {

      /// 🔥 OPTIONAL SAFETY (avoid duplicate apply)
      final existing = await _firestore
          .collection('applications')
          .where('jobId', isEqualTo: application.jobId)
          .where('seekerId', isEqualTo: application.seekerId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint("⚠️ Already applied");
        return;
      }

      /// 🔹 CREATE DOC FIRST
      final docRef =
          _firestore.collection('applications').doc();

      /// 🔥 SAVE WITH ID (VERY IMPORTANT FIX)
      await docRef.set({
        ...application.toMap(),
        "applicationId": docRef.id, // ✅ FIX
      });

      debugPrint("✅ Application submitted: ${docRef.id}");
      
      debugPrint("========== APPLICATION DEBUG ==========");
      debugPrint("Employer ID => $employerId");
      debugPrint("Job Title => $jobTitle");
      debugPrint("Seeker Name => ${application.name}");
      debugPrint("Seeker ID => ${application.seekerId}");
      debugPrint("Job ID => ${application.jobId}");


      /// 🔥 SEND NOTIFICATION TO EMPLOYER
      await _notificationService.createNotification(
        userId: employerId,
        type: "application",
        title: "New Application",
        body: "${application.name} applied",
        jobId: application.jobId,
        jobTitle: jobTitle,

        /// 🔥 IMPORTANT
        senderId: application.seekerId,
        senderName: application.name,
      );

    } catch (e) {
      debugPrint("❌ Apply error: $e");
      throw Exception("Failed to apply");
    }
  }

  /// 🔥 UPDATE APPLICATION STATUS
  Future<void> updateStatus({
    required String applicationId,
    required String status,
    required String seekerId,
    required String jobTitle,
    required String jobId,
  }) async {
    try {
      await _firestore
          .collection('applications')
          .doc(applicationId)
          .update({
        "status": status,
      });

      /// 🔥 SEND NOTIFICATION TO SEEKER


      await _notificationService.createNotification(
        userId: seekerId,
        type: status == "accepted"
            ? "Hired"
            : status == "rejected"
                ? "rejected"
                : "application",
        title: status == "accepted"
            ? "Application Accepted"
            : status == "rejected"
                ? "Application Rejected"
                : "Application Update",
        body: status == "accepted"
            ? "Congratulations! You have been selected for $jobTitle"
            : status == "rejected"
                ? "Your application for $jobTitle was not selected."
                : "Your application for $jobTitle was updated.",
        jobId: jobId,
        jobTitle: jobTitle,
        senderId: "employer",
        senderName: "Employer",
      );

    } catch (e) {
      debugPrint("❌ Status update error: $e");
    }
  }
}