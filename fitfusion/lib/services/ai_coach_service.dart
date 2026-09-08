import 'dart:math';
import '../models/chat_message_model.dart';
import '../models/user_profile_model.dart';
import '../models/workout_model.dart';
import '../providers/fitness_provider.dart';
import '../providers/achievement_provider.dart';

class UserFitnessContext {
  final String userName;
  final double currentWeight;
  final double targetWeight;
  final double heightCm;
  final double bmi;
  final String bmiCategory;
  final int streakDays;
  final int todaySteps;
  final int todayCalories;
  final int todayWaterMl;
  final double todaySleepHours;
  final int calorieGoal;
  final int stepsGoal;
  final int workoutMinutesGoal;
  final int totalWorkouts;
  final List<WorkoutModel> recentWorkouts;
  final int unlockedAchievementsCount;
  final String? recentAchievementTitle;
  final bool hasWorkedOutToday;

  const UserFitnessContext({
    required this.userName,
    required this.currentWeight,
    required this.targetWeight,
    required this.heightCm,
    required this.bmi,
    required this.bmiCategory,
    required this.streakDays,
    required this.todaySteps,
    required this.todayCalories,
    required this.todayWaterMl,
    required this.todaySleepHours,
    required this.calorieGoal,
    required this.stepsGoal,
    required this.workoutMinutesGoal,
    required this.totalWorkouts,
    required this.recentWorkouts,
    required this.unlockedAchievementsCount,
    this.recentAchievementTitle,
    required this.hasWorkedOutToday,
  });

  factory UserFitnessContext.fromProviders({
    required UserProfileModel? profile,
    required FitnessProvider fitness,
    required AchievementProvider? achievements,
  }) {
    final now = DateTime.now();
    final p = profile ?? const UserProfileModel(uid: 'user_1', name: 'Champion', email: 'user@fitfusion.app');
    final hasWorkoutToday = fitness.workouts.any((w) {
      return w.date.year == now.year && w.date.month == now.month && w.date.day == now.day;
    });

    final unlocked = achievements?.unlockedAchievements ?? [];
    final recentAchievement = unlocked.isNotEmpty ? unlocked.first.title : null;

    return UserFitnessContext(
      userName: p.name.split(' ').first,
      currentWeight: p.currentWeightKg,
      targetWeight: p.targetWeightKg,
      heightCm: p.heightCm,
      bmi: p.bmi,
      bmiCategory: p.bmiCategory,
      streakDays: fitness.streakDays,
      todaySteps: fitness.todaySteps,
      todayCalories: fitness.todayCaloriesBurned,
      todayWaterMl: fitness.todayWaterMl,
      todaySleepHours: fitness.todaySleepHours,
      calorieGoal: fitness.goals.dailyCalories,
      stepsGoal: fitness.goals.dailySteps,
      workoutMinutesGoal: fitness.goals.dailyWorkoutMinutes,
      totalWorkouts: fitness.workouts.length,
      recentWorkouts: fitness.workouts.take(5).toList(),
      unlockedAchievementsCount: unlocked.length,
      recentAchievementTitle: recentAchievement,
      hasWorkedOutToday: hasWorkoutToday,
    );
  }
}

class AICoachResponse {
  final String text;
  final WorkoutPlanModel? workoutPlan;
  final NutritionPlanModel? nutritionPlan;

  const AICoachResponse({
    required this.text,
    this.workoutPlan,
    this.nutritionPlan,
  });
}

class AICoachService {
  // Singleton pattern for clean architecture
  static final AICoachService _instance = AICoachService._internal();
  factory AICoachService() => _instance;
  AICoachService._internal();

