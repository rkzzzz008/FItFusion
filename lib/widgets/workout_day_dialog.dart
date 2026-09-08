import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/workout_model.dart';
import '../providers/calendar_provider.dart';
import '../providers/fitness_provider.dart';
import '../providers/achievement_provider.dart';
import '../services/calendar_service.dart';
import '../theme/app_theme.dart';
import 'add_workout_dialog.dart';

class WorkoutDayDialog extends StatefulWidget {
  final DateTime date;

  const WorkoutDayDialog({super.key, required this.date});

  static Future<void> show(BuildContext context, DateTime date) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkoutDayDialog(date: date),
    );
  }

  @override
  State<WorkoutDayDialog> createState() => _WorkoutDayDialogState();
}

class _WorkoutDayDialogState extends State<WorkoutDayDialog> {
  late TextEditingController _notesController;
  String? _selectedMood;
  bool _isSavingNote = false;

  final List<String> _availableMoods = [
    '🔥 Beast Mode',
    '⚡ Energetic',
    '😌 Great',
    '💪 Strong',
    '😴 Tired',
    '🧘 Peaceful',
  ];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadInitialData();
  }

  void _loadInitialData() {
    final calendarProv = Provider.of<CalendarProvider>(context, listen: false);
    final fitnessProv = Provider.of<FitnessProvider>(context, listen: false);
    final dayData = calendarProv.getDayData(widget.date, fitnessProv);
    _notesController.text = dayData.notes ?? '';
    _selectedMood = dayData.mood;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotesAndMood() async {
    setState(() => _isSavingNote = true);
    final calendarProv = Provider.of<CalendarProvider>(context, listen: false);
    await calendarProv.updateDayNotesAndMood(
      widget.date,
      notes: _notesController.text.trim(),
      mood: _selectedMood,
    );
    if (mounted) {
      setState(() => _isSavingNote = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Day log updated successfully!'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fitness = Provider.of<FitnessProvider>(context);
    final calendar = Provider.of<CalendarProvider>(context);
    final achievements = Provider.of<AchievementProvider>(context);
    final dayData = calendar.getDayData(widget.date, fitness, achievements);

    final dateFormatted = DateFormat('EEEE, MMMM d, yyyy').format(widget.date);
    final isToday = DateTime.now().year == widget.date.year &&
        DateTime.now().month == widget.date.month &&
        DateTime.now().day == widget.date.day;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row: Date and Status Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              dateFormatted,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppColors.primary, width: 1),
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dayData.hasWorkout
                              ? '${dayData.workouts.length} Workout${dayData.workouts.length > 1 ? 's' : ''} Completed'
                              : (dayData.isGoalAchieved ? 'Active Rest / Goals Met' : 'Rest Day'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: dayData.hasWorkout
                                ? AppColors.primary
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Quick Metric Summary Grid (4 Cards)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildMetricCard(
                    context,
                    isDark,
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFEF4444),
                    title: 'Calories Burned',
                    value: '${dayData.caloriesBurned} kcal',
                  ),
                  _buildMetricCard(
                    context,
                    isDark,
                    icon: Icons.timer_rounded,
                    color: const Color(0xFF3B82F6),
                    title: 'Duration',
                    value: '${dayData.durationMinutes} min',
                  ),
                  _buildMetricCard(
                    context,
                    isDark,
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF06B6D4),
                    title: 'Water Intake',
                    value: '${dayData.waterMl} ml',
                  ),
                  _buildMetricCard(
                    context,
                    isDark,
                    icon: Icons.bedtime_rounded,
                    color: const Color(0xFF8B5CF6),
                    title: 'Sleep Hours',
                    value: '${dayData.sleepHours.toStringAsFixed(1)} hrs',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Distance & Steps Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_run_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${dayData.distanceKm.toStringAsFixed(2)} km Total Distance',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 18, color: isDark ? Colors.white12 : Colors.black12),
                    Row(
                      children: [
                        const Icon(Icons.directions_walk_rounded, size: 18, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Text(
                          '${dayData.steps.toString()} Steps',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section: Workouts List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workouts (${dayData.workouts.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddWorkoutDialog(
                          onAdd: (workout) {
                            // Assign selected calendar day date
                            final adjustedWorkout = workout.copyWith(date: widget.date);
                            fitness.addWorkout(adjustedWorkout);
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Add Workout'),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              if (dayData.workouts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard.withOpacity(0.5) : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('🧘', style: TextStyle(fontSize: 28)),
                      const SizedBox(height: 6),
                      Text(
                        'No workout logged for this day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dayData.workouts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final w = dayData.workouts[index];
                    return _buildWorkoutItem(context, isDark, w, fitness);
                  },
                ),

              const SizedBox(height: 20),

              // Section: Achievements Unlocked That Day
              if (dayData.unlockedAchievements.isNotEmpty) ...[
                Text(
                  'Achievements Unlocked',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: dayData.unlockedAchievements.map((achTitle) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(
                            achTitle,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Section: Daily Mood
              Text(
                'Day Mood',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableMoods.map((mood) {
                  final isChosen = _selectedMood == mood;
                  return ChoiceChip(
                    label: Text(mood),
                    selected: isChosen,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isChosen ? Colors.white : (isDark ? Colors.white70 : AppColors.lightTextPrimary),
                    ),
                    backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                    onSelected: (selected) {
                      setState(() {
                        _selectedMood = selected ? mood : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Section: Daily Notes & Reflection
              Text(
                'Daily Notes & Reflection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'How did your workout feel today? Any personal records or notes...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Save Notes & Mood Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingNote ? null : _saveNotesAndMood,
                  icon: _isSavingNote
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Save Day Notes & Mood', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    bool isDark, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
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
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkoutItem(
    BuildContext context,
    bool isDark,
    WorkoutModel workout,
    FitnessProvider fitness,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${workout.durationMinutes} min • ${workout.caloriesBurned} kcal • ${workout.type.name.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              fitness.deleteWorkout(workout.id);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
            tooltip: 'Remove workout',
          ),
        ],
      ),
    );
  }
}
