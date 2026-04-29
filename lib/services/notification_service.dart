import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔥 INIT FCM
  Future<void> init() async {
    try {
      /// 🔥 REQUEST PERMISSION
      NotificationSettings settings =
          await _fcm.requestPermission();

      debugPrint(
          "Permission: ${settings.authorizationStatus}");

      /// 🔥 GET TOKEN
      await _saveToken();

      /// 🔥 TOKEN REFRESH (VERY IMPORTANT)
      _fcm.onTokenRefresh.listen((newToken) async {
        debugPrint("New FCM Token: $newToken");
        await _saveToken(newToken);
      });

      /// 🔥 FOREGROUND MESSAGE
      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          debugPrint(
              "Foreground notification: ${message.notification?.title}");

          /// 👉 You can later show local notification here
        },
      );

      /// 🔥 WHEN USER CLICKS NOTIFICATION (APP OPEN)
      FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) {
          debugPrint("Notification clicked (background)");

          _handleNotificationClick(message);
        },
      );

      /// 🔥 WHEN APP OPENED FROM TERMINATED STATE
      RemoteMessage? initialMessage =
          await _fcm.getInitialMessage();

      if (initialMessage != null) {
        debugPrint("Notification opened from terminated");
        _handleNotificationClick(initialMessage);
      }

    } catch (e) {
      debugPrint("FCM init error: $e");
    }
  }

  /// 🔥 SAVE TOKEN
  Future<void> _saveToken([String? tokenParam]) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final token = tokenParam ?? await _fcm.getToken();

      if (token == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'fcmToken': token,
      }, SetOptions(merge: true));

      debugPrint("FCM token saved");
    } catch (e) {
      debugPrint("Token save error: $e");
    }
  }

  /// 🔥 HANDLE CLICK (FUTURE NAVIGATION)
  void _handleNotificationClick(RemoteMessage message) {
    try {
      final data = message.data;

      debugPrint("Notification data: $data");

      /// 🚀 You will connect this later with Navigator
      /// Example:
      /// type = message / application

    } catch (e) {
      debugPrint("Click handle error: $e");
    }
  }
}