  /// Generates an initial welcome greeting based on real user context
  ChatMessageModel generateWelcomeMessage(UserFitnessContext context) {
    String greeting;
    if (context.streakDays >= 7) {
      greeting = "🔥 Hey ${context.userName}! You're on an incredible **${context.streakDays}-day streak**! I'm Coach Alex, your AI personal trainer. What are we crushing today?";
    } else if (context.hasWorkedOutToday) {
      greeting = "💪 Fantastic effort today, ${context.userName}! You've already burned **${context.todayCalories} kcal** today. I'm ready to optimize your recovery, nutrition, or plan tomorrow's session.";
    } else {
      greeting = "👋 Hello ${context.userName}! I'm Coach Alex, your personal fitness & nutrition AI. How can I help you reach your ${context.targetWeight} kg goal today?";
    }

    return ChatMessageModel(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      content: greeting,
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
    );
  }

  /// Generates dynamic daily tip for home dashboard
  String getDailyTip(UserFitnessContext context) {
    final tips = [
      "💧 Hydration accelerates fat burn! Aim for ${(context.currentWeight * 35).round()} ml water today.",
      "💤 Sleep is where muscles repair and fat is metabolized. Prioritize 7-8 hours tonight.",
      "🔥 Consistency beats intensity every single time. Keep that ${context.streakDays}-day streak alive!",
      "🥗 Protein preserves lean tissue during a deficit. Aim for ${(context.currentWeight * 1.8).round()}g daily.",
      "🏃 A brisk 15-minute walk after meals blunts glucose spikes and enhances digestion.",
    ];
    return tips[Random().nextInt(tips.length)];
  }

  /// Generates today's recommendation for home dashboard
  String getTodaysRecommendation(UserFitnessContext context) {
    if (context.hasWorkedOutToday) {
      return "Active Recovery: Foam rolling, 15m deep stretch, and replenish with high-protein dinner.";
    }
    if (context.streakDays > 0) {
      return "Streak Fuel: 30-min Metabolic HIIT or Upper Body Circuit to maintain your ${context.streakDays}-day momentum.";
    }
    return "Kickstart: 25-min Full Body Calisthenics to ignite your weekly energy!";
  }

  /// Core response engine - easily swappable with a live Gemini REST API call
  Future<AICoachResponse> processPrompt({
    required String prompt,
    required UserFitnessContext context,
  }) async {
    // Simulate natural AI thinking delay (600 - 1200ms) for high-craft UX
    await Future.delayed(const Duration(milliseconds: 800));

    final normalized = prompt.toLowerCase().trim();

    // 1. Lose Weight
    if (normalized.contains('lose weight') || normalized.contains('fat loss') || normalized.contains('burn fat')) {
      return _generateWeightLossResponse(context);
    }

    // 2. 20 Minutes Workout
    if (normalized.contains('20 min') || normalized.contains('20 minutes') || normalized.contains('short workout') || normalized.contains('quick workout')) {
      return _generate20MinuteWorkoutResponse(context);
    }

    // 3. Today's Workout suggestion
    if (normalized.contains("today's workout") || normalized.contains('suggest workout') || normalized.contains('what should i do today')) {
      return _generateTodaysWorkoutResponse(context);
    }

    // 4. Muscle Gain Plan
    if (normalized.contains('muscle gain') || normalized.contains('hypertrophy') || normalized.contains('build muscle') || normalized.contains('bulk')) {
      return _generateMuscleGainResponse(context);
    }

    // 5. Stamina & Cardio
    if (normalized.contains('stamina') || normalized.contains('cardio') || normalized.contains('endurance') || normalized.contains('running')) {
      return _generateStaminaResponse(context);
    }

    // 6. Beginner Workout
    if (normalized.contains('beginner') || normalized.contains('start working out') || normalized.contains('new to fitness')) {
      return _generateBeginnerWorkoutResponse(context);
    }

    // 7. Stretching & Mobility
    if (normalized.contains('stretch') || normalized.contains('mobility') || normalized.contains('sore') || normalized.contains('flexibility')) {
      return _generateStretchingResponse(context);
    }

    // 8. Post-workout nutrition / Meal advice
    if (normalized.contains('eat after') || normalized.contains('post-workout') || normalized.contains('nutrition') || normalized.contains('diet') || normalized.contains('food')) {
      return _generateNutritionResponse(context);
    }

    // 9. Motivation
    if (normalized.contains('motivation') || normalized.contains('inspire') || normalized.contains('tired') || normalized.contains('lazy') || normalized.contains('give up')) {
      return _generateMotivationResponse(context);
    }

    // Default intelligent personal trainer response
    return _generateConversationalResponse(prompt, context);
  }

