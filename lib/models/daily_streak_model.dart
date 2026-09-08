class DailyStreakModel {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastWorkoutDate;

  const DailyStreakModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastWorkoutDate,
  });

  /// Checks if the user completed at least one workout today.
  bool get hasWorkedOutToday {
    if (lastWorkoutDate == null) return false;
    final now = DateTime.now();
    return lastWorkoutDate!.year == now.year &&
        lastWorkoutDate!.month == now.month &&
        lastWorkoutDate!.day == now.day;
  }

  /// Checks if the streak is at risk (workout was yesterday, none yet today).
  bool get isAtRisk {
    if (lastWorkoutDate == null || currentStreak == 0) return false;
    if (hasWorkedOutToday) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      lastWorkoutDate!.year,
      lastWorkoutDate!.month,
      lastWorkoutDate!.day,
    );
    return today.difference(lastDay).inDays == 1;
  }

  /// Returns next milestone target (7, 30, or 100).
  int get nextMilestone {
    if (currentStreak < 7) return 7;
    if (currentStreak < 30) return 30;
    if (currentStreak < 100) return 100;
    return ((currentStreak ~/ 50) + 1) * 50;
  }

  /// Progress fraction towards next milestone (0.0 to 1.0).
  double get milestoneProgress {
    final next = nextMilestone;
    final prev = next == 7 ? 0 : (next == 30 ? 7 : (next == 100 ? 30 : next - 50));
    if (next <= prev) return 1.0;
    return ((currentStreak - prev) / (next - prev)).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastWorkoutDate': lastWorkoutDate?.toIso8601String(),
    };
  }

  factory DailyStreakModel.fromMap(Map<String, dynamic> map) {
    DateTime? parsedDate;
    if (map['lastWorkoutDate'] != null) {
      try {
        parsedDate = DateTime.tryParse(map['lastWorkoutDate'].toString());
      } catch (_) {}
    }

    return DailyStreakModel(
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      lastWorkoutDate: parsedDate,
    );
  }

  DailyStreakModel copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastWorkoutDate,
  }) {
    return DailyStreakModel(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
    );
  }
}
