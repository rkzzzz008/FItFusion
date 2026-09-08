import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/achievement_model.dart';
import '../models/workout_model.dart';
import '../services/achievement_service.dart';
import 'fitness_provider.dart';

class AchievementProvider with ChangeNotifier {
  final AchievementService _service = AchievementService();

  List<AchievementModel> _achievements = [];
  AchievementModel? _newlyUnlockedAchievement;

  int _trackedHydrationDays = 14;
  int _trackedSleepDays = 18;
  int _trackedConsecutiveGoalDays = 5;
  double _trackedDistanceKm = 48.5;
  String? _lastGoalDate;
  bool _initialized = false;

  AchievementProvider() {
    _loadFromStorage();
  }

  bool get isInitialized => _initialized;
  List<AchievementModel> get achievements => List.unmodifiable(_achievements);
  List<AchievementModel> get unlockedAchievements =>
      _achievements.where((a) => a.unlocked).toList();
  List<AchievementModel> get lockedAchievements =>
      _achievements.where((a) => !a.unlocked).toList();

  int get totalAchievements => _achievements.length;
  int get totalUnlocked => unlockedAchievements.length;
  double get overallProgressPercentage =>
      totalAchievements == 0 ? 0.0 : (totalUnlocked / totalAchievements).clamp(0.0, 1.0);
  int get overallProgressPercent => (overallProgressPercentage * 100).round();

  AchievementModel? get newlyUnlockedAchievement => _newlyUnlockedAchievement;

  /// Most recently unlocked achievement (sorted by unlock date or order)
  AchievementModel? get recentUnlockedAchievement {
    final unlocked = unlockedAchievements;
    if (unlocked.isEmpty) return null;
    return unlocked.last;
  }

  /// The next nearest locked achievement to work towards
  AchievementModel? get nextLockedAchievement {
    final locked = lockedAchievements;
    if (locked.isEmpty) return null;
    // Prefer non-ultimate achievement with the highest current progress
    final nonUltimate = locked.where((a) => a.id != 'ultimate_legend').toList();
    if (nonUltimate.isNotEmpty) {
      nonUltimate.sort((a, b) => b.progress.compareTo(a.progress));
      return nonUltimate.first;
    }
    return locked.first;
  }

  Future<void> _loadFromStorage() async {
    // Always wrap in .toList() to guarantee a mutable growable list.
    // AchievementService.defaultAchievements is a const list — assigning it
    // directly causes "Unsupported operation: indexed set" at runtime.
    _achievements = (await _service.loadAchievements()).toList();
    final metrics = await _service.loadTrackingMetrics();
    _trackedHydrationDays = metrics['hydrationDays'] as int? ?? 14;
    _trackedSleepDays = metrics['sleepDays'] as int? ?? 18;
    _trackedConsecutiveGoalDays = metrics['consecutiveGoalDays'] as int? ?? 5;
    _trackedDistanceKm = metrics['distanceKm'] as double? ?? 48.5;
    _lastGoalDate = metrics['lastGoalDate'] as String?;
    _initialized = true;
    notifyListeners();
  }

  void dismissUnlockCelebration() {
    _newlyUnlockedAchievement = null;
    notifyListeners();
  }

