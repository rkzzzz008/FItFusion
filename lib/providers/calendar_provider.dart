import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/workout_model.dart';
import '../services/calendar_service.dart';
import 'fitness_provider.dart';
import 'achievement_provider.dart';

class MonthlyStatistics {
  final int totalWorkouts;
  final int caloriesBurned;
  final int workoutMinutes;
  final int steps;
  final double averageWaterIntake;
  final double averageSleep;
  final int bestStreak;
  final WorkoutModel? longestWorkout;
  final WorkoutType? favoriteWorkoutType;
  final String mostActiveWeekday;
  final double monthlyCompletionPercent;

  const MonthlyStatistics({
    required this.totalWorkouts,
    required this.caloriesBurned,
    required this.workoutMinutes,
    required this.steps,
    required this.averageWaterIntake,
    required this.averageSleep,
    required this.bestStreak,
    this.longestWorkout,
    this.favoriteWorkoutType,
    required this.mostActiveWeekday,
    required this.monthlyCompletionPercent,
  });
}

class CalendarProvider with ChangeNotifier {
  final CalendarService _service = CalendarService();

  late DateTime _selectedMonth;
  late DateTime _selectedDate;
  final Map<String, Map<String, dynamic>> _metadataCache = {};
  bool _initialized = false;

  CalendarProvider() {
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _init();
  }

  DateTime get selectedMonth => _selectedMonth;
  DateTime get selectedDate => _selectedDate;
  bool get isInitialized => _initialized;

  Future<void> _init() async {
    final entries = await _service.fetchFirestoreCalendarEntries();
    _metadataCache.addAll(entries);
    _initialized = true;
    notifyListeners();
  }

