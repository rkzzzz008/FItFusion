import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/workout_model.dart';
import '../models/user_goals_model.dart';

class FirestoreService {
  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('FirestoreService: FirebaseFirestore not initialized or offline ($e)');
      return null;
    }
  }

  // Stream user's workouts in real-time
  Stream<List<WorkoutModel>> streamUserWorkouts(String userId) {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WorkoutModel.fromFirestore(doc)).toList());
  }

  // Add workout
  Future<void> addWorkout(String userId, WorkoutModel workout) async {
    final db = _db;
    if (db == null) return;
    await db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workout.id)
        .set(workout.toFirestore());
  }

  // Update workout
  Future<void> updateWorkout(String userId, WorkoutModel workout) async {
    final db = _db;
    if (db == null) return;
    await db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workout.id)
        .set(workout.toFirestore(), SetOptions(merge: true));
  }

  // Delete workout
  Future<void> deleteWorkout(String userId, String workoutId) async {
    final db = _db;
    if (db == null) return;
    await db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workoutId)
        .delete();
  }

  // Stream user goals
  Stream<UserGoalsModel> streamUserGoals(String userId) {
    final db = _db;
    if (db == null) return const Stream.empty();
    return db
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('goals')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            return const UserGoalsModel();
          }
          return UserGoalsModel.fromMap(snapshot.data()!);
        });
  }

  // Save goals
  Future<void> saveUserGoals(String userId, UserGoalsModel goals) async {
    final db = _db;
    if (db == null) return;
    await db
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('goals')
        .set(goals.toMap(), SetOptions(merge: true));
  }
}
