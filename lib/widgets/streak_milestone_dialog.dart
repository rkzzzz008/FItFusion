import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class StreakMilestoneDialog extends StatefulWidget {
  final int streakDays;
  final VoidCallback onDismiss;

  const StreakMilestoneDialog({
    super.key,
    required this.streakDays,
    required this.onDismiss,
  });

  static Future<void> show(BuildContext context, int streakDays) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StreakMilestoneDialog(
        streakDays: streakDays,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<StreakMilestoneDialog> createState() => _StreakMilestoneDialogState();
}

class _StreakMilestoneDialogState extends State<StreakMilestoneDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String get _milestoneTitle {
    if (widget.streakDays >= 100) return 'Century Legend!';
    if (widget.streakDays >= 30) return 'Monthly Master!';
    if (widget.streakDays >= 7) return 'Week Warrior!';
    return 'Streak Milestone!';
  }

  String get _milestoneBadge {
    if (widget.streakDays >= 100) return '👑';
    if (widget.streakDays >= 30) return '🏆';
    if (widget.streakDays >= 7) return '⚡';
    return '🔥';
  }

  Color get _badgeColor {
    if (widget.streakDays >= 100) return const Color(0xFFF59E0B);
    if (widget.streakDays >= 30) return const Color(0xFF8B5CF6);
    return AppColors.primary;
  }

  String get _milestoneDescription {
    if (widget.streakDays >= 100) {
      return 'Incredible dedication! You have sustained 100 consecutive active days. You are in the top 1% of athletes.';
    }
    if (widget.streakDays >= 30) {
      return '30 consecutive days of pure consistency! Your fitness habits are now fully locked in.';
    }
    if (widget.streakDays >= 7) {
      return '7 days in a row without breaking the chain! That is a full week of continuous progress.';
    }
    return 'You reached a new fitness streak milestone!';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: _badgeColor.withOpacity(0.35),
              width: 1.5,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing Animated Flame Icon & Badge
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _badgeColor.withOpacity(0.2),
                        AppColors.calories.withOpacity(0.2),
                      ],
                    ),
                    border: Border.all(
                      color: _badgeColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _milestoneBadge,
                      style: const TextStyle(fontSize: 44),
                    ),
                  ),
                )
                    .animate()
                    .scale(duration: 500.ms, curve: Curves.easeOutBack)
                    .shimmer(duration: 1200.ms, color: Colors.white24),

                const SizedBox(height: 18),

                // Title
                Text(
                  _milestoneTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                // Streak count pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _badgeColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: AppColors.calories,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${widget.streakDays} DAYS STREAK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: _badgeColor,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(delay: 300.ms, duration: 400.ms),

                const SizedBox(height: 14),

                // Description
                Text(
                  _milestoneDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 24),

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _confettiController.stop();
                      widget.onDismiss();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _badgeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flash_on_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Keep The Fire Burning!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),

        // Confetti Emitter
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 2, // down
          maxBlastForce: 6,
          minBlastForce: 2,
          emissionFrequency: 0.05,
          numberOfParticles: 25,
          gravity: 0.3,
          colors: const [
            Color(0xFF10B981), // Emerald
            Color(0xFFF59E0B), // Amber
            Color(0xFFF97316), // Orange
            Color(0xFF6366F1), // Indigo
            Color(0xFFEC4899), // Pink
          ],
        ),
      ],
    );
  }
}