  // ==================== GENERATORS ====================

  AICoachResponse _generateWeightLossResponse(UserFitnessContext context) {
    final weightDiff = (context.currentWeight - context.targetWeight).abs().toStringAsFixed(1);
    final proteinGrams = (context.currentWeight * 2.0).round();
    final targetKcal = (context.calorieGoal * 0.85).round();

    final plan = WorkoutPlanModel(
      title: 'High-Calorie Fat Burn HIIT',
      difficulty: 'Intermediate',
      estimatedDuration: '30 min',
      estimatedCalories: 320,
      warmup: ['Arm Circles & Torso Twists (2 min)', 'Jumping Jacks (2 min)', 'High Knees (1 min)'],
      exercises: const [
        WorkoutExerciseModel(name: 'Kettlebell / Dumbbell Goblet Squats', sets: 4, reps: '15 reps', restTime: '45s', targetMuscle: 'Quads & Glutes'),
        WorkoutExerciseModel(name: 'Mountain Climbers into Push-Ups', sets: 4, reps: '40s work', restTime: '30s', targetMuscle: 'Core & Upper Body'),
        WorkoutExerciseModel(name: 'Dumbbell Renegade Rows', sets: 3, reps: '12 per side', restTime: '45s', targetMuscle: 'Back & Core'),
        WorkoutExerciseModel(name: 'Burpee to Box / Broad Jump', sets: 3, reps: '10 reps', restTime: '60s', targetMuscle: 'Full Body Explosive'),
      ],
      cooldown: ['Hamstring & Quad Static Stretch', 'Child\'s Pose Deep Breathing (3 min)'],
    );

    return AICoachResponse(
      text: "### 🎯 Sustainable Weight Loss Strategy for ${context.userName}\n\n"
          "Your current weight is **${context.currentWeight} kg** with a BMI of **${context.bmi} (${context.bmiCategory})**. "
          "To reach your target of **${context.targetWeight} kg** (a **$weightDiff kg** transformation), we need a calibrated balance of a mild caloric deficit and high-density metabolic resistance training.\n\n"
          "**Key Guidelines:**\n"
          "- **Calorie Target**: Aim for approximately **$targetKcal kcal/day**\n"
          "- **Protein Anchor**: Consume **${proteinGrams}g of protein** daily to protect lean muscle while shredding fat.\n"
          "- **Daily Steps**: Keep exceeding your **${context.stepsGoal} steps** goal (you're currently at **${context.todaySteps} steps** today!)\n\n"
          "Here is your customized fat-burning circuit tailored to maximize EPOC (Excess Post-Exercise Oxygen Consumption):",
      workoutPlan: plan,
    );
  }

  AICoachResponse _generate20MinuteWorkoutResponse(UserFitnessContext context) {
    final plan = WorkoutPlanModel(
      title: '20-Minute Express Metabolic Blast',
      difficulty: 'All Levels',
      estimatedDuration: '20 min',
      estimatedCalories: 210,
      warmup: ['Arm Swings & Leg Swings (90 sec)', 'Light Jog in Place (90 sec)'],
      exercises: const [
        WorkoutExerciseModel(name: 'Bodyweight Squats to Jump', sets: 3, reps: '45s on / 15s off', restTime: '15s', targetMuscle: 'Lower Body'),
        WorkoutExerciseModel(name: 'Tempo Push-Ups (3s eccentric)', sets: 3, reps: '45s on / 15s off', restTime: '15s', targetMuscle: 'Chest & Triceps'),
        WorkoutExerciseModel(name: 'Reverse Lunges with Knee Drive', sets: 3, reps: '45s on / 15s off', restTime: '15s', targetMuscle: 'Legs & Balance'),
        WorkoutExerciseModel(name: 'Bicycle Crunches & Plank Hold', sets: 3, reps: '60s continuous', restTime: '30s', targetMuscle: 'Abs & Obliques'),
      ],
      cooldown: ['Cat-Cow Stretch (1 min)', 'Shoulder & Chest Opener (1 min)'],
    );

    return AICoachResponse(
      text: "⚡ **Only 20 minutes? That is more than enough for a killer session!**\n\n"
          "Short, focused workouts keep your metabolism revved up and maintain your **${context.streakDays}-day streak**. "
          "Zero equipment required. Keep your rest periods strictly under 20 seconds to keep your heart rate in the training zone.",
      workoutPlan: plan,
    );
  }

