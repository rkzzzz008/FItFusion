class UserProfileModel {
  final String uid;
  final String name;
  final String email;
  final double currentWeightKg;
  final double targetWeightKg;
  final double heightCm;
  final int age;
  final String gender;
  final int streakDays;
  final int totalWorkoutsCompleted;
  final bool isDarkMode;
  final bool notificationsEnabled;

  const UserProfileModel({
    required this.uid,
    required this.name,
    required this.email,
    this.currentWeightKg = 72.4,
    this.targetWeightKg = 68.0,
    this.heightCm = 178.0,
    this.age = 26,
    this.gender = 'Male',
    this.streakDays = 7,
    this.totalWorkoutsCompleted = 48,
    this.isDarkMode = true,
    this.notificationsEnabled = true,
  });

  double get bmi {
    if (heightCm <= 0) return 0.0;
    final heightMeters = heightCm / 100.0;
    return double.parse((currentWeightKg / (heightMeters * heightMeters)).toStringAsFixed(1));
  }

  String get bmiCategory {
    final val = bmi;
    if (val < 18.5) return 'Underweight';
    if (val < 25.0) return 'Normal weight';
    if (val < 30.0) return 'Overweight';
    return 'Obese';
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfileModel(
      uid: uid,
      name: map['name'] as String? ?? 'Alex Rivers',
      email: map['email'] as String? ?? 'alex.rivers@fitfusion.app',
      currentWeightKg: (map['currentWeightKg'] as num?)?.toDouble() ?? 72.4,
      targetWeightKg: (map['targetWeightKg'] as num?)?.toDouble() ?? 68.0,
      heightCm: (map['heightCm'] as num?)?.toDouble() ?? 178.0,
      age: (map['age'] as num?)?.toInt() ?? 26,
      gender: map['gender'] as String? ?? 'Male',
      streakDays: (map['streakDays'] as num?)?.toInt() ?? 7,
      totalWorkoutsCompleted: (map['totalWorkoutsCompleted'] as num?)?.toInt() ?? 48,
      isDarkMode: map['isDarkMode'] as bool? ?? true,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'currentWeightKg': currentWeightKg,
      'targetWeightKg': targetWeightKg,
      'heightCm': heightCm,
      'age': age,
      'gender': gender,
      'streakDays': streakDays,
      'totalWorkoutsCompleted': totalWorkoutsCompleted,
      'isDarkMode': isDarkMode,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  UserProfileModel copyWith({
    String? name,
    String? email,
    double? currentWeightKg,
    double? targetWeightKg,
    double? heightCm,
    int? age,
    String? gender,
    int? streakDays,
    int? totalWorkoutsCompleted,
    bool? isDarkMode,
    bool? notificationsEnabled,
  }) {
    return UserProfileModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      heightCm: heightCm ?? this.heightCm,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      streakDays: streakDays ?? this.streakDays,
      totalWorkoutsCompleted: totalWorkoutsCompleted ?? this.totalWorkoutsCompleted,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
