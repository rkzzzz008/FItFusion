class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon; // Emoji or badge symbol (e.g. '🥉', '🔥', '🏆', '👑', '💪', '⚡', '💧', '🎯', '😴', '🏃')
  final String category; // 'Workouts', 'Streaks', 'Calories', 'Hydration', 'Goals', 'Sleep', 'Distance', 'Mastery'
  final num currentValue;
  final num targetValue;
  final String unit; // 'workout', 'days', 'kcal', 'km', 'badges'
  final bool unlocked;
  final String? unlockedDate;
  final double progress; // 0.0 to 1.0
  final int tier; // 1 = Bronze, 2 = Silver, 3 = Gold, 4 = Diamond/Legendary

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.category = 'General',
    this.currentValue = 0,
    this.targetValue = 1,
    this.unit = '',
    this.unlocked = false,
    this.unlockedDate,
    this.progress = 0.0,
    this.tier = 1,
  });

  bool get isUnlocked => unlocked;

  double get progressPercentage => (progress * 100).clamp(0.0, 100.0);

  String get tierName {
    switch (tier) {
      case 4:
        return 'Legendary';
      case 3:
        return 'Gold';
      case 2:
        return 'Silver';
      case 1:
      default:
        return 'Bronze';
    }
  }

  String get progressDisplay {
    if (unit.isEmpty) {
      return '${currentValue.toInt()} / ${targetValue.toInt()}';
    }
    return '${currentValue.toInt()} / ${targetValue.toInt()} $unit';
  }

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    String? category,
    num? currentValue,
    num? targetValue,
    String? unit,
    bool? unlocked,
    String? unlockedDate,
    double? progress,
    int? tier,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      unit: unit ?? this.unit,
      unlocked: unlocked ?? this.unlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      progress: progress ?? this.progress,
      tier: tier ?? this.tier,
    );
  }

  factory AchievementModel.fromMap(Map<String, dynamic> map, String id) {
    final cur = (map['currentValue'] as num?) ?? 0;
    final tar = (map['targetValue'] as num?) ?? 1;
    final rawProgress = (map['progress'] as num?)?.toDouble() ??
        (tar > 0 ? (cur / tar).toDouble() : 0.0);

    return AchievementModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? '🏆',
      category: map['category'] as String? ?? 'General',
      currentValue: cur,
      targetValue: tar,
      unit: map['unit'] as String? ?? '',
      unlocked: map['unlocked'] as bool? ?? false,
      unlockedDate: map['unlockedDate'] as String?,
      progress: rawProgress.clamp(0.0, 1.0),
      tier: (map['tier'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'category': category,
      'currentValue': currentValue,
      'targetValue': targetValue,
      'unit': unit,
      'unlocked': unlocked,
      'unlockedDate': unlockedDate,
      'progress': progress,
      'tier': tier,
    };
  }
}
