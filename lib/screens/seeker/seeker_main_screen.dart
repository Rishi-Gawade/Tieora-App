import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';

import 'jobs/seeker_jobs_screen.dart';
import '../common/messages_list_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';

class SeekerMainScreen extends StatefulWidget {
  const SeekerMainScreen({super.key});

  @override
  State<SeekerMainScreen> createState() =>
      _SeekerMainScreenState();
}

class _SeekerMainScreenState
    extends State<SeekerMainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SeekerJobsScreen(),
    MessagesListScreen(),
    NotificationsScreen(),
    SizedBox(),
  ];

  void _onTabTapped(int index) {
    if (index == 3) {
      _scaffoldKey.currentState?.openDrawer();
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      /// 🔥 NOTIFICATION BADGE
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppTheme.primaryBlue,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home"),

          const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: "Messages"),

          BottomNavigationBarItem(
            label: "Notifications",
            icon: uid == null
                ? const Icon(Icons.notifications)
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(uid)
                        .collection('items')
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return const Icon(Icons.notifications);
                      }

                      final count = snap.hasData
                          ? snap.data!.docs.length
                          : 0;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications),
                          if (count > 0)
                            Positioned(
                              right: -6,
                              top: -4,
                              child: Container(
                                padding:
                                    const EdgeInsets.all(4),
                                decoration:
                                    const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints:
                                    const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Center(
                                  child: Text(
                                    count > 9
                                        ? '9+'
                                        : '$count',
                                    style:
                                        const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),

          const BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: "More"),
        ],
      ),
    );
  }

  /// 🔥 UPDATED MODERN DRAWER
  Drawer _buildDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [

            /// 🔵 MODERN HEADER
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(16, 40, 16, 20),
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ??
                              "Job Seeker",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 16,
                          ),
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
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),

            /// 🔹 ACCOUNT
            _drawerSection("ACCOUNT"),

            _drawerTile(
              icon: Icons.person_outline,
              title: "Profile",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ProfileScreen(),
                  ),
                );
              },
            ),

            _drawerTile(
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: () {},
            ),

            _drawerTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: () {},
            ),

            const Divider(),

            /// 🔹 SUPPORT
            _drawerSection("SUPPORT"),

            _drawerTile(
              icon: Icons.help_outline,
              title: "Help Center",
              onTap: () {},
            ),

            _drawerTile(
              icon: Icons.info_outline,
              title: "About Tieora",
              onTap: () {},
            ),

            const Spacer(),

            /// 🔴 LOGOUT
            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label:
                    const Text("Logout"),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize:
                      const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  await FirebaseAuth
                      .instance
                      .signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (_) => false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerSection(String title) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8),
      child: Align(
        alignment:
            Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight:
                FontWeight.bold,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon,
          color: AppTheme.primaryBlue),
      title: Text(title),
      trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14),
      onTap: onTap,
    );
  }
}