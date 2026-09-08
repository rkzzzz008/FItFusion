class UserGoalsModel {
  final int dailySteps;
  final int dailyWaterMl;
  final int dailyWorkoutMinutes;
  final double dailySleepHours;
  final int dailyCalories;
  final double targetWeightKg;

  const UserGoalsModel({
    this.dailySteps = 10000,
    this.dailyWaterMl = 3000,
    this.dailyWorkoutMinutes = 45,
    this.dailySleepHours = 8.0,
    this.dailyCalories = 2400,
    this.targetWeightKg = 70.0,
  });

  factory UserGoalsModel.fromMap(Map<String, dynamic> map) {
    return UserGoalsModel(
      dailySteps: (map['dailySteps'] as num?)?.toInt() ?? 10000,
      dailyWaterMl: (map['dailyWaterMl'] as num?)?.toInt() ?? 3000,
      dailyWorkoutMinutes: (map['dailyWorkoutMinutes'] as num?)?.toInt() ?? 45,
      dailySleepHours: (map['dailySleepHours'] as num?)?.toDouble() ?? 8.0,
      dailyCalories: (map['dailyCalories'] as num?)?.toInt() ?? 2400,
      targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble() ?? 70.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailySteps': dailySteps,
      'dailyWaterMl': dailyWaterMl,
      'dailyWorkoutMinutes': dailyWorkoutMinutes,
      'dailySleepHours': dailySleepHours,
      'dailyCalories': dailyCalories,
      'targetWeightKg': targetWeightKg,
    };
  }

  UserGoalsModel copyWith({
    int? dailySteps,
    int? dailyWaterMl,
    int? dailyWorkoutMinutes,
    double? dailySleepHours,
    int? dailyCalories,
    double? targetWeightKg,
  }) {
    return UserGoalsModel(
      dailySteps: dailySteps ?? this.dailySteps,
      dailyWaterMl: dailyWaterMl ?? this.dailyWaterMl,
      dailyWorkoutMinutes: dailyWorkoutMinutes ?? this.dailyWorkoutMinutes,
      dailySleepHours: dailySleepHours ?? this.dailySleepHours,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
    );
  }
}
