import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationHelper {

  /// Calculate match score based on skills
  static int calculateSkillScore(
    List<dynamic> userSkills,
    List<dynamic> jobSkills,
  ) {
    int score = 0;

    for (var skill in userSkills) {
      if (jobSkills.contains(skill)) {
        score += 10;
      }
    }

    return score;
  }

  /// Combine skill + distance score
  static int getFinalScore({
    required int skillScore,
    required int locationPriority,
  }) {
    return skillScore + (10 - locationPriority);
  }
}