  AICoachResponse _generateTodaysWorkoutResponse(UserFitnessContext context) {
    if (context.hasWorkedOutToday) {
      final plan = WorkoutPlanModel(
        title: 'Post-Workout Active Recovery & Alignment',
        difficulty: 'Gentle',
        estimatedDuration: '18 min',
        estimatedCalories: 75,
        warmup: ['Gentle Neck & Shoulder Rolls', 'Standing Side Bends'],
        exercises: const [
          WorkoutExerciseModel(name: 'World\'s Greatest Stretch', sets: 2, reps: '5 per side', restTime: '30s', targetMuscle: 'Hips & Thoracic Spine'),
          WorkoutExerciseModel(name: 'Pigeon Pose Hip Opener', sets: 2, reps: '60s per side', restTime: '20s', targetMuscle: 'Glutes & Hip Flexors'),
          WorkoutExerciseModel(name: 'Thoracic Foam Rolling / Thread Needle', sets: 2, reps: '8 per side', restTime: '30s', targetMuscle: 'Mid-Back'),
          WorkoutExerciseModel(name: 'Legs-Up-The-Wall Restorative Hold', sets: 1, reps: '5 minutes', restTime: '0s', targetMuscle: 'Circulation & Nervous System'),
        ],
      );

      return AICoachResponse(
        text: "You already logged a workout today and burned **${context.todayCalories} kcal**! 👏\n\n"
            "Overtraining hinders progress. Today's optimal protocol is an **Active Recovery Session** to flush lactic acid, restore mobility, and prepare you for tomorrow.",
        workoutPlan: plan,
      );
    }

    final plan = WorkoutPlanModel(
      title: 'Full Body Power & Core Alignment',
      difficulty: 'Intermediate',
      estimatedDuration: '35 min',
      estimatedCalories: 280,
      warmup: ['Hip 90/90s (2 min)', 'Inchworms with Push-Up (2 min)', 'Glute Bridges (2 min)'],
      exercises: const [
        WorkoutExerciseModel(name: 'Dumbbell Romanian Deadlifts', sets: 4, reps: '10-12 reps', restTime: '60s', targetMuscle: 'Hamstrings & Posterior Chain'),
        WorkoutExerciseModel(name: 'Overhead Dumbbell Press', sets: 4, reps: '8-10 reps', restTime: '60s', targetMuscle: 'Deltoids & Triceps'),
        WorkoutExerciseModel(name: 'Bulgarian Split Squats', sets: 3, reps: '10 per leg', restTime: '60s', targetMuscle: 'Quads & Glutes'),
        WorkoutExerciseModel(name: 'Hanging / Lying Leg Raises', sets: 3, reps: '15 reps', restTime: '45s', targetMuscle: 'Lower Abs'),
      ],
      cooldown: ['Cobra to Downward Dog (2 min)', 'Seated Spinal Twist (2 min)'],
    );

    return AICoachResponse(
      text: "Here is your prescription for today, ${context.userName}! Since your daily goal is **${context.workoutMinutesGoal} minutes**, this 35-minute full body power routine is perfectly paced.",
      workoutPlan: plan,
    );
  }

