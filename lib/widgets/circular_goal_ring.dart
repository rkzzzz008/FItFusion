import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../theme/app_theme.dart';

class CircularGoalRing extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final int percentage;
  final String title;
  final String subtitle;
  final Color ringColor;
  final double radius;

  const CircularGoalRing({
    super.key,
    required this.progress,
    required this.percentage,
    required this.title,
    required this.subtitle,
    this.ringColor = AppColors.primary,
    this.radius = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CircularPercentIndicator(
      radius: radius,
      lineWidth: 12.0,
      animation: true,
      animationDuration: 1200,
      percent: progress.clamp(0.0, 1.0),
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      progressColor: ringColor,
      center: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ringColor,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
