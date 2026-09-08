import 'package:flutter/foundation.dart';
import '../models/workout_model.dart';
import '../models/user_goals_model.dart';
import '../models/daily_streak_model.dart';
import '../services/local_storage_service.dart';

class FitnessProvider with ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService();

  int _todaySteps = 8420;
  int _todayWaterMl = 2250;
  int _todayWorkoutMinutes = 42;
  int _todayCaloriesBurned = 1840;
  double _todaySleepHours = 7.5;
  DailyStreakModel _streak = const DailyStreakModel();
  int? _milestoneCelebrationTarget;

  UserGoalsModel _goals = const UserGoalsModel();
  List<WorkoutModel> _workouts = [];

  FitnessProvider() {
    _initDefaultWorkouts();
    _loadFromStorage();
  }

  void _initDefaultWorkouts() {
    _workouts = [
      WorkoutModel(
        id: 'demo_w1',
        type: WorkoutType.running,
        title: 'Morning Coastal Run',
        durationMinutes: 32,
        caloriesBurned: 340,
        date: DateTime.now().subtract(const Duration(hours: 3)),
        intensity: WorkoutIntensity.high,
        notes: 'Paced 5:12 min/km. Felt energetic!',
      ),
      WorkoutModel(
        id: 'demo_w2',
        type: WorkoutType.strength,
        title: 'Upper Body Hypertrophy',
        durationMinutes: 45,
        caloriesBurned: 290,
        date: DateTime.now().subtract(const Duration(hours: 8)),
        intensity: WorkoutIntensity.moderate,
        notes: 'Bench press, pull-ups, lateral raises.',
      ),
      WorkoutModel(
        id: 'demo_w3',
        type: WorkoutType.hiit,
        title: 'Sprint Interval Circuit',
        durationMinutes: 20,
        caloriesBurned: 220,
        date: DateTime.now().subtract(const Duration(days: 1)),
        intensity: WorkoutIntensity.high,
      ),
    ];
  }

  Future<void> _loadFromStorage() async {
    try {
      final cachedSteps = await _storage.getDailySteps();
      final cachedWater = await _storage.getDailyWater();
      final cachedGoals = await _storage.getCachedGoals();
      final cachedWorkouts = await _storage.getCachedWorkouts();
      final cachedStreak = await _storage.getDailyStreak();

      _todaySteps = cachedSteps;
      _todayWaterMl = cachedWater;
      if (cachedGoals != null) _goals = cachedGoals;
      if (cachedWorkouts != null && cachedWorkouts.isNotEmpty) {
        _workouts = cachedWorkouts;
      }

      // Validate streak against current calendar date
      _streak = _validateStreak(cachedStreak);
      await _storage.saveDailyStreak(_streak);

      notifyListeners();
    } catch (_) {}
  }

  DailyStreakModel _validateStreak(DailyStreakModel s) {
    if (s.lastWorkoutDate == null) return s;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(
      s.lastWorkoutDate!.year,
      s.lastWorkoutDate!.month,
      s.lastWorkoutDate!.day,
    );
    final diff = today.difference(lastDay).inDays;

    if (diff <= 1) {
      // Completed workout today (0) or yesterday (1) - streak is intact!
      return s;
    } else {
      // User skipped one or more days (diff > 1) - reset streak to 0, preserve longest streak
      return s.copyWith(currentStreak: 0);
    }
  }

  // Getters
  int get todaySteps => _todaySteps;
  int get todayWaterMl => _todayWaterMl;
  int get todayWorkoutMinutes => _todayWorkoutMinutes;
  int get todayCaloriesBurned => _todayCaloriesBurned;
  double get todaySleepHours => _todaySleepHours;
  int get streakDays => _streak.currentStreak;
  DailyStreakModel get streak => _streak;
  int? get milestoneCelebrationTarget => _milestoneCelebrationTarget;
  UserGoalsModel get goals => _goals;
  List<WorkoutModel> get workouts => List.unmodifiable(_workouts);

  void dismissMilestoneCelebration() {
    _milestoneCelebrationTarget = null;
    notifyListeners();
  }

  void testMilestoneCelebration(int days) {
    _milestoneCelebrationTarget = days;
    notifyListeners();
  }

  // Percentage calculations with zero-division safety
  double get stepsProgress =>
      _goals.dailySteps <= 0 ? 0.0 : (_todaySteps / _goals.dailySteps).clamp(0.0, 1.0);
  double get waterProgress =>
      _goals.dailyWaterMl <= 0 ? 0.0 : (_todayWaterMl / _goals.dailyWaterMl).clamp(0.0, 1.0);
  double get workoutProgress =>
      _goals.dailyWorkoutMinutes <= 0 ? 0.0 : (_todayWorkoutMinutes / _goals.dailyWorkoutMinutes).clamp(0.0, 1.0);
  double get caloriesProgress =>
      _goals.dailyCalories <= 0 ? 0.0 : (_todayCaloriesBurned / _goals.dailyCalories).clamp(0.0, 1.0);

  int get overallScorePercent =>
      (((stepsProgress + waterProgress + workoutProgress + caloriesProgress) / 4) * 100).round();

  // Water Increment
  void addWater(int amountMl) {
    _todayWaterMl = (_todayWaterMl + amountMl).clamp(0, 10000);
    _storage.saveDailyWater(_todayWaterMl);
    notifyListeners();
  }

  // Steps Increment
  void addSteps(int steps) {
    _todaySteps += steps;
    _todayCaloriesBurned += (steps * 0.04).round();
    _storage.saveDailySteps(_todaySteps);
    notifyListeners();
  }

  // Workouts
  void addWorkout(WorkoutModel workout) {
    _workouts.insert(0, workout);
    _todayWorkoutMinutes += workout.durationMinutes;
    _todayCaloriesBurned += workout.caloriesBurned;
    _storage.cacheWorkouts(_workouts);

    // Update Daily Streak based on completed workout
    _recordWorkoutForStreak(workout.date);

    notifyListeners();
  }

  void _recordWorkoutForStreak(DateTime workoutDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDay = DateTime(workoutDate.year, workoutDate.month, workoutDate.day);

    // Only update streak if workout is completed on today's date
    if (workoutDay == today) {
      bool alreadyCompletedToday = false;
      if (_streak.lastWorkoutDate != null) {
        final lastDay = DateTime(
          _streak.lastWorkoutDate!.year,
          _streak.lastWorkoutDate!.month,
          _streak.lastWorkoutDate!.day,
        );
        if (lastDay == today) {
          alreadyCompletedToday = true;
        }
      }

      if (!alreadyCompletedToday) {
        int newStreak = 1;
        if (_streak.lastWorkoutDate != null) {
          final lastDay = DateTime(
            _streak.lastWorkoutDate!.year,
            _streak.lastWorkoutDate!.month,
            _streak.lastWorkoutDate!.day,
          );
          final diff = today.difference(lastDay).inDays;
          if (diff == 1) {
            // Worked out yesterday -> increment streak
            newStreak = _streak.currentStreak + 1;
          } else {
            // Skipped one or more days -> reset to 1
            newStreak = 1;
          }
        } else {
          newStreak = 1;
        }

        final newLongest = newStreak > _streak.longestStreak ? newStreak : _streak.longestStreak;
        _streak = DailyStreakModel(
          currentStreak: newStreak,
          longestStreak: newLongest,
          lastWorkoutDate: workoutDate,
        );
        _storage.saveDailyStreak(_streak);

        // Check celebration milestones: 7, 30, 100 days
        if (newStreak == 7 || newStreak == 30 || newStreak == 100) {
          _milestoneCelebrationTarget = newStreak;
        }
      }
    }
  }

  void simulateWorkoutToday() {
    final workout = WorkoutModel(
      id: 'streak_sim_${DateTime.now().millisecondsSinceEpoch}',
      type: WorkoutType.hiit,
      title: 'Daily Streak Workout',
      durationMinutes: 30,
      caloriesBurned: 240,
      date: DateTime.now(),
      intensity: WorkoutIntensity.high,
      notes: 'Completed session to extend streak!',
    );
    addWorkout(workout);
  }

  void resetDailyStreak() {
    _streak = _streak.copyWith(currentStreak: 0);
    _storage.saveDailyStreak(_streak);
    notifyListeners();
  }

  void updateWorkout(WorkoutModel workout) {
    final index = _workouts.indexWhere((w) => w.id == workout.id);
    if (index != -1) {
      _workouts[index] = workout;
      _storage.cacheWorkouts(_workouts);
      notifyListeners();
    }
  }

  void deleteWorkout(String workoutId) {
    _workouts.removeWhere((w) => w.id == workoutId);
    _storage.cacheWorkouts(_workouts);
    notifyListeners();
  }

  // Goals
  void updateGoals(UserGoalsModel newGoals) {
    _goals = newGoals;
    _storage.cacheGoals(newGoals);
    notifyListeners();
  }
}
