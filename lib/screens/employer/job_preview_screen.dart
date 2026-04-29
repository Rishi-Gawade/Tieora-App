import 'package:flutter/material.dart';

class JobPreviewScreen extends StatelessWidget {
  final String title;
  final String shortDescription;
  final String description;
  final String salary;
  final String jobType;
  final String jobScope;
  final bool isUrgent;
  final int openings;
  final String location;

  final VoidCallback onPost;

  const JobPreviewScreen({
    super.key,
    required this.title,
    required this.shortDescription,
    required this.description,
    required this.salary,
    required this.jobType,
    required this.jobScope,
    required this.isUrgent,
    required this.openings,
    required this.location,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    const spacer = SizedBox(height: 14);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Preview"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  /// 🔥 TITLE + URGENT BADGE
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isUrgent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "URGENT",
                            style: TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),

                  spacer,

                  /// 🔹 SHORT DESC
                  Text(
                    shortDescription,
                    style: const TextStyle(fontSize: 15),
                  ),

                  spacer,

                  /// 🔹 JOB DETAILS
                  Row(
                    children: [
                      _chip("💼 $jobType"),
                      const SizedBox(width: 8),
                      _chip("📍 $jobScope"),
                    ],
                  ),

                  spacer,

                  /// 🔹 SALARY
                  Text(
                    "Salary: $salary",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),

                  spacer,

                  /// 🔹 OPENINGS
                  Text(
                    "Openings: $openings",
                    style: const TextStyle(fontSize: 14),
                  ),

                  spacer,

                  /// 🔹 LOCATION
                  Text(
                    "Location: $location",
                    style: const TextStyle(fontSize: 14),
                  ),

                  spacer,

                  /// 🔹 DESCRIPTION
                  const Text(
                    "Job Description",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  spacer,
                  Text(description),

                  const SizedBox(height: 30),
                ],
              ),
            ),

            /// 🔥 ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Edit"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onPost,
                    child: const Text("Post Job"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  /// 🔹 SMALL CHIP WIDGET
  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}