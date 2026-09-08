import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fitness_provider.dart';
import '../../models/workout_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/workout_card.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _searchQuery = '';
  WorkoutType? _selectedTypeFilter;

  void _showAddWorkoutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => const _AddWorkoutBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fitness = Provider.of<FitnessProvider>(context);

    // Filter workouts
    final filteredWorkouts = fitness.workouts.where((w) {
      final matchesSearch = w.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (w.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesType = _selectedTypeFilter == null || w.type == _selectedTypeFilter;
      return matchesSearch && matchesType;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Text(
                    'Workout Feed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddWorkoutDialog(context),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search workouts...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter Chips Carousel
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedTypeFilter == null,
                      selectedColor: AppColors.primary,
                      onSelected: (_) => setState(() => _selectedTypeFilter = null),
                    ),
                  ),
                  ...WorkoutType.values.map((t) {
                    final isSel = _selectedTypeFilter == t;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(t.name.toUpperCase()),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        onSelected: (_) => setState(() => _selectedTypeFilter = isSel ? null : t),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Workout Cards Feed
            Expanded(
              child: filteredWorkouts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                          const SizedBox(height: 12),
                          Text(
                            'No workouts match your criteria',
                            style: TextStyle(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filteredWorkouts.length,
                      itemBuilder: (context, index) {
                        final workout = filteredWorkouts[index];
                        return WorkoutCard(
                          workout: workout,
                          onDelete: () => fitness.deleteWorkout(workout.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWorkoutBottomSheet extends StatefulWidget {
  const _AddWorkoutBottomSheet();

  @override
  State<_AddWorkoutBottomSheet> createState() => _AddWorkoutBottomSheetState();
}

class _AddWorkoutBottomSheetState extends State<_AddWorkoutBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  WorkoutType _type = WorkoutType.running;
  WorkoutIntensity _intensity = WorkoutIntensity.moderate;
  int _duration = 30;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Morning Run');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final caloriesEstimate = (_duration *
        (_intensity == WorkoutIntensity.high
            ? 11
            : _intensity == WorkoutIntensity.moderate
                ? 8
                : 5));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  onPressed: () => Navigator.pop(context),
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
                fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),

            // Discipline Type Dropdown
            DropdownButtonFormField<WorkoutType>(
              value: _type,
              decoration: InputDecoration(
                labelText: 'Discipline',
                filled: true,
                fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: WorkoutType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _type = val);
                }
              },
            ),
            const SizedBox(height: 16),

            // Duration Slider
            Text(
              'Duration: $_duration minutes (~$caloriesEstimate kcal)',
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
              onChanged: (val) {
                setState(() => _duration = val.round());
              },
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
                      onSelected: (_) {
                        setState(() => _intensity = i);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final fitness = Provider.of<FitnessProvider>(context, listen: false);
                  fitness.addWorkout(
                    WorkoutModel(
                      id: 'w_${DateTime.now().millisecondsSinceEpoch}',
                      type: _type,
                      title: _titleController.text.trim().isEmpty
                          ? 'Workout Session'
                          : _titleController.text.trim(),
                      durationMinutes: _duration,
                      caloriesBurned: caloriesEstimate,
                      date: DateTime.now(),
                      intensity: _intensity,
                      notes: _notesController.text.trim(),
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Workout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
