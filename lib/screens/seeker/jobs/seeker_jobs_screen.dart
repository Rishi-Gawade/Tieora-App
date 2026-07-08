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

  int selectedMode = -1;
  double radius = 10;
  String selectedDomain = "All";

final List<String> domains = [
  "All",
  "IT",
  "Electrician",
  "Mechanic",
  "Driver",
  "Delivery",
  "Plumber",
  "Carpenter",
  "Construction",
  "Office",
  "Student",
  "Freelance",
  "Security",
  "Cleaner",
  "Painter",
  "Technician",
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

List<JobModel> _applyFilters(List<JobModel> jobs) {

  List<JobModel> filtered = List.from(jobs);

  // Nearby
  if (selectedMode == 0) {
    filtered = filtered.where((job) {

      if ((job.jobScope ?? "").toLowerCase() != "local") {
        return false;
      }

      if (_userLocation == null || job.locationGeo == null) {
        return false;
      }
      debugPrint("User Location : ${_userLocation!.latitude}, ${_userLocation!.longitude}");
      debugPrint("Job Location  : ${job.locationGeo!.latitude}, ${job.locationGeo!.longitude}");

      final distance = LocationHelper.calculateDistance(
        _userLocation!,
        job.locationGeo!,
      );

      debugPrint("Distance = $distance");

      return distance <= radius;

    }).toList();
  }

  // City
  else if (selectedMode == 1) {
    filtered = filtered.where((job) {

      return (job.jobScope ?? "").toLowerCase() == "city";

    }).toList();
  }

  // Remote
  else if (selectedMode == 2) {
    filtered = filtered.where((job) {

      return (job.jobScope ?? "").toLowerCase() == "remote";

    }).toList();
  }

  // Category
  if (selectedDomain != "All") {
    filtered = filtered.where((job) {
      return (job.domain ?? "")
          .toLowerCase()
          .contains(selectedDomain.toLowerCase());
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
            return Container(
              height: MediaQuery.of(context).size.height * 0.70,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                 child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Filter Jobs",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 6),

                  const Text(
                    "Find jobs that match your preference",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                  const Text(
                    "Job Scope",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

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
                       Text(
                        "Search Radius (${radius.toInt()} km)",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                        Slider(
                          value: radius,
                          min: 0,
                          max: 20,
                          divisions: 20,
                          label: "${radius.toInt()} km",
                          onChanged: (value) {
                            setModalState(() => radius = value);
                          },
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  const Text(
                    "Category",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    children: domains.map((d) {
                      final selected = selectedDomain == d;

                     return ChoiceChip(
                        label: Text(
                          d,
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        selected: selected,
                        selectedColor: AppTheme.primaryBlue,
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) {
                          setModalState(() => selectedDomain = d);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                 Row(
                  children: [

                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            selectedMode = -1;
                            selectedDomain = "All";
                            radius = 10;
                          });
                        },
                        child: const Text("Reset"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        child: const Text("Apply"),
                      ),
                    ),
                  ],
                ),
                ],
              ),
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

                  /// 🔥 HANDLE LOADING
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const AppLoader();
                  }

                  /// 🔥 HANDLE ERROR (NO UI BREAK)
                  if (snap.hasError) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {});
                        },
                        child: const Text("Retry"),
                      ),
                    );
                  }

                  /// 🔥 VERY IMPORTANT (FIX GREY SCREEN)
                  if (!snap.hasData || snap.data == null) {
                    return const AppEmptyState(
                      icon: Icons.work_outline,
                      title: "No jobs available",
                      subtitle: "Please try again later",
                    );
                  }

                  /// 🔥 SAFE DATA
                  final allJobs = snap.data!;

                  debugPrint("TOTAL JOBS => ${allJobs.length}");

                  /// 🔥 APPLY FILTERS
                  final filteredJobs = _applyFilters(allJobs);
                  debugPrint("Filtered Jobs => ${filteredJobs.length}");

                  /// 🔥 SEARCH
                  final jobs = filteredJobs
                      .where((job) =>
                          (job.title ?? "").toLowerCase()
                              .contains(_searchController.text.toLowerCase()))
                      .toList();

                  /// 🔥 SORT
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

                        final ai = _calculateScore(job);

                        Color badgeColor;

                        String recommendation;

                        if (ai >= 85) {
                          badgeColor = Colors.green;
                          recommendation = "Excellent Match";
                        } else if (ai >= 60) {
                          badgeColor = Colors.orange;
                          recommendation = "Good Match";
                        } else {
                          badgeColor = Colors.red;
                          recommendation = "Low Match";
                        }

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
                                    JobDetailScreen(jobId: job.id),
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
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    if (ai > 50)
                                          Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: badgeColor,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              "⭐ ${ai.toInt()}%",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                    IconButton(
                                      icon: Icon(
                                        savedJobIds.contains(job.id)
                                            ? Icons.bookmark
                                            : Icons.bookmark_border,
                                      ),
                                      onPressed: () =>
                                          _toggleSave(job.id),
                                    ),
                                  ],
                                ),

                                Text(
                                  job.locationText ?? "",
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  job.company ?? "",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                
                                const SizedBox(height: 4),

                                  Text(
                                    "₹ ${job.wage}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                if (distance != null) ...[
                                  Builder(
                                    builder: (context) {

                                      String label;

                                      if (distance! < 2) {
                                        label = "🔥 Very close (${distance.toStringAsFixed(1)} km)";
                                      } else if (distance! < 5) {
                                      label = "📍 Nearby (${distance.toStringAsFixed(1)} km)";
                                      } else {
                                        label = "🌍 ${distance.toStringAsFixed(1)} km away";
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          label,
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                /// ⭐ RATING ADDED HERE
                          FutureBuilder<DocumentSnapshot?>(
                            future: _userCache.containsKey(job.postedBy)
                                ? Future.value(null)
                                : FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(job.postedBy)
                                    .get(),
                            builder: (context, snap) {

                              Map<String, dynamic>? user;

                              if (_userCache.containsKey(job.postedBy)) {
                                user = _userCache[job.postedBy];
                              } else if (snap.hasData && snap.data != null && snap.data!.exists) {
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
                ),
            )
  
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

  final title = (job.title ?? "").toLowerCase();
  final category = (job.category ?? "").toLowerCase();
  final domain = (job.domain ?? "").toLowerCase();

  // -------------------------
  // 1. Skills Match (50)
  // -------------------------
  int matchedSkills = 0;

  for (final skill in _userSkills) {
    if (title.contains(skill) ||
        category.contains(skill) ||
        domain.contains(skill)) {
      matchedSkills++;
    }
  }

  if (_userSkills.isNotEmpty) {
    score += (matchedSkills / _userSkills.length) * 50;
  }

  // -------------------------
  // 2. Preferred Domain (20)
  // -------------------------
  if (selectedDomain != "All") {
    if (domain.contains(selectedDomain.toLowerCase())) {
      score += 20;
    }
  }

  // -------------------------
  // 3. Job Scope (15)
  // -------------------------
  switch ((job.jobScope ?? "").toLowerCase()) {
    case "city":
      score += 15;
      break;
    case "remote":
      score += 12;
      break;
    case "local":
      score += 10;
      break;
  }

  // -------------------------
  // 4. Salary (15)
  // -------------------------
  final salary =
      double.tryParse(job.wage.toString()) ?? 0;

  if (salary >= 50000) {
    score += 15;
  } else if (salary >= 30000) {
    score += 10;
  } else if (salary >= 15000) {
    score += 5;
  }

  return score.clamp(0, 100);
}
}