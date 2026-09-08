import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement_model.dart';

class AchievementService {
  static const String _keyAchievements = 'fitfusion_achievements_v2';
  static const String _keyHydrationDays = 'fitfusion_tracked_hydration_days';
  static const String _keySleepDays = 'fitfusion_tracked_sleep_days';
  static const String _keyConsecutiveGoalDays = 'fitfusion_tracked_consecutive_goals';
  static const String _keyDistanceKm = 'fitfusion_tracked_distance_km';
  static const String _keyLastGoalDate = 'fitfusion_tracked_last_goal_date';

  /// Standard predefined achievements specification
  static List<AchievementModel> get defaultAchievements => const [
        AchievementModel(
          id: 'first_workout',
          title: 'First Workout',
          description: 'Complete your first workout.',
          icon: '🥉',
          category: 'Workouts',
          currentValue: 0,
          targetValue: 1,
          unit: 'workout',
          tier: 1,
        ),
        AchievementModel(
          id: 'streak_7',
          title: '7-Day Warrior',
          description: 'Maintain a 7-day streak.',
          icon: '🔥',
          category: 'Streaks',
          currentValue: 0,
          targetValue: 7,
          unit: 'days',
          tier: 1,
        ),
        AchievementModel(
          id: 'streak_30',
          title: '30-Day Master',
          description: 'Maintain a 30-day streak.',
          icon: '🏆',
          category: 'Streaks',
          currentValue: 0,
          targetValue: 30,
          unit: 'days',
          tier: 2,
        ),
        AchievementModel(
          id: 'streak_100',
          title: '100-Day Legend',
          description: 'Maintain a 100-day streak.',
          icon: '👑',
          category: 'Streaks',
          currentValue: 0,
          targetValue: 100,
          unit: 'days',
          tier: 3,
        ),
        AchievementModel(
          id: 'workout_50',
          title: 'Workout Beast',
          description: 'Complete 50 workouts.',
          icon: '💪',
          category: 'Workouts',
          currentValue: 0,
          targetValue: 50,
          unit: 'workouts',
          tier: 2,
        ),
        AchievementModel(
          id: 'calories_10k',
          title: 'Calorie Burner',
          description: 'Burn 10,000 calories.',
          icon: '⚡',
          category: 'Calories',
          currentValue: 0,
          targetValue: 10000,
          unit: 'kcal',
          tier: 2,
        ),
        AchievementModel(
          id: 'hydration_30',
          title: 'Hydration Hero',
          description: 'Drink enough water for 30 days.',
          icon: '💧',
          category: 'Hydration',
          currentValue: 0,
          targetValue: 30,
          unit: 'days',
          tier: 2,
        ),
        AchievementModel(
          id: 'goal_crusher_7',
          title: 'Goal Crusher',
          description: 'Reach all daily goals for 7 consecutive days.',
          icon: '🎯',
          category: 'Goals',
          currentValue: 0,
          targetValue: 7,
          unit: 'days',
          tier: 2,
        ),
        AchievementModel(
          id: 'sleep_30',
          title: 'Sleep Master',
          description: 'Meet sleep goals for 30 days.',
          icon: '😴',
          category: 'Sleep',
          currentValue: 0,
          targetValue: 30,
          unit: 'days',
          tier: 2,
        ),
        AchievementModel(
          id: 'marathon_100km',
          title: 'Marathon Beginner',
          description: 'Complete 100 km.',
          icon: '🏃',
          category: 'Distance',
          currentValue: 0,
          targetValue: 100,
          unit: 'km',
          tier: 2,
        ),
        AchievementModel(
          id: 'ultimate_legend',
          title: 'Ultimate Legend',
          description: 'Unlock every achievement.',
          icon: '👑',
          category: 'Mastery',
          currentValue: 0,
          targetValue: 10,
          unit: 'badges',
          tier: 4,
        ),
      ];

  /// Loads stored achievement records or initializes with defaults
  Future<List<AchievementModel>> loadAchievements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyAchievements);

      final defaults = defaultAchievements;
      if (data == null) {
        return defaults;
      }

      final decoded = jsonDecode(data);
      if (decoded is List) {
        final Map<String, Map<String, dynamic>> savedMap = {};
        for (final item in decoded) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = map['id'] as String? ?? '';
            if (id.isNotEmpty) {
              savedMap[id] = map;
            }
          }
        }

        // Merge saved unlock status & progress with canonical default definitions
        return defaults.map((def) {
          if (savedMap.containsKey(def.id)) {
            final saved = savedMap[def.id]!;
            final curVal = (saved['currentValue'] as num?) ?? def.currentValue;
            final isUnlocked = (saved['unlocked'] as bool?) ?? false;
            final dateStr = saved['unlockedDate'] as String?;
            final prog = (saved['progress'] as num?)?.toDouble() ??
                (def.targetValue > 0 ? (curVal / def.targetValue).toDouble().clamp(0.0, 1.0) : 0.0);

            return def.copyWith(
              currentValue: curVal,
              unlocked: isUnlocked,
              unlockedDate: dateStr,
              progress: prog.clamp(0.0, 1.0),
            );
          }
          return def;
        }).toList();
      }
    } catch (_) {}
    return defaultAchievements;
  }

  /// Persists current list of achievements to SharedPreferences
  Future<void> saveAchievements(List<AchievementModel> achievements) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = achievements.map((a) => a.toMap()).toList();
      await prefs.setString(_keyAchievements, jsonEncode(list));
    } catch (_) {}
  }

  /// Load auxiliary metric tracking counters
  Future<Map<String, dynamic>> loadTrackingMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'hydrationDays': prefs.getInt(_keyHydrationDays) ?? 14,
      'sleepDays': prefs.getInt(_keySleepDays) ?? 18,
      'consecutiveGoalDays': prefs.getInt(_keyConsecutiveGoalDays) ?? 5,
      'distanceKm': prefs.getDouble(_keyDistanceKm) ?? 48.5,
      'lastGoalDate': prefs.getString(_keyLastGoalDate),
    };
  }

  /// Save auxiliary metric tracking counters
  Future<void> saveTrackingMetrics({
    required int hydrationDays,
    required int sleepDays,
    required int consecutiveGoalDays,
    required double distanceKm,
    String? lastGoalDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHydrationDays, hydrationDays);
    await prefs.setInt(_keySleepDays, sleepDays);
    await prefs.setInt(_keyConsecutiveGoalDays, consecutiveGoalDays);
    await prefs.setDouble(_keyDistanceKm, distanceKm);
    if (lastGoalDate != null) {
      await prefs.setString(_keyLastGoalDate, lastGoalDate);
    }
  }
}
