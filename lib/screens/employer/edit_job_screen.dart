import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditJobScreen extends StatefulWidget {
  final String jobId;

  const EditJobScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<EditJobScreen> createState() =>
      _EditJobScreenState();
}

class _EditJobScreenState
    extends State<EditJobScreen> {

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final salaryCtrl = TextEditingController();

  bool isLoading = true;

  /// 🔥 LOAD EXISTING JOB DATA
  Future<void> loadJob() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("jobs")
          .doc(widget.jobId)
          .get();

      if (!doc.exists) return;

      final data =
          doc.data() as Map<String, dynamic>;

      titleCtrl.text = data["title"] ?? "";
      descCtrl.text = data["description"] ?? "";
      salaryCtrl.text = data["wage"] ?? "";

    } catch (e) {
      print("Load error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔥 UPDATE JOB
  Future<void> updateJob() async {
    try {
      await FirebaseFirestore.instance
          .collection("jobs")
          .doc(widget.jobId)
          .update({

        "title": titleCtrl.text.trim(),
        "description": descCtrl.text.trim(),
        "wage": salaryCtrl.text.trim(),

        /// 🔥 IMPORTANT
        "updatedAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
              content: Text("Job updated successfully")),
        );
      }

    } catch (e) {
      print("Update error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadJob();
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    salaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Job"),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  /// TITLE
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Job Title",
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// DESCRIPTION
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: "Description",
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// SALARY
                  TextField(
                    controller: salaryCtrl,
                    decoration: const InputDecoration(
                      labelText: "Salary",
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: updateJob,
                    child: const Text("Update Job"),
                  ),
                ],
              ),
            ),
    );
  }
}