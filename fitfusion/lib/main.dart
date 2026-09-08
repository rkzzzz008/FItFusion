import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'providers/fitness_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/achievement_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/ai_coach_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/ai_coach_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase Core: Initialized in local/preview fallback mode ($e)');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FitnessProvider()),
        ChangeNotifierProxyProvider<FitnessProvider, AchievementProvider>(
          create: (_) => AchievementProvider(),
          update: (_, fitness, achievements) {
            achievements?.updateFromFitness(fitness);
            return achievements ?? AchievementProvider();
          },
        ),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => AICoachProvider()),
      ],
      child: const FitFusionApp(),
    ),
  );
}

class FitFusionApp extends StatelessWidget {
  const FitFusionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'FitFusion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProv.themeMode,
      routes: {
        '/ai-coach': (context) => const AICoachScreen(),
      },
      home: const RootNavigator(),
    );
  }
}

enum AppFlowState {
  splash,
  onboarding,
  auth,
  main,
}

class RootNavigator extends StatefulWidget {
  const RootNavigator({super.key});

  @override
  State<RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<RootNavigator> {
  AppFlowState _flowState = AppFlowState.splash;

  @override
  Widget build(BuildContext context) {
    switch (_flowState) {
      case AppFlowState.splash:
        return SplashScreen(
          onFinish: () => setState(() => _flowState = AppFlowState.onboarding),
        );
      case AppFlowState.onboarding:
        return OnboardingScreen(
          onFinish: () => setState(() => _flowState = AppFlowState.auth),
        );
      case AppFlowState.auth:
        return AuthScreen(
          onSuccess: () => setState(() => _flowState = AppFlowState.main),
        );
      case AppFlowState.main:
        return MainNavigationShell(
          onLogout: () => setState(() => _flowState = AppFlowState.auth),
        );
    }
  }
}

class MainNavigationShell extends StatefulWidget {
  final VoidCallback onLogout;

  const MainNavigationShell({super.key, required this.onLogout});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onNavigateToActivity: () => setState(() => _currentIndex = 1),
        onNavigateToGoals: () => setState(() => _currentIndex = 3),
        onOpenAddWorkout: () => setState(() => _currentIndex = 1),
      ),
      const ActivityScreen(),
      const ProgressScreen(),
      const GoalsScreen(),
      ProfileScreen(onLogout: widget.onLogout),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AICoachScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text(
          'AI Coach',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        indicatorColor: AppColors.primary.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center, color: AppColors.primary),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag, color: AppColors.primary),
            label: 'Goals',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
