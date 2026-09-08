import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/achievement_model.dart';
import '../theme/app_theme.dart';

class AchievementUnlockDialog extends StatefulWidget {
  final AchievementModel achievement;
  final VoidCallback onDismiss;

  const AchievementUnlockDialog({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  static Future<void> show(BuildContext context, AchievementModel achievement) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AchievementUnlockDialog(
        achievement: achievement,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<AchievementUnlockDialog> createState() => _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _confettiController.play();

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  Color get _tierColor {
    switch (widget.achievement.tier) {
      case 4:
        return const Color(0xFF38BDF8); // Diamond / Cyan
      case 3:
        return const Color(0xFFF59E0B); // Gold / Amber
      case 2:
        return const Color(0xFF94A3B8); // Silver
      case 1:
      default:
        return const Color(0xFFCD7F32); // Bronze
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final a = widget.achievement;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(
              color: Color(0xFFF59E0B),
              width: 2,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Tag: "ACHIEVEMENT UNLOCKED!"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'ACHIEVEMENT UNLOCKED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 20),

                // Animated Glowing Badge with Gold Gradient & Shine
                Hero(
                  tag: 'achievement_badge_${a.id}',
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulsing outer halo glow
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withOpacity(0.45),
                              blurRadius: 28,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                      ),

                      // Gold Border Circle
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [
                              Color(0xFFFFFBEB),
                              Color(0xFFFDE68A),
                              Color(0xFFF59E0B),
                              Color(0xFFB45309),
                            ],
                            stops: [0.0, 0.4, 0.8, 1.0],
                          ),
                          border: Border.all(
                            color: const Color(0xFFFCD34D),
                            width: 3.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            a.icon,
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),
                      ),

                      // Animated Shine Sheen
                      AnimatedBuilder(
                        animation: _shineController,
                        builder: (context, child) {
                          return ClipOval(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment(-2.0 + (_shineController.value * 4.0), -1.0),
                                  end: Alignment(-1.0 + (_shineController.value * 4.0), 1.0),
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withOpacity(0.4),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut)
                    .shimmer(duration: 1500.ms, color: Colors.white38),

                const SizedBox(height: 18),

                // Title
                Text(
                  a.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 6),

                // Tier Pill & Category
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _tierColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _tierColor.withOpacity(0.4)),
                      ),
                      child: Text(
                        '${a.tierName} Badge',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _tierColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        a.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 12),

                // Description
                Text(
                  a.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ).animate().fadeIn(delay: 350.ms),

                if (a.unlockedDate != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Unlocked on ${a.unlockedDate}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 22),

                // Button: "Claim / Keep Crushing It"
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _confettiController.stop();
                      widget.onDismiss();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.emoji_events_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Keep Crushing It!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),

        // Particle Confetti Cannon
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirection: pi / 2, // blast downwards
          maxBlastForce: 6,
          minBlastForce: 2,
          emissionFrequency: 0.06,
          numberOfParticles: 30,
          gravity: 0.35,
          colors: const [
            Color(0xFFF59E0B), // Gold / Amber
            Color(0xFFFCD34D), // Light Gold
            Color(0xFF10B981), // Emerald
            Color(0xFF6366F1), // Indigo
            Color(0xFFEF4444), // Crimson
          ],
        ),
      ],
    );
  }
}