  void setMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
  }

  void nextMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    notifyListeners();
  }

  void previousMonth() {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  String _dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Retrieves day data integrating workouts, daily goals, water, sleep, streak, and notes
  CalendarDayData getDayData(
    DateTime date,
    FitnessProvider fitness, [
    AchievementProvider? achievements,
  ]) {
    final key = _dateKey(date);
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;

    // Filter workouts for this specific day
    final dayWorkouts = fitness.workouts.where((w) {
      return w.date.year == date.year &&
          w.date.month == date.month &&
          w.date.day == date.day;
    }).toList();

    // Sum workout stats
    int cals = 0;
    int duration = 0;
    double distKm = 0.0;
    for (final w in dayWorkouts) {
      cals += w.caloriesBurned;
      duration += w.durationMinutes;
      if (w.type == WorkoutType.running || w.type == WorkoutType.walking) {
        distKm += w.durationMinutes * 0.17;
      } else if (w.type == WorkoutType.cycling) {
        distKm += w.durationMinutes * 0.35;
      }
    }

    // Get metadata overrides (notes, mood, etc.)
    final meta = _metadataCache[key] ?? {};
    final notes = meta['notes'] as String?;
    final mood = meta['mood'] as String?;

    // Water & Sleep estimates (using today's live data for today, or deterministic historical values)
    int waterMl = isToday ? fitness.todayWaterMl : ((meta['waterMl'] as num?)?.toInt() ?? (dayWorkouts.isNotEmpty ? 2400 : 1800));
    double sleepHours = isToday ? fitness.todaySleepHours : ((meta['sleepHours'] as num?)?.toDouble() ?? (dayWorkouts.isNotEmpty ? 7.6 : 6.8));
    int steps = isToday ? fitness.todaySteps : ((meta['steps'] as num?)?.toInt() ?? (dayWorkouts.isNotEmpty ? 9200 : 4500));
    if (isToday) {
      cals += fitness.todayCaloriesBurned;
      distKm += (fitness.todaySteps * 0.00075);
    } else {
      distKm += (steps * 0.00075);
    }

    // Goal Achieved logic: if workouts completed OR steps/water meet daily targets
    final bool goalAchieved = dayWorkouts.isNotEmpty ||
        (fitness.goals.dailySteps > 0 && steps >= fitness.goals.dailySteps) ||
        (fitness.goals.dailyWaterMl > 0 && waterMl >= fitness.goals.dailyWaterMl);

    // Streak day logic: day is within active streak range
    final bool isStreakDay = dayWorkouts.isNotEmpty || (isToday && fitness.streak.currentStreak > 0);

    // Unlocked achievements on this day
    final unlockedToday = achievements?.unlockedAchievements
            .where((a) => a.unlockedDate != null && a.unlockedDate!.contains(DateFormat('MMM d').format(date)))
            .map((a) => a.title)
            .toList() ??
        const [];

    return CalendarDayData(
      date: date,
      workouts: dayWorkouts,
      caloriesBurned: cals,
      durationMinutes: duration,
      waterMl: waterMl,
      sleepHours: sleepHours,
      steps: steps,
      distanceKm: distKm,
      notes: notes,
      mood: mood,
      unlockedAchievements: unlockedToday,
      isGoalAchieved: goalAchieved,
      isStreakDay: isStreakDay,
    );
  }

  /// Updates custom user notes and mood for a given date
  Future<void> updateDayNotesAndMood(
    DateTime date, {
    String? notes,
    String? mood,
  }) async {
    final key = _dateKey(date);
    final existing = _metadataCache[key] ?? {};
    final updated = {
      ...existing,
      if (notes != null) 'notes': notes,
      if (mood != null) 'mood': mood,
    };
    _metadataCache[key] = updated;
    await _service.saveDayMetadata(date, updated);
    notifyListeners();
  }

  /// Computes high-level Monthly Statistics
  MonthlyStatistics getMonthlyStats(FitnessProvider fitness) {
    final targetMonth = _selectedMonth.month;
    final targetYear = _selectedMonth.year;

    // Filter workouts for the selected month
    final monthWorkouts = fitness.workouts.where((w) {
      return w.date.year == targetYear && w.date.month == targetMonth;
    }).toList();

    int totalWorkouts = monthWorkouts.length;
    int caloriesBurned = 0;
    int workoutMinutes = 0;
    WorkoutModel? longestWorkout;
    final Map<WorkoutType, int> typeFrequency = {};
    final Map<int, int> weekdayCount = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

    for (final w in monthWorkouts) {
      caloriesBurned += w.caloriesBurned;
      workoutMinutes += w.durationMinutes;

      if (longestWorkout == null || w.durationMinutes > longestWorkout.durationMinutes) {
        longestWorkout = w;
      }

      typeFrequency[w.type] = (typeFrequency[w.type] ?? 0) + 1;
      weekdayCount[w.date.weekday] = (weekdayCount[w.date.weekday] ?? 0) + 1;
    }

    // Favorite workout type
    WorkoutType? favType;
    int maxTypeCount = 0;
    typeFrequency.forEach((type, count) {
      if (count > maxTypeCount) {
        maxTypeCount = count;
        favType = type;
      }
    });

    // Most active weekday
    int mostActiveDayNum = 1;
    int maxDayCount = -1;
    weekdayCount.forEach((day, count) {
      if (count > maxDayCount) {
        maxDayCount = count;
        mostActiveDayNum = day;
      }
    });
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final mostActiveWeekday = weekdayNames[mostActiveDayNum - 1];

    // Estimated steps & water averages for month
    final daysInMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final daysPassed = (targetYear == DateTime.now().year && targetMonth == DateTime.now().month)
        ? DateTime.now().day
        : daysInMonth;

    final estimatedMonthlySteps = (totalWorkouts * 4200) + (daysPassed * 4500);
    final avgWater = 2450.0;
    final avgSleep = 7.4;
    final bestStreak = fitness.streak.longestStreak > 0 ? fitness.streak.longestStreak : fitness.streak.currentStreak;

    // Monthly completion % (days with workouts or active goals / days passed)
    final workoutDaysSet = monthWorkouts.map((w) => w.date.day).toSet();
    final double completionPercent = daysPassed > 0
        ? (workoutDaysSet.length / daysPassed).clamp(0.0, 1.0)
        : 0.0;

    return MonthlyStatistics(
      totalWorkouts: totalWorkouts,
      caloriesBurned: caloriesBurned,
      workoutMinutes: workoutMinutes,
      steps: estimatedMonthlySteps,
      averageWaterIntake: avgWater,
      averageSleep: avgSleep,
      bestStreak: bestStreak,
      longestWorkout: longestWorkout,
      favoriteWorkoutType: favType,
      mostActiveWeekday: mostActiveWeekday,
      monthlyCompletionPercent: completionPercent,
    );
  }

  /// Generates a yearly heatmap map: date string -> intensity (0, 1, 2, 3, 4)
  Map<String, int> getYearlyHeatmap(FitnessProvider fitness, int year) {
    final Map<String, int> heatmap = {};
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);

    // Populate all days
    DateTime current = startDate;
    while (!current.isAfter(endDate)) {
      heatmap[_dateKey(current)] = 0;
      current = current.add(const Duration(days: 1));
    }

    // Overlay workouts
    for (final w in fitness.workouts) {
      if (w.date.year == year) {
        final key = _dateKey(w.date);
        final cur = heatmap[key] ?? 0;
        heatmap[key] = (cur + 2).clamp(0, 4);
      }
    }

    // If streak active today in this year
    final now = DateTime.now();
    if (now.year == year && fitness.streak.currentStreak > 0) {
      for (int i = 0; i < fitness.streak.currentStreak && i < 30; i++) {
        final d = now.subtract(Duration(days: i));
        final k = _dateKey(d);
        if ((heatmap[k] ?? 0) == 0) {
          heatmap[k] = 1;
        }
      }
    }

    return heatmap;
  }
}
