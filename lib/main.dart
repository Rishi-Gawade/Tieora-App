import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🔥 NEW (FCM)
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';

// 🔥 EXISTING
import 'services/notification_write_service.dart';
import 'services/notification_service.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/employer/employer_home.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/common/profile_screen.dart';
import 'screens/seeker/seeker_main_screen.dart';
import 'screens/employer/post_job_screen.dart';
import 'screens/employer/my_jobs_screen.dart';
import 'screens/employer/applicants/applicants_screen.dart';

// Theme
import 'core/theme/app_theme.dart';

/// 🔥 BACKGROUND HANDLER (VERY IMPORTANT)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint("🔔 Background Notification: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// 🔥 REGISTER BACKGROUND HANDLER
  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

  /// 🔥 INIT FCM
  await NotificationService().init();

  runApp(const TieoraApp());
}

class TieoraApp extends StatefulWidget {
  const TieoraApp({super.key});

  static _TieoraAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_TieoraAppState>()!;

  @override
  State<TieoraApp> createState() => _TieoraAppState();
}

class _TieoraAppState extends State<TieoraApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tieora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/seeker': (context) => const SeekerMainScreen(),
        '/employer': (context) => const EmployerHome(),
        '/profile': (context) => const ProfileScreen(),
        '/post-job': (context) => const PostJobScreen(),
        '/my-jobs': (context) => const MyJobsScreen(),

        /// ⚠️ SAFE ARGUMENT HANDLING
        '/applicants': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as String?;
          return ApplicantsScreen(jobId: args ?? '');
        },
      },

      home: const RootDecider(),
    );
  }
}

class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        /// 🔥 LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        /// 🔥 NOT LOGGED IN
        if (!snapshot.hasData || snapshot.data == null) {
          debugPrint("User not logged in");
          return const LoginScreen();
        }

        final user = snapshot.data!;
        debugPrint("User logged in: ${user.uid}");

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection("users")
              .doc(user.uid)
              .get(),
          builder: (context, snap) {

            /// 🔥 LOADING
            if (snap.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            /// ❌ ERROR HANDLING
            if (snap.hasError) {
              debugPrint("Firestore error: ${snap.error}");
              return const LoginScreen();
            }

            /// 🔥 NO DATA
            if (!snap.hasData || !snap.data!.exists) {
              debugPrint("User document not found");
              return const LoginScreen();
            }

            final data =
                snap.data!.data() as Map<String, dynamic>?;

            /// 🔥 INVALID DATA
            if (data == null) {
              debugPrint("User data is null");
              return const LoginScreen();
            }

            final role = data["userType"]?.toString();

            debugPrint("User role: $role");

            /// 🔥 STRICT ROLE HANDLING
            if (role == "seeker") {
              return const SeekerMainScreen();
            } else if (role == "employer") {
              return const EmployerHome();
            } else {
              debugPrint("Invalid role detected");
              return const LoginScreen();
            }
          },
        );
      },
    );
  }
}