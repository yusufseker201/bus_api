import 'density_report.dart';

class UserProfile {
  const UserProfile({
    required this.userName,
    required this.totalPoints,
    required this.currentRank,
    required this.badgeName,
    required this.recentReports,
  });

  final String userName;
  final int totalPoints;
  final String currentRank;
  final String badgeName;
  final List<DensityReport> recentReports;

  UserProfile copyWith({
    String? userName,
    int? totalPoints,
    String? currentRank,
    String? badgeName,
    List<DensityReport>? recentReports,
  }) {
    return UserProfile(
      userName: userName ?? this.userName,
      totalPoints: totalPoints ?? this.totalPoints,
      currentRank: currentRank ?? this.currentRank,
      badgeName: badgeName ?? this.badgeName,
      recentReports: recentReports ?? this.recentReports,
    );
  }
}
