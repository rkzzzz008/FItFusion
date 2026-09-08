class WorkoutExerciseModel {
  final String name;
  final int sets;
  final String reps;
  final String restTime;
  final String targetMuscle;
  final String? notes;

  const WorkoutExerciseModel({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restTime,
    required this.targetMuscle,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'restTime': restTime,
      'targetMuscle': targetMuscle,
      'notes': notes,
    };
  }

  factory WorkoutExerciseModel.fromMap(Map<String, dynamic> map) {
    return WorkoutExerciseModel(
      name: map['name'] as String? ?? 'Exercise',
      sets: (map['sets'] as num?)?.toInt() ?? 3,
      reps: map['reps'] as String? ?? '10-12',
      restTime: map['restTime'] as String? ?? '60s',
      targetMuscle: map['targetMuscle'] as String? ?? 'Full Body',
      notes: map['notes'] as String?,
    );
  }
}

class WorkoutPlanModel {
  final String title;
  final String difficulty; // 'Beginner', 'Intermediate', 'Advanced'
  final String estimatedDuration; // e.g. '20 min', '45 min'
  final int estimatedCalories;
  final List<String> warmup;
  final List<WorkoutExerciseModel> exercises;
  final List<String> cooldown;

  const WorkoutPlanModel({
    required this.title,
    this.difficulty = 'Intermediate',
    this.estimatedDuration = '30 min',
    this.estimatedCalories = 250,
    this.warmup = const [],
    required this.exercises,
    this.cooldown = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'difficulty': difficulty,
      'estimatedDuration': estimatedDuration,
      'estimatedCalories': estimatedCalories,
      'warmup': warmup,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'cooldown': cooldown,
    };
  }

  factory WorkoutPlanModel.fromMap(Map<String, dynamic> map) {
    return WorkoutPlanModel(
      title: map['title'] as String? ?? 'Custom Workout Plan',
      difficulty: map['difficulty'] as String? ?? 'Intermediate',
      estimatedDuration: map['estimatedDuration'] as String? ?? '30 min',
      estimatedCalories: (map['estimatedCalories'] as num?)?.toInt() ?? 250,
      warmup: (map['warmup'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      exercises: (map['exercises'] as List<dynamic>?)
              ?.map((e) => WorkoutExerciseModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      cooldown: (map['cooldown'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class NutritionPlanModel {
  final String title;
  final String breakfast;
  final String lunch;
  final String dinner;
  final List<String> snacks;
  final String hydration;
  final int proteinTargetGrams;
  final int totalCalories;
  final List<String> keyTips;

  const NutritionPlanModel({
    required this.title,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    this.snacks = const [],
    required this.hydration,
    this.proteinTargetGrams = 120,
    this.totalCalories = 2100,
    this.keyTips = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
      'snacks': snacks,
      'hydration': hydration,
      'proteinTargetGrams': proteinTargetGrams,
      'totalCalories': totalCalories,
      'keyTips': keyTips,
    };
  }

  factory NutritionPlanModel.fromMap(Map<String, dynamic> map) {
    return NutritionPlanModel(
      title: map['title'] as String? ?? 'Custom Nutrition Plan',
      breakfast: map['breakfast'] as String? ?? 'Oatmeal & Protein Shake',
      lunch: map['lunch'] as String? ?? 'Grilled Chicken Salad & Quinoa',
      dinner: map['dinner'] as String? ?? 'Salmon with Steamed Greens & Sweet Potato',
      snacks: (map['snacks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      hydration: map['hydration'] as String? ?? '2.5 - 3.0 Liters water',
      proteinTargetGrams: (map['proteinTargetGrams'] as num?)?.toInt() ?? 120,
      totalCalories: (map['totalCalories'] as num?)?.toInt() ?? 2100,
      keyTips: (map['keyTips'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

enum MessageSender { user, ai }

class ChatMessageModel {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final WorkoutPlanModel? workoutPlan;
  final NutritionPlanModel? nutritionPlan;
  final bool isTyping;

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.workoutPlan,
    this.nutritionPlan,
    this.isTyping = false,
  });

  bool get isUser => sender == MessageSender.user;
  bool get isAi => sender == MessageSender.ai;

  ChatMessageModel copyWith({
    String? id,
    String? content,
    MessageSender? sender,
    DateTime? timestamp,
    WorkoutPlanModel? workoutPlan,
    NutritionPlanModel? nutritionPlan,
    bool? isTyping,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      workoutPlan: workoutPlan ?? this.workoutPlan,
      nutritionPlan: nutritionPlan ?? this.nutritionPlan,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'sender': sender.name,
      'timestamp': timestamp.toIso8601String(),
      'workoutPlan': workoutPlan?.toMap(),
      'nutritionPlan': nutritionPlan?.toMap(),
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: map['content'] as String? ?? '',
      sender: (map['sender'] as String?) == 'user' ? MessageSender.user : MessageSender.ai,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      workoutPlan: map['workoutPlan'] != null
          ? WorkoutPlanModel.fromMap(map['workoutPlan'] as Map<String, dynamic>)
          : null,
      nutritionPlan: map['nutritionPlan'] != null
          ? NutritionPlanModel.fromMap(map['nutritionPlan'] as Map<String, dynamic>)
          : null,
    );
  }
}
