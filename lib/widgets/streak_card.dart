import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/daily_streak_model.dart';
import '../theme/app_theme.dart';

class StreakCard extends StatefulWidget {
  final DailyStreakModel streak;
  final VoidCallback onLogWorkout;
  final Function(int days)? onTestMilestone;

  const StreakCard({
    super.key,
    required this.streak,
    required this.onLogWorkout,
    this.onTestMilestone,
  });

  @override
  State<StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<StreakCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatLastWorkout(DateTime? date) {
    if (date == null) return 'No workouts yet';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workoutDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(workoutDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = widget.streak;
    final hasWorkoutToday = streak.hasWorkedOutToday;
    final isAtRisk = streak.isAtRisk;

    // Milestone calculation
    final nextMilestone = streak.nextMilestone;
    final progress = streak.milestoneProgress;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasWorkoutToday
              ? AppColors.primary.withOpacity(0.35)
              : (isAtRisk
                  ? AppColors.calories.withOpacity(0.4)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          width: hasWorkoutToday || isAtRisk ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasWorkoutToday ? AppColors.primary : AppColors.calories)
                .withOpacity(isDark ? 0.08 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Flame + Animated Streak Counter + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Pulsing Flame Icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (_pulseController.value * 0.08);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.calories,
                            AppColors.accent,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.calories.withOpacity(
                              0.3 + (_pulseController.value * 0.25),
                            ),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),

              // Streak Count with Animated Number
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Animated Switcher for Streak Number
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.4),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            '${streak.currentStreak}',
                            key: ValueKey<int>(streak.currentStreak),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          streak.currentStreak == 1 ? 'Day Streak' : 'Days Streak',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasWorkoutToday
                          ? 'Active streak kept alive!'
                          : (isAtRisk
                              ? 'Workout today to keep your streak!'
                              : 'Log a session to fuel the fire'),
                      style: TextStyle(
                        fontSize: 12,
                        color: hasWorkoutToday
                            ? AppColors.primary
                            : (isAtRisk ? AppColors.calories : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                        fontWeight: hasWorkoutToday || isAtRisk ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Today's Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: hasWorkoutToday
                      ? AppColors.primary.withOpacity(0.15)
                      : (isAtRisk
                          ? AppColors.calories.withOpacity(0.15)
                          : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasWorkoutToday
                        ? AppColors.primary.withOpacity(0.3)
                        : (isAtRisk ? AppColors.calories.withOpacity(0.3) : Colors.transparent),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasWorkoutToday
                          ? Icons.check_circle_rounded
                          : (isAtRisk ? Icons.alarm_rounded : Icons.fitness_center_rounded),
                      size: 14,
                      color: hasWorkoutToday
                          ? AppColors.primary
                          : (isAtRisk ? AppColors.calories : (isDark ? Colors.white70 : AppColors.lightTextSecondary)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasWorkoutToday
                          ? 'Done Today'
                          : (isAtRisk ? 'Pending' : 'Ready'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasWorkoutToday
                            ? AppColors.primary
                            : (isAtRisk ? AppColors.calories : (isDark ? Colors.white70 : AppColors.lightTextSecondary)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Milestone Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Next Milestone: $nextMilestone Days',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.calories,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.calories),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Milestone Badges Row (7d, 30d, 100d)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMilestonePill(
                days: 7,
                label: '7d Warrior',
                icon: '⚡',
                current: streak.currentStreak,
                isDark: isDark,
                onTap: () => widget.onTestMilestone?.call(7),
              ),
              _buildMilestonePill(
                days: 30,
                label: '30d Master',
                icon: '🏆',
                current: streak.currentStreak,
                isDark: isDark,
                onTap: () => widget.onTestMilestone?.call(30),
              ),
              _buildMilestonePill(
                days: 100,
                label: '100d Legend',
                icon: '👑',
                current: streak.currentStreak,
                isDark: isDark,
                onTap: () => widget.onTestMilestone?.call(100),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(height: 14),

          // Footer: Longest Streak, Last Active Date, and Action
          Row(
            children: [
              // Longest Streak
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Best Record',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          '${streak.longestStreak} days',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Last Workout Date
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Workout',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          _formatLastWorkout(streak.lastWorkoutDate),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Log workout or checkmark action button
              if (!hasWorkoutToday)
                ElevatedButton.icon(
                  onPressed: widget.onLogWorkout,
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: const Text('+ Workout', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Secured',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonePill({
    required int days,
    required String label,
    required String icon,
    required int current,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final reached = current >= days;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: reached
              ? AppColors.accent.withOpacity(0.15)
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: reached
                ? AppColors.accent.withOpacity(0.4)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: reached ? FontWeight.bold : FontWeight.w500,
                color: reached
                    ? AppColors.accent
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
