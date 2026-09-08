import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/workout_model.dart';

class CalendarDayData {
  final DateTime date;
  final List<WorkoutModel> workouts;
  final int caloriesBurned;
  final int durationMinutes;
  final int waterMl;
  final double sleepHours;
  final int steps;
  final double distanceKm;
  final String? notes;
  final String? mood; // e.g. '🔥 Energized', '💪 Strong', '😌 Great', '😴 Fatigued'
  final List<String> unlockedAchievements;
  final bool isGoalAchieved;
  final bool isStreakDay;

  const CalendarDayData({
    required this.date,
    this.workouts = const [],
    this.caloriesBurned = 0,
    this.durationMinutes = 0,
    this.waterMl = 0,
    this.sleepHours = 0.0,
    this.steps = 0,
    this.distanceKm = 0.0,
    this.notes,
    this.mood,
    this.unlockedAchievements = const [],
    this.isGoalAchieved = false,
    this.isStreakDay = false,
  });

  bool get hasWorkout => workouts.isNotEmpty;
  bool get hasMultipleWorkouts => workouts.length > 1;

  int get activityIntensity {
    if (workouts.isEmpty && steps < 3000) return 0;
    if (workouts.length >= 3 || caloriesBurned >= 700 || durationMinutes >= 90) return 4;
    if (workouts.length >= 2 || caloriesBurned >= 450 || durationMinutes >= 50) return 3;
    if (workouts.isNotEmpty || caloriesBurned >= 250 || steps >= 7000) return 2;
    return 1;
  }

  CalendarDayData copyWith({
    DateTime? date,
    List<WorkoutModel>? workouts,
    int? caloriesBurned,
    int? durationMinutes,
    int? waterMl,
    double? sleepHours,
    int? steps,
    double? distanceKm,
    String? notes,
    String? mood,
    List<String>? unlockedAchievements,
    bool? isGoalAchieved,
    bool? isStreakDay,
  }) {
    return CalendarDayData(
      date: date ?? this.date,
      workouts: workouts ?? this.workouts,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      waterMl: waterMl ?? this.waterMl,
      sleepHours: sleepHours ?? this.sleepHours,
      steps: steps ?? this.steps,
      distanceKm: distanceKm ?? this.distanceKm,
      notes: notes ?? this.notes,
      mood: mood ?? this.mood,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      isGoalAchieved: isGoalAchieved ?? this.isGoalAchieved,
      isStreakDay: isStreakDay ?? this.isStreakDay,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'notes': notes,
      'mood': mood,
      'waterMl': waterMl,
      'sleepHours': sleepHours,
      'steps': steps,
      'distanceKm': distanceKm,
      'unlockedAchievements': unlockedAchievements,
      'isGoalAchieved': isGoalAchieved,
      'isStreakDay': isStreakDay,
    };
  }

  factory CalendarDayData.fromMap(Map<String, dynamic> map, DateTime date) {
    return CalendarDayData(
      date: date,
      notes: map['notes'] as String?,
      mood: map['mood'] as String?,
      waterMl: (map['waterMl'] as num?)?.toInt() ?? 0,
      sleepHours: (map['sleepHours'] as num?)?.toDouble() ?? 0.0,
      steps: (map['steps'] as num?)?.toInt() ?? 0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      unlockedAchievements: List<String>.from(map['unlockedAchievements'] ?? []),
      isGoalAchieved: map['isGoalAchieved'] as bool? ?? false,
      isStreakDay: map['isStreakDay'] as bool? ?? false,
    );
  }
}

class CalendarService {
  static const String _keyCalendarMetaPrefix = 'fitfusion_cal_day_';

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Loads local day metadata (notes, mood, custom water/sleep overrides)
  Future<Map<String, dynamic>?> loadDayMetadata(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyCalendarMetaPrefix${_dateKey(date)}';
      final jsonString = prefs.getString(key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('CalendarService: loadDayMetadata error $e');
    }
    return null;
  }

  /// Saves local day metadata to SharedPreferences and syncs to Firestore if available
  Future<void> saveDayMetadata(DateTime date, Map<String, dynamic> data) async {
    final dateKey = _dateKey(date);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyCalendarMetaPrefix$dateKey';
      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      debugPrint('CalendarService: saveDayMetadata local error $e');
    }

    // Attempt Firestore sync
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('calendar_entries')
            .doc(dateKey)
            .set({
          ...data,
          'date': Timestamp.fromDate(date),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Offline or preview fallback
      debugPrint('CalendarService: Firestore sync non-fatal error ($e)');
    }
  }

  /// Syncs all calendar entries from Firestore
  Future<Map<String, Map<String, dynamic>>> fetchFirestoreCalendarEntries() async {
    final Map<String, Map<String, dynamic>> results = {};
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('calendar_entries')
            .get();

        for (final doc in snap.docs) {
          results[doc.id] = doc.data();
        }
      }
    } catch (e) {
      debugPrint('CalendarService: fetchFirestoreCalendarEntries error ($e)');
    }
    return results;
  }
}
