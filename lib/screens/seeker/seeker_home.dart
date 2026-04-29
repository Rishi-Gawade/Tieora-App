import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/theme/app_theme.dart';
import '../../services/job_service.dart';
import '../../models/job_model.dart';
import '../../utils/location_helper.dart';

import 'jobs/job_detail_screen.dart';

class SeekerHome extends StatefulWidget {
  const SeekerHome({super.key});

  @override
  State<SeekerHome> createState() => _SeekerHomeState();
}

class _SeekerHomeState extends State<SeekerHome> {
  final JobService _jobService = JobService();

  List<JobModel> _jobs = [];
  bool _isLoading = false;

  int selectedMode = 0; // 0 Nearby, 1 City, 2 Remote
  double radius = 10;

  String selectedDomain = "All";

  final List<String> domains = [
    "All",
    "field",
    "technical",
    "student",
    "office",
    "delivery"
  ];

  @override
  void initState() {
    super.initState();
    _loadFilteredJobs();
  }

  Future<void> _loadFilteredJobs() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final userData = userDoc.data() ?? {};
      final userCity = userData['city'] ?? "";

      List<JobModel> jobs = [];

      if (selectedMode == 0) {
        final userLocation =
            await LocationHelper.getCurrentLocation();

        if (userLocation != null) {
          jobs = await _jobService.getFilteredJobsAdvanced(
            userLocation: userLocation,
            userCity: userCity,
            filterType: "nearby",
            radiusKm: radius,
          );
        }
      } else if (selectedMode == 1) {
        final userLocation =
            await LocationHelper.getCurrentLocation();

        if (userLocation != null) {
          jobs = await _jobService.getFilteredJobsAdvanced(
            userLocation: userLocation,
            userCity: userCity,
            filterType: "city",
          );
        }
      } else {
        final userLocation =
            await LocationHelper.getCurrentLocation();

        if (userLocation != null) {
          jobs = await _jobService.getFilteredJobsAdvanced(
            userLocation: userLocation,
            userCity: userCity,
            filterType: "remote",
          );
        }
      }

      if (selectedDomain != "All") {
        jobs = jobs.where((job) {
          final domain = (job.category ?? "").toLowerCase();
          return domain.contains(selectedDomain.toLowerCase());
        }).toList();
      }

      setState(() {
        _jobs = jobs;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Filter error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tieora"),
        actions: const [
          Icon(Icons.bookmark_border),
          SizedBox(width: 12),
          Icon(Icons.notifications_none),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [

          /// 🔥 HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Find Your Next Opportunity",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  user?.email ?? "",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 18),

                /// 🔍 SEARCH + FILTER ROW
                Row(
                  children: [
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              "Search job title, skill or company",
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue
                            .withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: AppTheme.primaryBlue,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),

          /// 🚀 MODE TOGGLE
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ToggleButtons(
              isSelected: [
                selectedMode == 0,
                selectedMode == 1,
                selectedMode == 2,
              ],
              onPressed: (index) async {
                setState(() => selectedMode = index);
                await _loadFilteredJobs();
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Nearby"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("City"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Remote"),
                ),
              ],
            ),
          ),

          /// 🔥 RADIUS SLIDER
          if (selectedMode == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        "Radius: ${radius.toInt()} km",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Slider(
                    min: 5,
                    max: 20,
                    divisions: 3,
                    value: radius,
                    onChanged: (value) {
                      setState(() => radius = value);
                    },
                    onChangeEnd: (_) => _loadFilteredJobs(),
                  ),
                ],
              ),
            ),

          /// 🔥 DOMAIN FILTER
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
              itemCount: domains.length,
              itemBuilder: (context, index) {
                final isSelected =
                    selectedDomain == domains[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(domains[index]),
                    selected: isSelected,
                    onSelected: (_) async {
                      setState(
                          () => selectedDomain = domains[index]);
                      await _loadFilteredJobs();
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          /// JOB LIST
          Expanded(child: _buildJobList()),
        ],
      ),
    );
  }

  Widget _buildJobList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_jobs.isEmpty) {
      return const Center(
        child: Text("No jobs found\nTry changing filters"),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(AppTheme.defaultRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.work_outline),
                  const SizedBox(width: 10),
                  Expanded(child: Text(job.title)),
                  if (job.isUrgent == true)
                    const Text("🔥 URGENT"),
                ],
              ),

              const SizedBox(height: 10),

              Text(job.locationText ?? "Unknown"),
              Text(job.wage),

              const SizedBox(height: 10),

              Text(job.shortDescription),

              const SizedBox(height: 10),

              Row(
                children: [
                  Text(job.jobScope ?? ""),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JobDetailScreen(
                                  jobId: job.id!),
                        ),
                      );
                    },
                    child: const Text("Apply"),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}