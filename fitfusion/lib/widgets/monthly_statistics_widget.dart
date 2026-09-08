import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_provider.dart';
import '../theme/app_theme.dart';

class MonthlyStatisticsWidget extends StatelessWidget {
  final MonthlyStatistics stats;
  final DateTime month;

  const MonthlyStatisticsWidget({
    super.key,
    required this.stats,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthName = DateFormat('MMMM yyyy').format(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title & Completion Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  monthName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${(stats.monthlyCompletionPercent * 100).toStringAsFixed(0)}% Active',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Hero Monthly Highlights Banner (Workouts & Calories)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E2638), const Color(0xFF141D2C)]
                  : [Colors.white, const Color(0xFFF8FAFC)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildBannerColumn(
                  label: 'TOTAL WORKOUTS',
                  value: '${stats.totalWorkouts}',
                  sub: '${stats.workoutMinutes} minutes',
                  color: AppColors.primary,
                  icon: Icons.fitness_center_rounded,
                  isDark: isDark,
                ),
              ),
              Container(width: 1, height: 44, color: isDark ? Colors.white12 : Colors.black12),
              Expanded(
                child: _buildBannerColumn(
                  label: 'CALORIES BURNED',
                  value: '${stats.caloriesBurned}',
                  sub: 'active kcal',
                  color: const Color(0xFFEF4444),
                  icon: Icons.local_fire_department_rounded,
                  isDark: isDark,
                ),
              ),
              Container(width: 1, height: 44, color: isDark ? Colors.white12 : Colors.black12),
              Expanded(
                child: _buildBannerColumn(
                  label: 'TOTAL STEPS',
                  value: _formatNumber(stats.steps),
                  sub: 'recorded steps',
                  color: const Color(0xFF10B981),
                  icon: Icons.directions_walk_rounded,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2x3 Detailed Statistics Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            // Best Streak
            _buildStatCard(
              isDark,
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFF59E0B),
              label: 'Best Streak',
              value: '${stats.bestStreak} Days',
              caption: 'consecutive active days',
            ),
            // Longest Workout
            _buildStatCard(
              isDark,
              icon: Icons.hourglass_top_rounded,
              iconColor: const Color(0xFF6366F1),
              label: 'Longest Workout',
              value: stats.longestWorkout != null
                  ? '${stats.longestWorkout!.durationMinutes} min'
                  : 'N/A',
              caption: stats.longestWorkout?.title ?? 'No session',
            ),
            // Favorite Workout Type
            _buildStatCard(
              isDark,
              icon: Icons.star_rounded,
              iconColor: const Color(0xFFEC4899),
              label: 'Favorite Activity',
              value: stats.favoriteWorkoutType != null
                  ? stats.favoriteWorkoutType!.name.toUpperCase()
                  : 'Varied',
              caption: 'highest frequency',
            ),
            // Most Active Weekday
            _buildStatCard(
              isDark,
              icon: Icons.calendar_view_week_rounded,
              iconColor: const Color(0xFF8B5CF6),
              label: 'Peak Weekday',
              value: stats.mostActiveWeekday,
              caption: 'most frequent training',
            ),
            // Average Water Intake
            _buildStatCard(
              isDark,
              icon: Icons.water_drop_rounded,
              iconColor: const Color(0xFF06B6D4),
              label: 'Avg Water Intake',
              value: '${stats.averageWaterIntake.toInt()} ml',
              caption: 'daily hydration',
            ),
            // Average Sleep
            _buildStatCard(
              isDark,
              icon: Icons.bedtime_rounded,
              iconColor: const Color(0xFF3B82F6),
              label: 'Avg Sleep',
              value: '${stats.averageSleep.toStringAsFixed(1)} hrs',
              caption: 'recovery quality',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBannerColumn({
    required String label,
    required String value,
    required String sub,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
        ),
        Text(
          sub,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    bool isDark, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String caption,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
