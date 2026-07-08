import '../models/job_model.dart';
import '../models/user_model.dart';
import '../utils/location_helper.dart';

class AIRecommendationService {

  /// ===============================
  /// SKILL MATCH (40%)
  /// ===============================
  double calculateSkillMatch(
    AppUser user,
    JobModel job,
  ) {
    if (user.skills.isEmpty || job.skills == null || job.skills!.isEmpty) {
      return 0;
    }

    int matched = 0;

    for (final skill in user.skills) {
      if (job.skills!
          .map((e) => e.toString().toLowerCase())
          .contains(skill.toLowerCase())) {
        matched++;
      }
    }

    return (matched / job.skills!.length) * 40;
  }

  /// ===============================
  /// LOCATION MATCH (25%)
  /// ===============================
  double calculateLocationMatch(
    AppUser user,
    JobModel job,
  ) {
    if (job.locationGeo == null) return 0;

    final distance = LocationHelper.calculateDistance(
      user.locationGeo,
      job.locationGeo!,
    );

    if (distance <= user.radiusPreference) {
      return 25;
    }

    return 0;
  }

  /// ===============================
  /// EXPERIENCE MATCH (15%)
  /// ===============================
  double calculateExperienceMatch(
    AppUser user,
    JobModel job,
  ) {
    if (user.experienceLevel == null) {
      return 0;
    }

    return 15;
  }

  /// ===============================
  /// SALARY MATCH (10%)
  /// ===============================
  double calculateSalaryMatch(
    AppUser user,
    JobModel job,
  ) {
    if (job.salary == null) {
      return 5;
    }

    return 10;
  }

  /// ===============================
  /// OVERALL MATCH (100%)
  /// ===============================
  double calculateOverallMatch(
    AppUser user,
    JobModel job,
  ) {
    double score = 0;

    score += calculateSkillMatch(user, job);

    score += calculateLocationMatch(user, job);

    score += calculateExperienceMatch(user, job);

    score += calculateSalaryMatch(user, job);

    if (job.jobScope == "remote") {
      score += 10;
    } else if (job.jobScope == "city") {
      score += 8;
    } else {
      score += 5;
    }

    return score.clamp(0, 100);
  }

  Future<List<JobModel>> getRecommendedJobs(
  AppUser user,
  List<JobModel> jobs,
) async {

  List<JobModel> recommendedJobs = [];

  for (final job in jobs) {

    final score = calculateOverallMatch(
      user,
      job,
    );

    recommendedJobs.add(
      job.copyWith(
        matchScore: score,
      ),
    );
  }

  recommendedJobs.sort(
    (a, b) => (b.matchScore ?? 0)
        .compareTo(a.matchScore ?? 0),
  );

  return recommendedJobs;
}

}