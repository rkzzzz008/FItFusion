import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/achievement_model.dart';
import '../providers/achievement_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/achievement_card.dart';
import '../widgets/achievement_progress_ring.dart';
import '../widgets/achievement_unlock_dialog.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  int _selectedFilterIndex = 0; // 0 = All, 1 = Unlocked, 2 = In Progress

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final achievementProv = Provider.of<AchievementProvider>(context);

    // Filter achievements
    List<AchievementModel> displayedList;
    if (_selectedFilterIndex == 1) {
      displayedList = achievementProv.unlockedAchievements;
    } else if (_selectedFilterIndex == 2) {
      displayedList = achievementProv.lockedAchievements;
    } else {
      displayedList = achievementProv.achievements;
    }

    final nextBadge = achievementProv.nextLockedAchievement;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: const Text(
          'Achievements & Badges',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Quick simulation / test unlock action menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Achievement Tools',
            onSelected: (val) {
              if (val == 'test_unlock' && nextBadge != null) {
                achievementProv.testUnlockAchievement(nextBadge.id);
                AchievementUnlockDialog.show(context, nextBadge.copyWith(unlocked: true));
              } else if (val == 'reset') {
                achievementProv.resetAllAchievements();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Achievements reset to initial tracking state')),
                );
              }
            },
            itemBuilder: (context) => [
              if (nextBadge != null)
                PopupMenuItem(
                  value: 'test_unlock',
                  child: Row(
                    children: [
                      const Icon(Icons.flash_on_rounded, color: AppColors.accent, size: 18),
                      const SizedBox(width: 8),
                      Text('Unlock "${nextBadge.title}"'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restart_alt_rounded, color: AppColors.error, size: 18),
                    SizedBox(width: 8),
                    Text('Reset Progress'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Mastery Overview Card with Progress Ring
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E2638), const Color(0xFF151D2A)]
                      : [Colors.white, const Color(0xFFF8FAFC)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.08 : 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Progress Ring
                  AchievementProgressRing(
                    progress: achievementProv.overallProgressPercentage,
                    totalUnlocked: achievementProv.totalUnlocked,
                    totalBadges: achievementProv.totalAchievements,
                    size: 96,
                    strokeWidth: 9,
                  ),
                  const SizedBox(width: 20),

                  // Mastery Stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('👑', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              'Mastery Status',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${achievementProv.totalUnlocked} of ${achievementProv.totalAchievements} Badges',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          achievementProv.totalUnlocked == achievementProv.totalAchievements
                              ? 'Grandmaster! You have unlocked every milestone.'
                              : 'Keep logging workouts and hitting daily goals to unlock legendary trophies!',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 18),

            // Next Milestone Spotlight Card (if any locked)
            if (nextBadge != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent.withOpacity(0.15),
                      ),
                      child: Center(
                        child: Text(nextBadge.icon, style: const TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'NEXT MILESTONE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: AppColors.accent,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${nextBadge.progressPercentage.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nextBadge.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: nextBadge.progress,
                              minHeight: 5,
                              backgroundColor: isDark ? Colors.white12 : Colors.black12,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 18),
            ],

            // Filter Tabs Row
            Row(
              children: [
                _buildFilterChip(
                  label: 'All (${achievementProv.totalAchievements})',
                  index: 0,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Unlocked (${achievementProv.totalUnlocked})',
                  index: 1,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'In Progress (${achievementProv.lockedAchievements.length})',
                  index: 2,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Badges List
            if (displayedList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        _selectedFilterIndex == 1
                            ? 'No badges unlocked yet. Start moving!'
                            : 'All badges completed!',
                        style: TextStyle(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final badge = displayedList[index];
                  return AchievementCard(
                    achievement: badge,
                    onTap: () => AchievementUnlockDialog.show(context, badge),
                  ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: 0.04, end: 0);
                },
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isSelected = _selectedFilterIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFFF59E0B) : const Color(0xFFF59E0B))
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF59E0B)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
