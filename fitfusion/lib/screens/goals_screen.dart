import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/fitness_provider.dart';
import '../models/user_goals_model.dart';
import '../theme/app_theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  late ConfettiController _confettiController;
  int _steps = 10000;
  int _water = 3000;
  int _workoutMin = 45;
  int _calories = 2400;
  double _sleep = 8.0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final goals = Provider.of<FitnessProvider>(context, listen: false).goals;
      _steps = goals.dailySteps;
      _water = goals.dailyWaterMl;
      _workoutMin = goals.dailyWorkoutMinutes;
      _calories = goals.dailyCalories;
      _sleep = goals.dailySleepHours;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _saveGoals() {
    final fitness = Provider.of<FitnessProvider>(context, listen: false);
    fitness.updateGoals(
      UserGoalsModel(
        dailySteps: _steps,
        dailyWaterMl: _water,
        dailyWorkoutMinutes: _workoutMin,
        dailyCalories: _calories,
        dailySleepHours: _sleep,
      ),
    );
    _confettiController.play();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitness targets updated successfully!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Goals & Targets',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Customize your daily benchmarks to align with your personal fitness journey.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Steps Target
                  _buildSliderCard(
                    isDark: isDark,
                    title: 'Daily Steps',
                    valueDisplay: '$_steps steps',
                    icon: Icons.directions_walk_rounded,
                    color: AppColors.primary,
                    min: 4000,
                    max: 30000,
                    divisions: 26,
                    currentValue: _steps.toDouble(),
                    onChanged: (v) => setState(() => _steps = v.round()),
                  ),
                  const SizedBox(height: 12),

                  // Water Target
                  _buildSliderCard(
                    isDark: isDark,
                    title: 'Daily Hydration',
                    valueDisplay: '$_water ml',
                    icon: Icons.water_drop_rounded,
                    color: AppColors.water,
                    min: 1000,
                    max: 6000,
                    divisions: 20,
                    currentValue: _water.toDouble(),
                    onChanged: (v) => setState(() => _water = v.round()),
                  ),
                  const SizedBox(height: 12),

                  // Workout Minutes Target
                  _buildSliderCard(
                    isDark: isDark,
                    title: 'Active Workout Time',
                    valueDisplay: '$_workoutMin min',
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.secondary,
                    min: 15,
                    max: 120,
                    divisions: 21,
                    currentValue: _workoutMin.toDouble(),
                    onChanged: (v) => setState(() => _workoutMin = v.round()),
                  ),
                  const SizedBox(height: 12),

                  // Calories Target
                  _buildSliderCard(
                    isDark: isDark,
                    title: 'Active Energy Burn',
                    valueDisplay: '$_calories kcal',
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.calories,
                    min: 1200,
                    max: 4500,
                    divisions: 33,
                    currentValue: _calories.toDouble(),
                    onChanged: (v) => setState(() => _calories = v.round()),
                  ),
                  const SizedBox(height: 12),

                  // Sleep Target
                  _buildSliderCard(
                    isDark: isDark,
                    title: 'Restorative Sleep',
                    valueDisplay: '${_sleep.toStringAsFixed(1)} hrs',
                    icon: Icons.bedtime_rounded,
                    color: AppColors.sleep,
                    min: 5.0,
                    max: 10.0,
                    divisions: 10,
                    currentValue: _sleep,
                    onChanged: (v) => setState(() => _sleep = v),
                  ),
                  const SizedBox(height: 24),

                  // Save Goals Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saveGoals,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        'Apply Daily Goals',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Confetti celebratory burst
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                AppColors.accent,
                AppColors.water,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required bool isDark,
    required String title,
    required String valueDisplay,
    required IconData icon,
    required Color color,
    required double min,
    required double max,
    required int divisions,
    required double currentValue,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              const Spacer(),
              Text(
                valueDisplay,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          Slider(
            value: currentValue,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
