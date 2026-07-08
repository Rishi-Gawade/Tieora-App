import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'employer_dashboard.dart';
import 'my_jobs_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import 'company_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:badges/badges.dart' as badges;

class EmployerHome extends StatefulWidget {
  const EmployerHome({super.key});

  @override
  State<EmployerHome> createState() => _EmployerHomeState();
}

class _EmployerHomeState extends State<EmployerHome> {

  int _selectedIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const EmployerDashboard(),
    const MyJobsScreen(),
    const NotificationsScreen(),
  ];

  void _onItemTapped(int index) {

    if (index == 3) {
      _scaffoldKey.currentState?.openEndDrawer();
      return;
    }

    if (index >= 0 && index < _screens.length) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(

      key: _scaffoldKey,

      body: _screens[_selectedIndex],

      /// 🔥 PREMIUM ANIMATED DRAWER
      endDrawer: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 300),
        tween: Tween(begin: 0.9, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Drawer(
          child: SafeArea(
            child: Column(
              children: [

                /// 🔷 MODERN HEADER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2E5BFF),
                        Color(0xFF4DA0FF),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            color: Colors.blue, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            /// 🔥 NAME + VERIFIED BADGE
                            Row(
                              children: [
                                Text(
                                  user?.displayName ?? "Employer",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),

                                /// ✅ VERIFIED BADGE (READY)
                                const Icon(
                                  Icons.verified,
                                  color: Colors.greenAccent,
                                  size: 18,
                                ),
                              ],
                            ),

                            const SizedBox(height: 4),

                            Text(
                              user?.email ?? "",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),

                            const SizedBox(height: 6),

                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const ProfileScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Edit Profile",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                /// 🔥 SCROLLABLE CONTENT (IMPORTANT)
                Expanded(
                  child: ListView(
                    children: [

                      /// 🔹 ACCOUNT
                      _sectionTitle("ACCOUNT"),

                      _tile(Icons.person, "Profile", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      }),

                      _tile(Icons.business, "My Company Profile", () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CompanyProfileScreen(),
                          ),
                        );
                      }),

                      _tile(Icons.settings, "Settings", () {}),
                      _tile(Icons.lock, "Change Password", () {}),

                      const Divider(),

                      /// 🔹 SUPPORT
                      _sectionTitle("SUPPORT"),

                      _tile(Icons.help_outline, "Help Center", () {}),
                      _tile(Icons.info_outline, "About Tieora", () {}),
                    ],
                  ),
                ),

                /// 🔴 LOGOUT BUTTON
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();

                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        "/login",
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: "My Jobs",
          ),
          BottomNavigationBarItem(
            label: "Notifications",
            icon: uid == null
                ? const Icon(Icons.notifications_none)
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(uid)
                        .collection('items')
                        .where('isRead', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final unread = snapshot.data?.docs.length ?? 0;

                      return badges.Badge(
                        showBadge: unread > 0,
                        badgeContent: Text(
                          unread > 99 ? '99+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        child: const Icon(Icons.notifications_none),
                      );
                    },
                  ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: "More",
          ),
        ],
      ),
    );
  }

  Widget _tile(
      IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}