import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickActionItem {
  final String label;
  final String prompt;
  final String icon;
  final Color accentColor;

  const QuickActionItem({
    required this.label,
    required this.prompt,
    required this.icon,
    required this.accentColor,
  });
}

class QuickPromptCard extends StatelessWidget {
  final Function(String prompt) onSelectPrompt;
  final bool isCompact;

  const QuickPromptCard({
    super.key,
    required this.onSelectPrompt,
    this.isCompact = false,
  });

  static const List<QuickActionItem> quickActions = [
    QuickActionItem(
      label: 'Lose Weight',
      prompt: 'How can I lose weight sustainably with my current stats?',
      icon: '🔥',
      accentColor: Color(0xFFF97316),
    ),
    QuickActionItem(
      label: 'Build Muscle',
      prompt: 'Build a muscle gain plan tailored to my body.',
      icon: '💪',
      accentColor: Color(0xFF6366F1),
    ),
    QuickActionItem(
      label: 'Quick Workout',
      prompt: 'I have only 20 minutes today. Give me an intense session.',
      icon: '⚡',
      accentColor: Color(0xFFEAB308),
    ),
    QuickActionItem(
      label: 'Today\'s Workout',
      prompt: 'Suggest today\'s workout based on my streak and goals.',
      icon: '🎯',
      accentColor: AppColors.primary,
    ),
    QuickActionItem(
      label: 'Nutrition',
      prompt: 'What should I eat after my workout to optimize recovery?',
      icon: '🍎',
      accentColor: Color(0xFF10B981),
    ),
    QuickActionItem(
      label: 'Cardio & Stamina',
      prompt: 'How can I improve my stamina and aerobic capacity?',
      icon: '🏃',
      accentColor: Color(0xFF38BDF8),
    ),
    QuickActionItem(
      label: 'Stretch & Mobility',
      prompt: 'Suggest stretching exercises to relieve tightness and soreness.',
      icon: '🧘',
      accentColor: Color(0xFF8B5CF6),
    ),
    QuickActionItem(
      label: 'Beginner Workout',
      prompt: 'Give me a beginner workout with gentle joint progression.',
      icon: '🌱',
      accentColor: Color(0xFF10B981),
    ),
    QuickActionItem(
      label: 'Motivation',
      prompt: 'Give me motivation to crush my workout today!',
      icon: '👑',
      accentColor: Color(0xFFF59E0B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isCompact) {
      // Horizontal scrollable chip strip for chat screen bottom
      return SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: quickActions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final action = quickActions[index];
            return InkWell(
              onTap: () => onSelectPrompt(action.prompt),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(action.icon, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text(
                      action.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    // Grid or Card presentation for Dashboard or Modal
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'QUICK ASK SUGGESTIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickActions.take(6).map((action) {
            return InkWell(
              onTap: () => onSelectPrompt(action.prompt),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(action.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      action.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
