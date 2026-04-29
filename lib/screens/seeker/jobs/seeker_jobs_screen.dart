import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/job_model.dart';
import '../../../services/job_service.dart';
import '../../../utils/location_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_rating.dart'; // ✅ NEW

import 'job_detail_screen.dart';

class SeekerJobsScreen extends StatefulWidget {
  const SeekerJobsScreen({super.key});

  @override
  State<SeekerJobsScreen> createState() =>
      _SeekerJobsScreenState();
}

class _SeekerJobsScreenState extends State<SeekerJobsScreen> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final JobService _jobService = JobService();

  StreamSubscription? _savedSub;
  final Set<String> savedJobIds = {};

  final TextEditingController _searchController =
      TextEditingController();

  bool showSearch = false;

  GeoPoint? _userLocation;
  List<String> _userSkills = [];
  Map<String, Map<String, dynamic>> _userCache = {};

  int selectedMode = 0;
  double radius = 10;
  String selectedDomain = "All";

  final List<String> domains = [
    "All",
    "it",
    "electrician",
    "mechanic"
  ];

  @override
  void initState() {
    super.initState();
    _listenToSavedJobs();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final data = doc.data();
if (data != null) {
  setState(() {

    /// 📍 LOCATION
    if (data['locationGeo'] is GeoPoint) {
      _userLocation = data['locationGeo'];
    }

    /// 🛠 SKILLS
    if (data['skills'] is List) {
      _userSkills = (data['skills'] as List)
          .map((e) => e.toString().toLowerCase())
          .toList();
    }
  });
}
}

  void _listenToSavedJobs() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    _savedSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved_jobs')
        .snapshots()
        .listen((snap) {
      savedJobIds.clear();
      for (final saved in snap.docs) {
        savedJobIds.add(saved.id);
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _toggleSave(String jobId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('saved_jobs')
        .doc(jobId);

    try {
      if (savedJobIds.contains(jobId)) {
        await ref.delete();
      } else {
        await ref.set({
          'savedAt': FieldValue.serverTimestamp()
        });
      }
    } catch (e) {
      AppSnackbar.showError(
        context,
        "Failed to update saved jobs",
      );
    }
  }

  Future<List<JobModel>> _applyFilters(List<JobModel> jobs) async {
    if (_userLocation == null) return jobs;

    List<JobModel> filtered = [];

    for (var job in jobs) {
      if (job.locationGeo == null) continue;

      final distance = LocationHelper.calculateDistance(
        _userLocation!,
        job.locationGeo!,
      );

      if (selectedMode == 0 && distance <= radius) {
        filtered.add(job);
      } else if (selectedMode == 1) {
        filtered.add(job);
      } else if (selectedMode == 2 &&
          job.jobScope == "remote") {
        filtered.add(job);
      }
    }

    if (selectedDomain != "All") {
      filtered = filtered.where((job) {
        return job.category
            .toLowerCase()
            .contains(selectedDomain);
      }).toList();
    }

    return filtered;
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text("Filters",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      _option("Nearby", 0, setModalState),
                      _option("City", 1, setModalState),
                      _option("Remote", 2, setModalState),
                    ],
                  ),

                  const SizedBox(height: 20),

                  if (selectedMode == 0)
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text("Radius: ${radius.toInt()} km"),
                        Slider(
                          value: radius,
                          min: 0,
                          max: 15,
                          divisions: 15,
                          label: "${radius.toInt()} km",
                          onChanged: (value) {
                            setModalState(() => radius = value);
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  const Text("Category"),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    children: domains.map((d) {
                      final selected = selectedDomain == d;

                      return ChoiceChip(
                        label: Text(d),
                        selected: selected,
                        onSelected: (_) {
                          setModalState(() => selectedDomain = d);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text("Apply Filters"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _option(String text, int index, Function setModalState) {
    final isSelected = selectedMode == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setModalState(() => selectedMode = index);
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color:
                    isSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Find Your Next Opportunity"),
        actions: [
          IconButton(
            icon: Icon(showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                showSearch = !showSearch;
                _searchController.clear();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _openFilterSheet,
          ),
        ],
      ),

      body: Column(
        children: [

          if (showSearch)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Search job...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          Expanded(
            child: StreamBuilder<List<JobModel>>(
              stream: _jobService.getJobs(),
              builder: (context, snap) {

                if (snap.connectionState == ConnectionState.waiting) {
                  return const AppLoader();
                }

                if (snap.hasError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    AppSnackbar.showError(
                      context,
                      "Failed to load jobs",
                    );
                  });

                  return Center(
                    child: ElevatedButton(
                      onPressed: () {
                        (context as Element).markNeedsBuild();
                      },
                      child: const Text("Retry"),
                    ),
                  );
                }

                return FutureBuilder<List<JobModel>>(
                  future: _applyFilters(snap.data ?? []),
                  builder: (context, filteredSnap) {

                    if (filteredSnap.connectionState == ConnectionState.waiting) {
                      return const AppLoader();
                    }

                   final jobs = (filteredSnap.data ?? [])
                      .where((job) =>
                          job.title.toLowerCase().contains(
                              _searchController.text.toLowerCase()))
                      .toList();

                  /// 🔥 ADD THIS LINE HERE (IMPORTANT)
                  jobs.sort((a, b) =>
                    _calculateScore(b).compareTo(_calculateScore(a)));

                  if (jobs.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.work_outline,
                      title: "No jobs found",
                      subtitle: "Try adjusting filters or search",
                    );
                  }
                    

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: jobs.length,
                      itemBuilder: (context, i) {

                        final job = jobs[i];

                        double? distance;
                        if (_userLocation != null &&
                            job.locationGeo != null) {
                          distance =
                              LocationHelper.calculateDistance(
                            _userLocation!,
                            job.locationGeo!,
                          );
                        }
                          
                        return InkWell(
                          borderRadius:
                              BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    JobDetailScreen(jobId: job.id!),
                              ),
                            );
                          },
                          
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withOpacity(0.05),
                                  blurRadius: 6,
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        job.title,
                                        style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (_calculateScore(job) > 50)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              "Recommended",
                                              style: TextStyle(color: Colors.white, fontSize: 10),
                                            ),
                                          ),
                                    IconButton(
                                      icon: Icon(
                                        savedJobIds.contains(job.id)
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                      ),
                                      onPressed: () =>
                                          _toggleSave(job.id!),
                                    ),
                                  ],
                                ),

                                Text(job.locationText ?? ""),

                                /// ⭐ RATING ADDED HERE
                           FutureBuilder<DocumentSnapshot>(
                              future: _userCache.containsKey(job.postedBy)
                                  ? Future.value(null)
                                  : FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(job.postedBy)
                                      .get(),
                              builder: (context, snap) {

                                Map<String, dynamic>? user;

                                /// 🔥 USE CACHE FIRST
                                if (_userCache.containsKey(job.postedBy)) {
                                  user = _userCache[job.postedBy];
                                }

                                /// 🔥 FETCH & STORE
                                else if (snap.hasData && snap.data!.exists) {
                                  user = snap.data!.data() as Map<String, dynamic>;
                                  _userCache[job.postedBy] = user;
                                }

                                if (user == null) return const SizedBox();

                                final rating = (user['rating'] ?? 0).toDouble();
                                final total = user['totalRatings'] ?? 0;

                                if (total == 0) return const SizedBox();

                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: AppRating(
                                    rating: rating,
                                    totalRatings: total,
                                    size: 14,
                                  ),
                                );
                              },
                            ),

                                if (distance != null)
                                  Text(
                                    LocationHelper.getDistanceLabel(distance),
                                    style: const TextStyle(
                                      color: Colors.green,
                                    ),
                                  ),

                                const SizedBox(height: 6),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    job.jobScope ?? "local",
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  @override
void dispose() {
  _savedSub?.cancel();
  _searchController.dispose();
  super.dispose();
}
  double _calculateScore(JobModel job) {
  double score = 0;

  if (_userSkills.any((s) =>
      (job.category ?? "").toLowerCase().contains(s))) {
    score += 50;
  }

  if (_userLocation != null && job.locationGeo != null) {
    final distance = LocationHelper.calculateDistance(
      _userLocation!,
      job.locationGeo!,
    );

    if (distance < 5) score += 40;
    else if (distance < 10) score += 20;
  }

  if (job.jobScope == "remote") {
    score += 10;
  }

  return score;
}
}