  /// Manually trigger or simulate unlocking for testing and UI preview
  void testUnlockAchievement(String achievementId) {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index != -1) {
      final nowFormatted = DateFormat('MMM d, yyyy').format(DateTime.now());
      final updated = _achievements[index].copyWith(
        unlocked: true,
        unlockedDate: nowFormatted,
        currentValue: _achievements[index].targetValue,
        progress: 1.0,
      );
      _achievements[index] = updated;
      _newlyUnlockedAchievement = updated;
      _service.saveAchievements(_achievements);
      notifyListeners();
    }
  }

  /// Automated Evaluation of all 11 Achievements based on FitnessProvider
  void updateFromFitness(FitnessProvider fitness) {
    if (!_initialized || _achievements.isEmpty) return;

    bool hasChanged = false;
    final nowFormatted = DateFormat('MMM d, yyyy').format(DateTime.now());
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Calculate cumulative calories (sum from logged workouts + today's active calories)
    int cumulativeCalories = fitness.todayCaloriesBurned;
    for (final w in fitness.workouts) {
      cumulativeCalories += w.caloriesBurned;
    }

    // 2. Calculate distance in km (from running/walking workouts + step conversion)
    double totalKm = (fitness.todaySteps * 0.00075);
    for (final w in fitness.workouts) {
      if (w.type == WorkoutType.running || w.type == WorkoutType.walking) {
        totalKm += (w.durationMinutes * 0.17); // ~10km/h average running pace
      } else if (w.type == WorkoutType.cycling) {
        totalKm += (w.durationMinutes * 0.35); // ~21km/h average cycling pace
      }
    }
    if (totalKm < _trackedDistanceKm) {
      totalKm = _trackedDistanceKm;
    } else {
      _trackedDistanceKm = totalKm;
    }

    // 3. Hydration tracking: check if today's water reached daily goal
    int hydrationDays = _trackedHydrationDays;
    if (fitness.goals.dailyWaterMl > 0 && fitness.todayWaterMl >= fitness.goals.dailyWaterMl) {
      if (_lastGoalDate != todayStr) {
        hydrationDays = _trackedHydrationDays + 1;
      }
    }

    // 4. Sleep tracking: check if today's sleep meets goal
    int sleepDays = _trackedSleepDays;
    if (fitness.goals.dailySleepHours > 0 && fitness.todaySleepHours >= fitness.goals.dailySleepHours) {
      sleepDays = _trackedSleepDays;
    }

    // 5. Daily goals combined: steps, water, workouts, and calories all met
    int consecutiveGoals = _trackedConsecutiveGoalDays;
    final bool allGoalsMet = fitness.stepsProgress >= 1.0 &&
        fitness.waterProgress >= 1.0 &&
        fitness.workoutProgress >= 1.0 &&
        fitness.caloriesProgress >= 1.0;
    if (allGoalsMet && _lastGoalDate != todayStr) {
      consecutiveGoals = _trackedConsecutiveGoalDays + 1;
    }

    // Update internal tracking persistence
    _service.saveTrackingMetrics(
      hydrationDays: hydrationDays,
      sleepDays: sleepDays,
      consecutiveGoalDays: consecutiveGoals,
      distanceKm: _trackedDistanceKm,
      lastGoalDate: allGoalsMet ? todayStr : _lastGoalDate,
    );

    // Map each of the 11 achievements to its evaluated target
    final workoutCount = fitness.workouts.length;
    final currentStreak = fitness.streakDays;
    final longestStreak = fitness.streak.longestStreak;
    final effectiveStreak = currentStreak > longestStreak ? currentStreak : longestStreak;

    // Evaluate each achievement
    for (int i = 0; i < _achievements.length; i++) {
      final a = _achievements[i];
      num evaluatedValue = a.currentValue;

      switch (a.id) {
        case 'first_workout':
          evaluatedValue = workoutCount >= 1 ? 1 : 0;
          break;
        case 'streak_7':
          evaluatedValue = effectiveStreak;
          break;
        case 'streak_30':
          evaluatedValue = effectiveStreak;
          break;
        case 'streak_100':
          evaluatedValue = effectiveStreak;
          break;
        case 'workout_50':
          evaluatedValue = workoutCount;
          break;
        case 'calories_10k':
          evaluatedValue = cumulativeCalories;
          break;
        case 'hydration_30':
          evaluatedValue = hydrationDays;
          break;
        case 'goal_crusher_7':
          evaluatedValue = consecutiveGoals;
          break;
        case 'sleep_30':
          evaluatedValue = sleepDays;
          break;
        case 'marathon_100km':
          evaluatedValue = totalKm.round();
          break;
        case 'ultimate_legend':
          // Count how many of the other 10 achievements are unlocked
          final otherUnlocked = _achievements
              .where((other) => other.id != 'ultimate_legend' && other.unlocked)
              .length;
          evaluatedValue = otherUnlocked;
          break;
      }

      final double newProgress =
          a.targetValue > 0 ? (evaluatedValue / a.targetValue).clamp(0.0, 1.0) : 0.0;
      final bool shouldUnlock = evaluatedValue >= a.targetValue;

      if (!a.unlocked && shouldUnlock) {
        // Newly unlocked!
        _achievements[i] = a.copyWith(
          currentValue: evaluatedValue,
          progress: 1.0,
          unlocked: true,
          unlockedDate: nowFormatted,
        );
        _newlyUnlockedAchievement = _achievements[i];
        hasChanged = true;
      } else if (a.currentValue != evaluatedValue || (a.progress - newProgress).abs() > 0.01) {
        // Value or progress changed without changing unlock status
        _achievements[i] = a.copyWith(
          currentValue: evaluatedValue,
          progress: newProgress,
        );
        hasChanged = true;
      }
    }

    if (hasChanged) {
      _service.saveAchievements(_achievements);
      notifyListeners();
    }
  }

  /// Reset all achievements for debugging or demonstration
  Future<void> resetAllAchievements() async {
    _achievements = AchievementService.defaultAchievements.toList();
    _trackedHydrationDays = 0;
    _trackedSleepDays = 0;
    _trackedConsecutiveGoalDays = 0;
    _trackedDistanceKm = 0.0;
    _lastGoalDate = null;
    await _service.saveAchievements(_achievements);
    await _service.saveTrackingMetrics(
      hydrationDays: 0,
      sleepDays: 0,
      consecutiveGoalDays: 0,
      distanceKm: 0.0,
    );
    notifyListeners();
  }
}
