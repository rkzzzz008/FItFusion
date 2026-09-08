import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fitness_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circular_goal_ring.dart';
import '../widgets/metric_summary_card.dart';
import '../widgets/water_intake_widget.dart';
import '../widgets/workout_card.dart';
import '../widgets/streak_card.dart';
import '../widgets/streak_milestone_dialog.dart';
import '../providers/achievement_provider.dart';
import '../widgets/achievement_card.dart';
import '../widgets/achievement_progress_ring.dart';
import '../widgets/achievement_unlock_dialog.dart';
import 'achievement_screen.dart';
import '../providers/calendar_provider.dart';
import 'calendar_screen.dart';
import '../providers/ai_coach_provider.dart';
import '../providers/auth_provider.dart';
import 'ai_coach_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToActivity;
  final VoidCallback onNavigateToGoals;
  final VoidCallback onOpenAddWorkout;

  const HomeScreen({
    super.key,
    required this.onNavigateToActivity,
    required this.onNavigateToGoals,
    required this.onOpenAddWorkout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _lastHandledMilestone;
  bool _coachInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize AI Coach context once, safely after the first frame.
    // Must NOT call notifyListeners() inside build(), so we defer here.
    if (!_coachInitialized) {
      _coachInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final coachProv = Provider.of<AICoachProvider>(context, listen: false);
        if (!coachProv.isInitialized) {
          final authProv = Provider.of<AuthProvider>(context, listen: false);
          final fitness = Provider.of<FitnessProvider>(context, listen: false);
          final achievementProv =
              Provider.of<AchievementProvider>(context, listen: false);
          coachProv.initContext(
            profile: authProv.profile,
            fitness: fitness,
            achievements: achievementProv,
          );
        }
      });
    }
  }

  void _checkAndTriggerMilestone(
      BuildContext context, FitnessProvider fitness) {
    final milestone = fitness.milestoneCelebrationTarget;
    if (milestone != null && milestone != _lastHandledMilestone) {
      _lastHandledMilestone = milestone;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        StreakMilestoneDialog.show(context, milestone).then((_) {
          if (mounted) {
            fitness.dismissMilestoneCelebration();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fitness = Provider.of<FitnessProvider>(context);
    final achievementProv = Provider.of<AchievementProvider>(context);
    final calendarProv = Provider.of<CalendarProvider>(context);
    final coachProv = Provider.of<AICoachProvider>(context);
    final monthlyStats = calendarProv.getMonthlyStats(fitness);

    _checkAndTriggerMilestone(context, fitness);

    // Defer achievement celebration dialog — must NOT mutate provider state
    // synchronously inside build().
    if (achievementProv.newlyUnlockedAchievement != null) {
      final newlyUnlocked = achievementProv.newlyUnlockedAchievement!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        achievementProv.dismissUnlockCelebration();
        AchievementUnlockDialog.show(context, newlyUnlocked);
      });
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back,',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          'Alex Rivers',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Streak Pill (tap to view milestone details)
                    InkWell(
                      onTap: () {
                        StreakMilestoneDialog.show(
                          context,
                          fitness.streak.currentStreak >= 7
                              ? (fitness.streak.currentStreak >= 30
                                  ? (fitness.streak.currentStreak >= 100
                                      ? 100
                                      : 30)
                                  : 7)
                              : 7,
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.local_fire_department,
                                color: AppColors.accent, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${fitness.streak.currentStreak}d Streak',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Prominent AI Fitness Coach Card (Near top of dashboard)
                _buildAICoachCard(context, isDark, coachProv),
                const SizedBox(height: 16),

                // Daily Streak System Card
                StreakCard(
                  streak: fitness.streak,
                  onLogWorkout: widget.onOpenAddWorkout,
                  onTestMilestone: (days) {
                    StreakMilestoneDialog.show(context, days);
                  },
                ),
                const SizedBox(height: 16),

                // Monthly Mini Calendar Card
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CalendarScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1B2434), const Color(0xFF141D2B)]
                            : [Colors.white, const Color(0xFFF8FAFC)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary
                              .withValues(alpha: isDark ? 0.08 : 0.04),
                          blurRadius: 14,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Workout Calendar',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Monthly activity & heatmap',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Row(
                              children: [
                                const Text(
                                  'View',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Mini metrics 3-column glance
                        Row(
                          children: [
                            // 1. Today's Workout
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "TODAY'S WORKOUT",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      fitness.workouts.any((w) {
                                        final now = DateTime.now();
                                        return w.date.year == now.year &&
                                            w.date.month == now.month &&
                                            w.date.day == now.day;
                                      })
                                          ? 'Completed ✓'
                                          : 'Rest / Pending',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: fitness.workouts.any((w) {
                                          final now = DateTime.now();
                                          return w.date.year == now.year &&
                                              w.date.month == now.month &&
                                              w.date.day == now.day;
                                        })
                                            ? AppColors.primary
                                            : (isDark
                                                ? Colors.white70
                                                : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 2. Current Streak
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CURRENT STREAK',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '🔥 ${fitness.streak.currentStreak} Days',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 3. Upcoming Goals
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.04)
                                      : Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'UPCOMING GOAL',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '🎯 ${fitness.goals.dailyCalories} kcal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.lightTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Monthly Completion % Progress Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Monthly Completion %',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              '${(monthlyStats.monthlyCompletionPercent * 100).toInt()}% Target Met',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: monthlyStats.monthlyCompletionPercent,
                            minHeight: 6,
                            backgroundColor:
                                isDark ? Colors.white12 : Colors.black12,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Main Goal Ring Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircularGoalRing(
                        progress: fitness.overallScorePercent / 100.0,
                        percentage: fitness.overallScorePercent,
                        title: 'Daily Goal',
                        subtitle: 'Score',
                        radius: 56.0,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fitness.overallScorePercent >= 100
                                  ? 'Daily Goals Crushed!'
                                  : 'Target on Track',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${fitness.todayCaloriesBurned} of ${fitness.goals.dailyCalories} kcal consumed through active motion today.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Quick simulate steps button
                            OutlinedButton.icon(
                              onPressed: () => fitness.addSteps(500),
                              icon: const Icon(Icons.add_road, size: 16),
                              label: const Text('+500 Steps',
                                  style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side:
                                    const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2x2 Telemetry Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.16,
                  children: [
                    MetricSummaryCard(
                      title: 'Steps Taken',
                      value: '${fitness.todaySteps}',
                      unit: '/ ${fitness.goals.dailySteps}',
                      icon: Icons.directions_walk_rounded,
                      accentColor: AppColors.primary,
                      progress: fitness.stepsProgress,
                    ),
                    MetricSummaryCard(
                      title: 'Active Energy',
                      value: '${fitness.todayCaloriesBurned}',
                      unit: 'kcal',
                      icon: Icons.local_fire_department_rounded,
                      accentColor: AppColors.calories,
                      progress: fitness.caloriesProgress,
                    ),
                    MetricSummaryCard(
                      title: 'Workout Time',
                      value: '${fitness.todayWorkoutMinutes}',
                      unit: 'min',
                      icon: Icons.fitness_center_rounded,
                      accentColor: AppColors.secondary,
                      progress: fitness.workoutProgress,
                    ),
                    MetricSummaryCard(
                      title: 'Sleep Target',
                      value: '${fitness.todaySleepHours}',
                      unit: 'hrs',
                      icon: Icons.bedtime_rounded,
                      accentColor: AppColors.sleep,
                      progress: 0.94,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Hydration Tracker
                WaterIntakeWidget(
                  currentMl: fitness.todayWaterMl,
                  goalMl: fitness.goals.dailyWaterMl,
                  onAddWater: (amount) => fitness.addWater(amount),
                ),
                const SizedBox(height: 24),

                // Achievements & Badges Showcase
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'Achievements & Badges',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AchievementScreen(),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Achievement Progress % and Total Badges Unlocked Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E2638), const Color(0xFF151D2A)]
                          : [Colors.white, const Color(0xFFF8FAFC)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B)
                            .withValues(alpha: isDark ? 0.08 : 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AchievementProgressRing(
                        progress: achievementProv.overallProgressPercentage,
                        totalUnlocked: achievementProv.totalUnlocked,
                        totalBadges: achievementProv.totalAchievements,
                        size: 72,
                        strokeWidth: 7,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Badges Unlocked',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: isDark
                                        ? Colors.white70
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                                Text(
                                  '${achievementProv.overallProgressPercent}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${achievementProv.totalUnlocked} of ${achievementProv.totalAchievements} Badges',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value:
                                    achievementProv.overallProgressPercentage,
                                minHeight: 5,
                                backgroundColor:
                                    isDark ? Colors.white12 : Colors.black12,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF59E0B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Recent Achievement Card (if unlocked)
                if (achievementProv.recentUnlockedAchievement != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Text(
                        'Recent Achievement',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white70
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AchievementCard(
                    achievement: achievementProv.recentUnlockedAchievement!,
                    isCompact: true,
                    onTap: () {
                      AchievementUnlockDialog.show(
                        context,
                        achievementProv.recentUnlockedAchievement!,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // Next Achievement Card (if next locked milestone exists)
                if (achievementProv.nextLockedAchievement != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.track_changes_rounded,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: 6),
                      Text(
                        'Next Achievement to Unlock',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white70
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AchievementCard(
                    achievement: achievementProv.nextLockedAchievement!,
                    isCompact: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AchievementScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 10),

                // Recent Workouts Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Sessions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onNavigateToActivity,
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Recent Workouts List
                if (fitness.workouts.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      'No workouts logged today. Tap + to record your first session!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  )
                else
                  ...fitness.workouts.take(3).map(
                        (w) => WorkoutCard(
                          workout: w,
                          onDelete: () => fitness.deleteWorkout(w.id),
                        ),
                      ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAICoachCard(
      BuildContext context, bool isDark, AICoachProvider coach) {
    const quickChips = [
      {
        'label': 'Lose Weight',
        'icon': '🔥',
        'prompt': 'How can I lose weight sustainably with my current stats?'
      },
      {
        'label': 'Build Muscle',
        'icon': '💪',
        'prompt': 'Build a muscle gain plan tailored to my body.'
      },
      {
        'label': 'Cardio',
        'icon': '🏃',
        'prompt': 'How can I improve my stamina and aerobic capacity?'
      },
      {
        'label': 'Stretch',
        'icon': '🧘',
        'prompt':
            'Suggest stretching exercises to relieve tightness and soreness.'
      },
      {
        'label': 'Nutrition',
        'icon': '🍎',
        'prompt': 'What should I eat after my workout to optimize recovery?'
      },
      {
        'label': 'Quick Workout',
        'icon': '⚡',
        'prompt': 'I have only 20 minutes today. Give me an intense session.'
      },
    ];

    void openAICoach([String? prompt]) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AICoachScreen(initialPrompt: prompt),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openAICoach(),
        borderRadius: BorderRadius.circular(24),
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: AppColors.primary.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF192233), const Color(0xFF131B28)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Coach Avatar + Title + Badge + Quick Ask Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Hero(
                          tag: 'ai_coach_avatar',
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xFF047857)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Coach Alex',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'AI COACH',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Personal AI Fitness Trainer & Advisor',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chat Button
                  ElevatedButton.icon(
                    onPressed: () => openAICoach(),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 13),
                    label: const Text('Chat',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 1. Today's Recommendation Block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E283A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2B384E)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.track_changes_rounded,
                            size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        const Text(
                          "TODAY'S RECOMMENDATION",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      coach.todaysRecommendation,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.white : AppColors.lightTextPrimary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // 2. Daily Tip Block
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C2534)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF283446)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DAILY COACH TIP',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            coach.dailyTip,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Quick Actions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const Row(
                    children: [
                      const Text(
                        'Tap card to open chat',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 4. Quick Action Chips Wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickChips.map((chip) {
                  return InkWell(
                    onTap: () => openAICoach(chip['prompt']),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E283A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(chip['icon']!,
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 5),
                          Text(
                            chip['label']!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
