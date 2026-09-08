import 'package:flutter/material.dart';
import '../models/workout_model.dart';
import '../theme/app_theme.dart';

/// A dialog widget for adding/logging a new workout session.
/// Used in CalendarScreen and WorkoutDayDialog.
class AddWorkoutDialog extends StatefulWidget {
  /// Callback invoked with the created [WorkoutModel] when user saves.
  final void Function(WorkoutModel workout) onAdd;

  const AddWorkoutDialog({super.key, required this.onAdd});

  @override
  State<AddWorkoutDialog> createState() => _AddWorkoutDialogState();
}

class _AddWorkoutDialogState extends State<AddWorkoutDialog> {
  final _titleController = TextEditingController(text: 'Morning Run');
  final _notesController = TextEditingController();
  WorkoutType _type = WorkoutType.running;
  WorkoutIntensity _intensity = WorkoutIntensity.moderate;
  int _duration = 30;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _caloriesEstimate => _duration *
      (_intensity == WorkoutIntensity.high
          ? 11
          : _intensity == WorkoutIntensity.moderate
              ? 8
              : 5);

  void _handleSave() {
    final workout = WorkoutModel(
      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
      type: _type,
      title: _titleController.text.trim().isEmpty
          ? 'Workout Session'
          : _titleController.text.trim(),
      durationMinutes: _duration,
      caloriesBurned: _caloriesEstimate,
      date: DateTime.now(),
      intensity: _intensity,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    widget.onAdd(workout);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Log Workout Session',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Workout Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Activity Name',
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Discipline Type Dropdown
            DropdownButtonFormField<WorkoutType>(
              value: _type,
              decoration: InputDecoration(
                labelText: 'Discipline',
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              dropdownColor: isDark ? AppColors.darkCard : AppColors.lightCard,
              items: WorkoutType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _type = val);
              },
            ),
            const SizedBox(height: 16),

            // Duration Slider
            Text(
              'Duration: $_duration minutes (~$_caloriesEstimate kcal)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            Slider(
              value: _duration.toDouble(),
              min: 5,
              max: 180,
              divisions: 35,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _duration = val.round()),
            ),
            const SizedBox(height: 12),

            // Intensity Selector
            Text(
              'Intensity',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: WorkoutIntensity.values.map((i) {
                final isSelected = _intensity == i;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Center(child: Text(i.name.toUpperCase())),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      onSelected: (_) => setState(() => _intensity = i),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Optional Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'How did it feel?',
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save Workout',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
