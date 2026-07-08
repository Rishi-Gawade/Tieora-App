import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployerDashboard extends StatefulWidget {
  const EmployerDashboard({super.key});

  @override
  State<EmployerDashboard> createState() => _EmployerDashboardState();
}

class _EmployerDashboardState extends State<EmployerDashboard> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String get employerId => _auth.currentUser!.uid;

  Stream<QuerySnapshot> getJobs() {
    return _firestore
        .collection('jobs')
        .where('postedBy', isEqualTo: employerId)
        .snapshots();
  }

  Stream<QuerySnapshot> getApplications() {
    return _firestore
        .collection('applications')
        .where('employerId', isEqualTo: employerId)
        .snapshots();
  }

  Widget statCard(IconData icon, String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value.toString(),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget insightBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget jobCard(DocumentSnapshot job) {
    final data = job.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? '',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(data['locationText'] ?? '',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/applicants',
                  arguments: job.id);
            },
            child: const Text("View"),
          )
        ],
      ),
    );
  }

  Widget _quickActionCard({
  required IconData icon,
  required String title,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(18),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [

          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(.12),
            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/post-job");
        },
        child: const Icon(Icons.add),
      ),

     body: SafeArea(
      child: SingleChildScrollView(
        child: Container(
          color: const Color(0xfff5f6fa),
          padding: const EdgeInsets.all(16),

            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

             Row(
              children: [

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Good Morning 👋",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),  

          const SizedBox(height: 6),

          const Text(
            "Employer Dashboard",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

              const Text(
                "Manage your hiring efficiently",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(
              Icons.business,
              color: Colors.blue,
              size: 30,
            ),
          ),
        ],
      ),

              const SizedBox(height: 24),

              /// 🔥 STATS + INSIGHTS
              StreamBuilder<QuerySnapshot>(
                stream: getJobs(),
                builder: (context, jobSnap) {

                  int jobs = jobSnap.data?.docs.length ?? 0;

                  return StreamBuilder<QuerySnapshot>(
                    stream: getApplications(),
                    builder: (context, appSnap) {

                      final apps = appSnap.data?.docs ?? [];

                      int applicants = apps.length;
                      int hired = apps.where((a) {
                        final d = a.data() as Map<String, dynamic>;
                        return d["status"] == "hired";
                      }).length;

                      return Column(
                        children: [

                          Row(
                            children: [
                              Expanded(child: statCard(Icons.work, "Jobs", jobs, Colors.blue)),
                              const SizedBox(width: 10),
                              Expanded(child: statCard(Icons.people, "Applicants", applicants, Colors.green)),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(child: statCard(Icons.check, "Hired", hired, Colors.purple)),
                              const SizedBox(width: 10),
                              Expanded(child: statCard(Icons.visibility, "Active", jobs, Colors.orange)),
                            ],
                          ),

                          const SizedBox(height: 16),

                          /// 🔥 INSIGHTS
                          if (jobs == 0)
                            insightBox("Post your first job to start hiring 🚀")
                          else if (applicants == 0)
                            insightBox("Your jobs have low visibility ⚠️ Try improving description")
                          else
                            insightBox("Great! Your jobs are getting attention 🎯"),

                          /// 🔥 SMART TIP
                          insightBox("Tip: Jobs with salary get 3x more applicants 💡"),
                        ],
                      );
                    },
                  );
                },
              ),

const SizedBox(height: 20),

const Text(
  "Quick Actions",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 12),

Row(
  children: [

    Expanded(
      child: _quickActionCard(
        icon: Icons.add_circle_outline,
        title: "Post Job",
        color: Colors.blue,
        onTap: () {
          Navigator.pushNamed(context, "/post-job");
        },
      ),
    ),

    const SizedBox(width: 12),

    Expanded(
      child: _quickActionCard(
        icon: Icons.work_outline,
        title: "My Jobs",
        color: Colors.green,
        onTap: () {
          Navigator.pushNamed(context, "/my-jobs");
        },
      ),
    ),

    const SizedBox(width: 12),

    Expanded(
      child: _quickActionCard(
        icon: Icons.people_outline,
        title: "Applicants",
        color: Colors.orange,
        onTap: () {
          Navigator.pushNamed(context, "/my-jobs");
        },
      ),
    ),
  ],
),

const SizedBox(height: 24),

const Text(
  "Recent Activity",
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 10),

                SizedBox(
                  height: 260,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: getApplications(),
                    builder: (context, snapshot) {

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No recent activity"));
                      }

                      final apps = snapshot.data!.docs.take(5).toList();

                      return ListView.builder(
                        itemCount: apps.length,
                        itemBuilder: (context, index) {

                          final data =
                              apps[index].data() as Map<String, dynamic>;

                          return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [

                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.blue.shade50,
                            child: const Icon(
                              Icons.person,
                              color: Colors.blue,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text(
                                  "${data["name"] ?? "Someone"}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  "Applied for ${data["jobTitle"] ?? ""}",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "New",
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
     ),
    );
  }
}