import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_goals_model.dart';
import '../models/workout_model.dart';
import '../models/daily_streak_model.dart';

class LocalStorageService {
  static const String _keyGoals = 'fitfusion_cached_goals';
  static const String _keySteps = 'fitfusion_cached_steps';
  static const String _keyWater = 'fitfusion_cached_water';
  static const String _keyTheme = 'fitfusion_dark_theme';
  static const String _keyWorkouts = 'fitfusion_cached_workouts';
  static const String _keyStreakCurrent = 'fitfusion_streak_current';
  static const String _keyStreakLongest = 'fitfusion_streak_longest';
  static const String _keyStreakLastDate = 'fitfusion_streak_last_date';

  Future<void> cacheGoals(UserGoalsModel goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGoals, jsonEncode(goals.toMap()));
  }

  Future<UserGoalsModel?> getCachedGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyGoals);
      if (data != null) {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return UserGoalsModel.fromMap(decoded);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveDailySteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySteps, steps);
  }

  Future<int> getDailySteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySteps) ?? 8420;
  }

  Future<void> saveDailyWater(int waterMl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWater, waterMl);
  }

  Future<int> getDailyWater() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyWater) ?? 2250;
  }

  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTheme, isDark);
  }

  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTheme) ?? true;
  }

  Future<void> cacheWorkouts(List<WorkoutModel> workouts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = workouts.map((w) => {'id': w.id, ...w.toMap()}).toList();
      await prefs.setString(_keyWorkouts, jsonEncode(list));
    } catch (_) {}
  }

  Future<List<WorkoutModel>?> getCachedWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_keyWorkouts);
      if (data != null) {
        final list = jsonDecode(data) as List;
        return list
            .map((item) => WorkoutModel.fromMap(
                  Map<String, dynamic>.from(item as Map),
                  item['id'] as String,
                ))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveDailyStreak(DailyStreakModel streak) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyStreakCurrent, streak.currentStreak);
      await prefs.setInt(_keyStreakLongest, streak.longestStreak);
      if (streak.lastWorkoutDate != null) {
        await prefs.setString(
          _keyStreakLastDate,
          streak.lastWorkoutDate!.toIso8601String(),
        );
      } else {
        await prefs.remove(_keyStreakLastDate);
      }
    } catch (_) {}
  }

  Future<DailyStreakModel> getDailyStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_keyStreakCurrent);
      final longest = prefs.getInt(_keyStreakLongest);
      final lastDateStr = prefs.getString(_keyStreakLastDate);

      DateTime? lastDate;
      if (lastDateStr != null) {
        lastDate = DateTime.tryParse(lastDateStr);
      }

      if (current != null || longest != null || lastDate != null) {
        return DailyStreakModel(
          currentStreak: current ?? 0,
          longestStreak: longest ?? 0,
          lastWorkoutDate: lastDate,
        );
      }
    } catch (_) {}

    // Default initial streak state:
    // Start with 6 consecutive days and yesterday as last workout,
    // so user's workout today hits the 7-day milestone!
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return DailyStreakModel(
      currentStreak: 6,
      longestStreak: 12,
      lastWorkoutDate: yesterday,
    );
  }
}
