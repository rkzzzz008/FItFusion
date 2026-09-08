import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkoutType {
  running,
  strength,
  hiit,
  yoga,
  cycling,
  swimming,
  walking,
  boxing,
}

enum WorkoutIntensity {
  low,
  moderate,
  high,
}

class WorkoutModel {
  final String id;
  final WorkoutType type;
  final String title;
  final int durationMinutes;
  final int caloriesBurned;
  final DateTime date;
  final String? notes;
  final WorkoutIntensity intensity;

  const WorkoutModel({
    required this.id,
    required this.type,
    required this.title,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.date,
    this.notes,
    this.intensity = WorkoutIntensity.moderate,
  });

  static DateTime _parseDate(dynamic dateValue) {
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is String) {
      return DateTime.tryParse(dateValue) ?? DateTime.now();
    } else if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    }
    return DateTime.now();
  }

  factory WorkoutModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return WorkoutModel(
      id: snapshot.id,
      type: WorkoutType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'running'),
        orElse: () => WorkoutType.running,
      ),
      title: data['title'] as String? ?? 'Workout Session',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      caloriesBurned: (data['caloriesBurned'] as num?)?.toInt() ?? 0,
      date: _parseDate(data['date']),
      notes: data['notes'] as String?,
      intensity: WorkoutIntensity.values.firstWhere(
        (e) => e.name == (data['intensity'] ?? 'moderate'),
        orElse: () => WorkoutIntensity.moderate,
      ),
    );
  }

  factory WorkoutModel.fromMap(Map<String, dynamic> data, String id) {
    return WorkoutModel(
      id: id,
      type: WorkoutType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'running'),
        orElse: () => WorkoutType.running,
      ),
      title: data['title'] as String? ?? 'Workout Session',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      caloriesBurned: (data['caloriesBurned'] as num?)?.toInt() ?? 0,
      date: _parseDate(data['date']),
      notes: data['notes'] as String?,
      intensity: WorkoutIntensity.values.firstWhere(
        (e) => e.name == (data['intensity'] ?? 'moderate'),
        orElse: () => WorkoutIntensity.moderate,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'date': date.toIso8601String(),
      'notes': notes,
      'intensity': intensity.name,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'title': title,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'intensity': intensity.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  WorkoutModel copyWith({
    String? id,
    WorkoutType? type,
    String? title,
    int? durationMinutes,
    int? caloriesBurned,
    DateTime? date,
    String? notes,
    WorkoutIntensity? intensity,
  }) {
    return WorkoutModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      intensity: intensity ?? this.intensity,
    );
  }
}