  AICoachResponse _generateMuscleGainResponse(UserFitnessContext context) {
    final proteinGrams = (context.currentWeight * 2.2).round();
    final surplusKcal = context.calorieGoal + 300;

    final plan = WorkoutPlanModel(
      title: 'Hypertrophy Push-Pull Compound Builder',
      difficulty: 'Advanced',
      estimatedDuration: '45 min',
      estimatedCalories: 340,
      warmup: ['Band Pull-Aparts (2x15)', 'Dynamic Wrist & Shoulder Mobility (3 min)', 'Empty Barbell / Light Warmup Sets'],
      exercises: const [
        WorkoutExerciseModel(name: 'Incline Dumbbell Chest Press', sets: 4, reps: '8-10 reps (RPE 8)', restTime: '90s', targetMuscle: 'Upper Chest & Front Delts'),
        WorkoutExerciseModel(name: 'Barbell Bent-Over Row', sets: 4, reps: '8-10 reps', restTime: '90s', targetMuscle: 'Lats & Rhomboids'),
        WorkoutExerciseModel(name: 'Standing Overhead Barbell Press', sets: 3, reps: '6-8 reps', restTime: '90s', targetMuscle: 'Shoulders & Core'),
        WorkoutExerciseModel(name: 'Incline Dumbbell Hammer Curls', sets: 3, reps: '10-12 reps', restTime: '60s', targetMuscle: 'Biceps & Brachialis'),
        WorkoutExerciseModel(name: 'Cable Overhead Triceps Extensions', sets: 3, reps: '12-15 reps', restTime: '60s', targetMuscle: 'Long Head Triceps'),
      ],
      cooldown: ['Chest Doorway Stretch (2 min)', 'Cross-Body Shoulder Stretch (2 min)'],
    );

    return AICoachResponse(
      text: "### 💪 Hypertrophy Blueprint for ${context.userName}\n\n"
          "Building lean muscle requires progressive mechanical tension, a calorie surplus, and ample amino acid availability.\n\n"
          "- **Daily Calorie Target**: **~$surplusKcal kcal** (slight 250-300 kcal lean bulk surplus)\n"
          "- **Protein Target**: **${proteinGrams}g** (${(proteinGrams / 4).round()}g per meal over 4 meals)\n"
          "- **Sleep**: Target at least **8 hours** (you averaged ${context.todaySleepHours} hrs recently).\n\n"
          "Here is today's targeted hypertrophy session:",
      workoutPlan: plan,
    );
  }

  AICoachResponse _generateStaminaResponse(UserFitnessContext context) {
    final plan = WorkoutPlanModel(
      title: 'VO2 Max & Aerobic Threshold Intervals',
      difficulty: 'Intermediate',
      estimatedDuration: '30 min',
      estimatedCalories: 310,
      warmup: ['Light Jog (3 min)', 'Dynamic High Knees, Butt Kicks, A-Skips (3 min)'],
      exercises: const [
        WorkoutExerciseModel(name: 'Zone 4 Hard Run / Rowing Surge', sets: 5, reps: '2 min hard pace (85% HR max)', restTime: '90s light jog', targetMuscle: 'Cardiovascular System'),
        WorkoutExerciseModel(name: 'Sprint Intervals', sets: 6, reps: '30s sprint (95% HR)', restTime: '60s walk', targetMuscle: 'Fast-Twitch & Aerobic Capacity'),
        WorkoutExerciseModel(name: 'Steady Zone 2 Recovery Flush', sets: 1, reps: '8 minutes continuous', restTime: '0s', targetMuscle: 'Mitochondrial Density'),
      ],
      cooldown: ['Calf, Achilles & Hamstring static stretches', 'Deep diaphragmatic breathing'],
    );

    return AICoachResponse(
      text: "🏃 **To build relentless stamina, we train both your aerobic base (Zone 2) and top-end VO2 Max!**\n\n"
          "You've already clocked **${context.todaySteps} steps** today. This interval protocol will expand your lung capacity and lower your resting heart rate over time.",
      workoutPlan: plan,
    );
  }

