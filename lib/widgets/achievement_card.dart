import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/achievement_model.dart';
import '../theme/app_theme.dart';
import 'achievement_unlock_dialog.dart';

class AchievementCard extends StatefulWidget {
  final AchievementModel achievement;
  final VoidCallback? onTap;
  final bool isCompact;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
    this.isCompact = false,
  });

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (widget.achievement.unlocked) {
      _shineController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AchievementCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.achievement.unlocked && !_shineController.isAnimating) {
      _shineController.repeat();
    } else if (!widget.achievement.unlocked && _shineController.isAnimating) {
      _shineController.stop();
    }
  }

  @override
  void dispose() {
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
    final isUnlocked = a.unlocked;

    return InkWell(
      onTap: widget.onTap ?? () => AchievementUnlockDialog.show(context, a),
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isUnlocked
              ? (isDark
                  ? const Color(0xFF1E2638)
                  : const Color(0xFFFFFFFF))
              : (isDark
                  ? AppColors.darkCard.withOpacity(0.6)
                  : AppColors.lightCard.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isUnlocked
                ? const Color(0xFFF59E0B).withOpacity(0.5)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isUnlocked ? 1.5 : 1.0,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.2 : 0.12),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: EdgeInsets.all(widget.isCompact ? 14 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Badge Avatar with Hero, Shine, or Grayscale Lock
            _buildBadgeAvatar(isDark, isUnlocked, a),
            const SizedBox(width: 14),

            // Achievement Title, Description & Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title + Status Chip
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          a.title,
                          style: TextStyle(
                            fontSize: widget.isCompact ? 15 : 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isUnlocked
                                ? (isDark ? Colors.white : AppColors.lightTextPrimary)
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (isUnlocked)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check, size: 10, color: Colors.white),
                              SizedBox(width: 3),
                              Text(
                                'UNLOCKED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 10,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${a.progressPercentage.toInt()}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    a.description,
                    style: TextStyle(
                      fontSize: widget.isCompact ? 12 : 13,
                      height: 1.35,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    maxLines: widget.isCompact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Progress Bar & Stats (or Unlock Date)
                  if (!isUnlocked)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              a.progressDisplay,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                            Text(
                              '${a.progressPercentage.toInt()}%',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: a.progress,
                            minHeight: 6,
                            backgroundColor: isDark ? Colors.white10 : Colors.black12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              a.progress > 0.6 ? AppColors.accent : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          a.unlockedDate != null ? 'Unlocked ${a.unlockedDate}' : 'Unlocked',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _tierColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            a.tierName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _tierColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeAvatar(bool isDark, bool isUnlocked, AchievementModel a) {
    final double avatarSize = widget.isCompact ? 52 : 58;

    if (!isUnlocked) {
      // Locked: Grayscale + Blur + Lock Icon
      return Stack(
        alignment: Alignment.center,
        children: [
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0, 0, 0, 0.45, 0,
            ]),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 0.8, sigmaY: 0.8),
              child: Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white10 : Colors.black12,
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.black26,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    a.icon,
                    style: TextStyle(fontSize: avatarSize * 0.45),
                  ),
                ),
              ),
            ),
          ),
          // Centered Lock Icon badge
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.black12,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.lock_rounded,
              size: avatarSize * 0.28,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      );
    }

    // Unlocked: Gold Gradient, Glow Border, Shine Animation, and Hero
    return Hero(
      tag: 'achievement_badge_${a.id}',
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Glow
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),

          // Gold Gradient Circle
          Container(
            width: avatarSize,
            height: avatarSize,
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
                width: 2.2,
              ),
            ),
            child: Center(
              child: Text(
                a.icon,
                style: TextStyle(fontSize: avatarSize * 0.48),
              ),
            ),
          ),

          // Animated Badge Shine Sheen
          AnimatedBuilder(
            animation: _shineController,
            builder: (context, child) {
              return ClipOval(
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-2.5 + (_shineController.value * 5.0), -1.0),
                      end: Alignment(-1.5 + (_shineController.value * 5.0), 1.0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.45),
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
    );
  }
}
