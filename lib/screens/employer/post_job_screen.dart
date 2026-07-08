import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/job_model.dart';
import '../../services/job_service.dart';
import '../../utils/location_helper.dart';
import '../common/map_picker_screen.dart';
import 'job_preview_screen.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final jobController = TextEditingController();
  final shortDescController = TextEditingController();
  final descController = TextEditingController();
  final wageController = TextEditingController();
  final locationController = TextEditingController();

  final JobService _jobService = JobService();

  /// ✅ FIXED CATEGORY LIST
  List<String> categories = [
    "Skilled Services",
    "General Work",
    "Professional",
  ];

  /// OPTIONAL SUB-CATEGORIES (FUTURE USE)
  Map<String, List<String>> subCategories = {
    "Skilled Services": [
      "Electrician",
      "Plumber",
      "Carpenter",
      "Technician",
    ],
    "General Work": [
      "Labour",
      "Cleaner",
      "Cook",
      "Helper",
    ],
    "Professional": [
      "Driver",
      "Office Work",
      "Other",
    ],
  };

  String category = "Skilled Services";
  String jobType = "Full-time";
  String jobScope = "Local";
  String salaryType = "Fixed";

  bool isUrgent = false;
  int openings = 1;
  bool loading = false;

  GeoPoint? selectedGeoPoint;

String getDomain(String category) {
  switch (category) {
    case "Professional":
      return "professional";

    case "Skilled Services":
      return "technical";

    case "General Work":
      return "field";

    default:
      return "field";
  }
}
  String extractCity(String location) {
    final parts = location.split(",");
    return parts.isNotEmpty ? parts.last.trim() : location;
  }

  Future<void> postJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      final userData = userDoc.data()!;

      final locationText = locationController.text.trim();

      GeoPoint? locationGeo = selectedGeoPoint;

locationGeo ??= await LocationHelper.geoFromText(locationText);

// Temporary fallback for demo
locationGeo ??= const GeoPoint(
  18.5204,
  73.8567,
);


      final job = JobModel(
        id: "",
        title: jobController.text.trim(),
        shortDescription: shortDescController.text.trim(),
        description: descController.text.trim(),
        category: category,
        wage: salaryType == "Negotiable"
            ? "Negotiable"
            : wageController.text.trim(),
        postedBy: uid,
        postedByName:
            userData["companyName"] ?? userData["fullName"] ?? "Employer",
        locationText: locationText,
        locationGeo: locationGeo,
        jobScope: jobScope.toLowerCase(),
        isUrgent: isUrgent,
        employerType: userData["employerType"] ?? "individual",
        timestamp: DateTime.now(),
        city: extractCity(locationText),
        domain: getDomain(category),
      );

      await _jobService.postJob(job);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job posted successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("$e")));
    }

    setState(() => loading = false);
  }

  void previewJob() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobPreviewScreen(
          title: jobController.text,
          shortDescription: shortDescController.text,
          description: descController.text,
          salary: salaryType == "Negotiable"
              ? "Negotiable"
              : wageController.text,
          jobType: jobType,
          jobScope: jobScope,
          isUrgent: isUrgent,
          openings: openings,
          location: locationController.text,
          onPost: postJob,
        ),
      ),
    );
  }

  Future<void> openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        locationController.text = result["address"];
        selectedGeoPoint = result["geo"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);

    return Scaffold(
      appBar: AppBar(title: const Text("Post a Job")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: jobController,
                decoration: const InputDecoration(
                  labelText: "Job Title",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.length < 3 ? "Enter valid job title" : null,
              ),
              gap,

              TextFormField(
                controller: shortDescController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: "Short Summary",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.isEmpty ? "Enter summary" : null,
              ),
              gap,

              TextFormField(
                controller: descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Job Description",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v!.length < 10 ? "Add proper description" : null,
              ),
              gap,

              /// ✅ FIXED CATEGORY DROPDOWN
              DropdownButtonFormField(
                value: categories.contains(category) ? category : null,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => category = v);
                  }
                },
              ),
              gap,

              DropdownButtonFormField(
                value: jobType,
                decoration: const InputDecoration(
                  labelText: "Job Type",
                  border: OutlineInputBorder(),
                ),
                items: ["Full-time", "Part-time", "Contract"]
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => jobType = v!),
              ),
              gap,

              DropdownButtonFormField(
                value: jobScope,
                decoration: const InputDecoration(
                  labelText: "Job Scope",
                  border: OutlineInputBorder(),
                ),
                items: ["Local", "City", "Remote"]
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => jobScope = v!),
              ),
              gap,

              DropdownButtonFormField(
                value: salaryType,
                decoration: const InputDecoration(
                  labelText: "Salary Type",
                  border: OutlineInputBorder(),
                ),
                items: ["Fixed", "Hourly", "Negotiable"]
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => salaryType = v!),
              ),
              gap,

              if (salaryType != "Negotiable")
                TextFormField(
                  controller: wageController,
                  decoration: const InputDecoration(
                    labelText: "Wage / Salary",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v!.isEmpty ? "Enter salary" : null,
                ),

              gap,

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Openings"),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (openings > 1) {
                            setState(() => openings--);
                          }
                        },
                        icon: const Icon(Icons.remove),
                      ),
                      Text(openings.toString()),
                      IconButton(
                        onPressed: () =>
                            setState(() => openings++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),

              gap,

              SwitchListTile(
                title: const Text("Urgent Hiring"),
                value: isUrgent,
                onChanged: (v) =>
                    setState(() => isUrgent = v),
              ),

              gap,

              TextFormField(
  controller: locationController,
  decoration: const InputDecoration(
    labelText: "Job Location",
    prefixIcon: Icon(Icons.location_on),
    suffixIcon: Icon(Icons.map),
    border: OutlineInputBorder(),
  ),
),

              gap,

              OutlinedButton(
                onPressed: openMapPicker,
                child: const Text("Select on Map"),
              ),

              gap,

              OutlinedButton(
                onPressed: previewJob,
                child: const Text("Preview Job"),
              ),

              gap,

              loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: postJob,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 14),
                        child: Text("Post Job"),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}