  AICoachResponse _generateBeginnerWorkoutResponse(UserFitnessContext context) {
    final plan = WorkoutPlanModel(
      title: 'Foundations of Movement: Beginner Full Body',
      difficulty: 'Beginner',
      estimatedDuration: '22 min',
      estimatedCalories: 160,
      warmup: ['Neck rolls & Shoulder shrugs', 'Hip circles & Ankle rotations', 'Gentle high knee marches (2 min)'],
      exercises: const [
        WorkoutExerciseModel(name: 'Chair / Box Squats', sets: 3, reps: '10-12 controlled reps', restTime: '60s', targetMuscle: 'Thighs & Balance', notes: 'Focus on keeping chest upright'),
        WorkoutExerciseModel(name: 'Incline Wall or Counter Push-Ups', sets: 3, reps: '8-10 reps', restTime: '60s', targetMuscle: 'Chest & Arms', notes: 'Keep body in straight plank line'),
        WorkoutExerciseModel(name: 'Glute Bridges on Mat', sets: 3, reps: '12 reps (2s hold at top)', restTime: '45s', targetMuscle: 'Glutes & Lower Back'),
        WorkoutExerciseModel(name: 'Bird-Dog Core Stability', sets: 3, reps: '6 per side', restTime: '45s', targetMuscle: 'Core & Spine Stability'),
      ],
      cooldown: ['Seated Hamstring Reach (1 min)', 'Child\'s Pose (2 min)'],
    );

    return AICoachResponse(
      text: "🌟 **Welcome to your fitness journey, ${context.userName}!**\n\n"
          "The most important rule right now is **form over weight** and **consistency over intensity**. "
          "This beginner foundational routine is joint-friendly, highly effective, and designed to build confident movement patterns without soreness paralysis.",
      workoutPlan: plan,
    );
  }

  AICoachResponse _generateStretchingResponse(UserFitnessContext context) {
    final plan = WorkoutPlanModel(
      title: 'Full Body Mobility & Tension Release',
      difficulty: 'All Levels',
      estimatedDuration: '15 min',
      estimatedCalories: 60,
      warmup: ['Deep belly breathing (1 min)', 'Gentle arm and torso twists (1 min)'],
      exercises: const [
        WorkoutExerciseModel(name: 'Cat-Cow Spinal Waves', sets: 2, reps: '10 rhythmic breaths', restTime: '15s', targetMuscle: 'Spine & Abdominals'),
        WorkoutExerciseModel(name: 'Deep Squat Pry with Thoracic Reach', sets: 2, reps: '60s hold', restTime: '30s', targetMuscle: 'Hips, Ankles & Mid-Back'),
        WorkoutExerciseModel(name: 'Kneeling Hip Flexor / Couch Stretch', sets: 2, reps: '45s per side', restTime: '20s', targetMuscle: 'Psoas & Quads'),
        WorkoutExerciseModel(name: 'Puppy Dog Shoulder Opener', sets: 2, reps: '45s hold', restTime: '20s', targetMuscle: 'Lats & Chest'),
      ],
      cooldown: ['Corpse Pose (Savasana) with deep exhales (2 min)'],
    );

    return AICoachResponse(
      text: "🧘 **Daily mobility is the secret to injury prevention and better workout power.**\n\n"
          "If you've been sitting at a desk or pushed hard during your recent workouts, this 15-minute mobility flow will decompress your spine and free up tight hips.",
      workoutPlan: plan,
    );
  }

