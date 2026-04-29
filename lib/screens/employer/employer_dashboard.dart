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
        .where('employerId', isEqualTo: employerId)
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
        child: Container(
          color: const Color(0xfff5f6fa),
          padding: const EdgeInsets.all(16),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                "Employer Dashboard",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                "Welcome Employer 👋",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 16),

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
                        return d["status"] == "accepted";
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

              const SizedBox(height: 16),

              const Text(
                "Recent Activity",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Expanded(
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

                        return ListTile(
                          leading: const Icon(Icons.notifications),
                          title: Text("${data["name"] ?? "Someone"} applied"),
                          subtitle: Text(data["jobTitle"] ?? ""),
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
    );
  }
}