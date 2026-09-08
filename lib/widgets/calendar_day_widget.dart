import 'package:flutter/material.dart';
import '../services/calendar_service.dart';
import '../theme/app_theme.dart';

class CalendarDayWidget extends StatelessWidget {
  final DateTime date;
  final CalendarDayData dayData;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final VoidCallback onTap;

  const CalendarDayWidget({
    super.key,
    required this.date,
    required this.dayData,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  bool get _isFutureDay {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final dayMidnight = DateTime(date.year, date.month, date.day);
    return dayMidnight.isAfter(todayMidnight);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasWorkout = dayData.hasWorkout;
    final multipleWorkouts = dayData.hasMultipleWorkouts;
    final isStreak = dayData.isStreakDay;
    final isGoalAchieved = dayData.isGoalAchieved;
    final isFuture = _isFutureDay;

    // Visual styles based on activity intensity & state
    BoxDecoration decoration;
    Color textColor;

    if (!isCurrentMonth) {
      // Days from previous/next month
      textColor = isDark ? Colors.white24 : Colors.black26;
      decoration = const BoxDecoration();
    } else if (isFuture) {
      // Future days
      textColor = isDark ? Colors.white38 : Colors.black38;
      decoration = BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
      );
    } else if (isSelected) {
      // Selected day
      textColor = Colors.white;
      decoration = BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      );
    } else if (hasWorkout) {
      textColor = Colors.white;
      if (multipleWorkouts) {
        // Multiple Workouts: High intensity Gold / Amber gradient with glow
        decoration = BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: isToday
              ? Border.all(color: const Color(0xFFFDE68A), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );
      } else {
        // Completed Workout: Emerald gradient
        decoration = BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isGoalAchieved
                ? const [Color(0xFF10B981), Color(0xFF047857)]
                : const [Color(0xFF34D399), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: isToday
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );
      }
    } else if (isToday) {
      // Today without workout logged yet
      textColor = AppColors.primary;
      decoration = BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
      );
    } else if (isGoalAchieved) {
      // Goal Achieved (e.g. steps/water met) without formal workout session
      textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
      decoration = BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.4),
          width: 1.2,
        ),
      );
    } else {
      // Normal past day without workout
      textColor = isDark ? Colors.white70 : AppColors.lightTextPrimary;
      decoration = BoxDecoration(
        color: isDark ? AppColors.darkCard.withOpacity(0.4) : AppColors.lightCard.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder.withOpacity(0.4) : AppColors.lightBorder.withOpacity(0.6),
          width: 1.0,
        ),
      );
    }

    return InkWell(
      onTap: isFuture ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.all(2.5),
        decoration: decoration,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Day Number
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday || isSelected || hasWorkout
                        ? FontWeight.w900
                        : FontWeight.w600,
                    color: textColor,
                  ),
                ),
                // Sub-label / icon indicator
                if (hasWorkout && !isSelected) ...[
                  const SizedBox(height: 2),
                  if (multipleWorkouts)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${dayData.workouts.length}x',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ] else if (isToday && !hasWorkout && !isSelected) ...[
                  const SizedBox(height: 3),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),

            // Top-right badges: Streak Flame or Achievement Star
            if (isStreak && isCurrentMonth && !isFuture && !isSelected)
              Positioned(
                top: 2,
                right: 3,
                child: hasWorkout
                    ? const Text(
                        '🔥',
                        style: TextStyle(fontSize: 9),
                      )
                    : Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
              ),

            // Today badge dot if selected
            if (isToday && isSelected)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