  AICoachResponse _generateNutritionResponse(UserFitnessContext context) {
    final proteinTarget = (context.currentWeight * 1.8).round();
    final waterTarget = ((context.currentWeight * 35) / 1000).toStringAsFixed(1);

    final nutrition = NutritionPlanModel(
      title: 'Optimized Recovery & Lean Fuel Blueprint',
      breakfast: '3 scrambled eggs with spinach + 1/2 avocado on sourdough toast + black coffee / green tea',
      lunch: 'Grilled chicken breast (180g) with quinoa, mixed greens, cherry tomatoes, and olive oil dressing',
      dinner: 'Wild salmon fillet (180g) or tofu with roasted sweet potato cubes & steamed broccoli',
      snacks: ['Greek yogurt (0% fat) with blueberries & walnuts', 'Whey / Plant protein shake after workout', 'Apple slices with almond butter'],
      hydration: '$waterTarget Liters daily (currently ${context.todayWaterMl} ml logged)',
      proteinTargetGrams: proteinTarget,
      totalCalories: context.calorieGoal > 0 ? context.calorieGoal : 2100,
      keyTips: [
        'Post-Workout Golden Hour: Consume 25-35g fast-digesting protein + carbs within 45 min.',
        'Hydration Check: Drink 500ml water immediately upon waking.',
        'Color Rule: Ensure your lunch and dinner plates have at least 2 distinct vegetable colors.',
      ],
    );

    return AICoachResponse(
      text: "### 🍎 Personalized Nutrition Strategy for ${context.userName}\n\n"
          "Eating properly is 75% of your fitness results. Tailored to your weight of **${context.currentWeight} kg**:\n\n"
          "- **Daily Protein Target**: **${proteinTarget}g**\n"
          "- **Daily Hydration Goal**: **$waterTarget L** (you've had **${context.todayWaterMl} ml** today)\n"
          "- **Post-Workout Window**: Prioritize a 3:1 or 2:1 Carb-to-Protein ratio to refill depleted glycogen and synthesize new muscle fibers.\n\n"
          "Here is your clean meal layout for today:",
      nutritionPlan: nutrition,
    );
  }

  AICoachResponse _generateMotivationResponse(UserFitnessContext context) {
    String motivationMsg;

    if (context.streakDays >= 14) {
      motivationMsg = "🔥 **LOOK AT THAT ${context.streakDays}-DAY STREAK, ${context.userName}!**\n\n"
          "Do you know how rare that is? Most people quit on day 3. You showed up through busy schedules, tired mornings, and excuses. "
          "You've already unlocked **${context.unlockedAchievementsCount} achievements**"
          "${context.recentAchievementTitle != null ? ' including *${context.recentAchievementTitle}*' : ''}. "
          "Remember: Champions don't look for motivation; they rely on identity. You are an athlete. Keep blazing!";
    } else if (context.streakDays > 0) {
      motivationMsg = "⚡ **You are ${context.streakDays} days into building the strongest version of yourself!**\n\n"
          "Every rep, every drop of sweat, and every healthy choice is a vote for who you are becoming. "
          "Your target is **${context.targetWeight} kg**, and every day you log brings that reality closer. "
          "Don't negotiate with your inner critic—lace up your shoes and get 1% better today!";
    } else if (!context.hasWorkedOutToday) {
      motivationMsg = "🌅 **Today is Day 1 of your new streak!**\n\n"
          "It doesn't matter what happened yesterday or last week. The only workout you'll ever regret is the one you didn't do. "
          "Even 15 minutes counts. You have **${context.todayCalories} kcal** burned so far—let's push that number higher and finish today proud!";
    } else {
      motivationMsg = "🎯 **Great work today, ${context.userName}!**\n\n"
          "You've already put in the work with **${context.todayCalories} kcal burned** and **${context.todaySteps} steps**. "
          "Rest with purpose, fuel your body, and wake up ready to conquer tomorrow.";
    }

    return AICoachResponse(text: motivationMsg);
  }

  AICoachResponse _generateConversationalResponse(String prompt, UserFitnessContext context) {
    return AICoachResponse(
      text: "I hear you, ${context.userName}! As your personal trainer, here is my advice on **\"$prompt\"**:\n\n"
          "- **Contextual Check**: You're currently on a **${context.streakDays}-day streak** with **${context.todaySteps} steps** and **${context.todayCalories} kcal** logged today.\n"
          "- **Recommendation**: Keep your daily habits aligned with your **${context.targetWeight} kg target weight**. If you're feeling sluggish, check hydration (${context.todayWaterMl} ml so far) and sleep (${context.todaySleepHours} hrs).\n\n"
          "Would you like me to generate a custom workout, adjust your macros, or map out a quick 20-minute plan?",
    );
  }
}
