import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/fitness_provider.dart';
import '../providers/achievement_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_day_widget.dart';
import '../widgets/workout_day_dialog.dart';
import '../widgets/monthly_statistics_widget.dart';
import '../widgets/activity_heatmap_widget.dart';
import '../widgets/add_workout_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _activeTab = 0; // 0: Calendar Grid & Stats, 1: Activity Heatmap

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final calendar = Provider.of<CalendarProvider>(context);
    final fitness = Provider.of<FitnessProvider>(context);
    final achievements = Provider.of<AchievementProvider>(context);

    final selectedMonth = calendar.selectedMonth;
    final selectedDate = calendar.selectedDate;
    final monthlyStats = calendar.getMonthlyStats(fitness);
    final heatmapData = calendar.getYearlyHeatmap(fitness, selectedMonth.year);

    final monthTitle = DateFormat('MMMM yyyy').format(selectedMonth);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Calendar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            Text(
              'Visualize activity, streaks & milestones',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          // Jump to Today button
          TextButton.icon(
            onPressed: () {
              final now = DateTime.now();
              calendar.setMonth(now);
              calendar.selectDate(now);
            },
            icon: const Icon(Icons.today_rounded, size: 16),
            label: const Text('Today'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AddWorkoutDialog(
              onAdd: (workout) {
                final adjustedWorkout = workout.copyWith(date: calendar.selectedDate);
                fitness.addWorkout(adjustedWorkout);
              },
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Workout', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented Tab Selector: Calendar View vs Contribution Heatmap
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        title: 'Monthly Calendar',
                        icon: Icons.calendar_month_rounded,
                        isSelected: _activeTab == 0,
                        isDark: isDark,
                        onTap: () => setState(() => _activeTab = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        title: 'Yearly Heatmap',
                        icon: Icons.grid_view_rounded,
                        isSelected: _activeTab == 1,
                        isDark: isDark,
                        onTap: () => setState(() => _activeTab = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (_activeTab == 0) ...[
                // Month Navigation Header Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1E2638), const Color(0xFF151D2A)]
                          : [Colors.white, const Color(0xFFF8FAFC)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Month Selector Row with Animated Arrows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => calendar.previousMonth(),
                            icon: const Icon(Icons.chevron_left_rounded, size: 28),
                            tooltip: 'Previous Month',
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: ScaleTransition(scale: anim, child: child),
                            ),
                            child: Text(
                              monthTitle,
                              key: ValueKey(monthTitle),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => calendar.nextMonth(),
                            icon: const Icon(Icons.chevron_right_rounded, size: 28),
                            tooltip: 'Next Month',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Day-of-week Headers (Mon to Sun)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: const [
                          _WeekdayHeader('M'),
                          _WeekdayHeader('T'),
                          _WeekdayHeader('W'),
                          _WeekdayHeader('T'),
                          _WeekdayHeader('F'),
                          _WeekdayHeader('S'),
                          _WeekdayHeader('S'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
                      const SizedBox(height: 6),

                      // Animated Calendar Grid
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: _buildMonthCalendarGrid(
                          key: ValueKey('${selectedMonth.year}-${selectedMonth.month}'),
                          context: context,
                          month: selectedMonth,
                          selectedDate: selectedDate,
                          calendar: calendar,
                          fitness: fitness,
                          achievements: achievements,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Selected Day Glance Card
                _buildSelectedDayGlance(
                  context,
                  isDark,
                  selectedDate: selectedDate,
                  calendar: calendar,
                  fitness: fitness,
                  achievements: achievements,
                ),
                const SizedBox(height: 24),

                // Monthly Statistics Widget
                MonthlyStatisticsWidget(
                  stats: monthlyStats,
                  month: selectedMonth,
                ),
              ] else ...[
                // Activity Heatmap View
                ActivityHeatmapWidget(
                  heatmapData: heatmapData,
                  year: selectedMonth.year,
                  onDayTap: (date) {
                    calendar.selectDate(date);
                    WorkoutDayDialog.show(context, date);
                  },
                ),
                const SizedBox(height: 20),

                // Monthly Statistics also visible under heatmap
                MonthlyStatisticsWidget(
                  stats: monthlyStats,
                  month: selectedMonth,
                ),
              ],
              const SizedBox(height: 70), // FAB clearance
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthCalendarGrid({
    required Key key,
    required BuildContext context,
    required DateTime month,
    required DateTime selectedDate,
    required CalendarProvider calendar,
    required FitnessProvider fitness,
    required AchievementProvider achievements,
  }) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    // weekday 1=Mon, 7=Sun
    final leadingEmptyDays = firstDayOfMonth.weekday - 1;

    final now = DateTime.now();

    final totalCells = leadingEmptyDays + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    return GridView.builder(
      key: key,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.05,
      ),
      itemCount: totalRows * 7,
      itemBuilder: (context, index) {
        final dayOffset = index - leadingEmptyDays + 1;
        final isCurrentMonth = dayOffset >= 1 && dayOffset <= daysInMonth;

        DateTime cellDate;
        if (dayOffset < 1) {
          final prevMonthLastDay = DateTime(month.year, month.month, 0);
          cellDate = DateTime(month.year, month.month - 1, prevMonthLastDay.day + dayOffset);
        } else if (dayOffset > daysInMonth) {
          cellDate = DateTime(month.year, month.month + 1, dayOffset - daysInMonth);
        } else {
          cellDate = DateTime(month.year, month.month, dayOffset);
        }

        final isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;
        final isSelected = cellDate.year == selectedDate.year &&
            cellDate.month == selectedDate.month &&
            cellDate.day == selectedDate.day;

        final dayData = calendar.getDayData(cellDate, fitness, achievements);

        return CalendarDayWidget(
          date: cellDate,
          dayData: dayData,
          isCurrentMonth: isCurrentMonth,
          isToday: isToday,
          isSelected: isSelected,
          onTap: () {
            calendar.selectDate(cellDate);
            WorkoutDayDialog.show(context, cellDate);
          },
        );
      },
    );
  }

  Widget _buildSelectedDayGlance(
    BuildContext context,
    bool isDark, {
    required DateTime selectedDate,
    required CalendarProvider calendar,
    required FitnessProvider fitness,
    required AchievementProvider achievements,
  }) {
    final dayData = calendar.getDayData(selectedDate, fitness, achievements);
    final dateStr = DateFormat('EEEE, MMM d').format(selectedDate);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: dayData.hasWorkout
                  ? AppColors.primary.withOpacity(0.2)
                  : (isDark ? Colors.white10 : Colors.black12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              dayData.hasWorkout ? Icons.fitness_center_rounded : Icons.event_note_rounded,
              color: dayData.hasWorkout ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dayData.hasWorkout
                      ? '${dayData.workouts.length} workout(s) • ${dayData.caloriesBurned} kcal • ${dayData.durationMinutes} min'
                      : (dayData.isGoalAchieved ? 'Active rest • Goals met' : 'Rest day • Tap to inspect or log'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              WorkoutDayDialog.show(context, selectedDate);
            },
            icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            tooltip: 'View day details',
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 36,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ),
    );
  }
}
