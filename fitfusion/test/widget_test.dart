// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fitfusion/main.dart';
import 'package:fitfusion/providers/theme_provider.dart';
import 'package:fitfusion/providers/auth_provider.dart';
import 'package:fitfusion/providers/fitness_provider.dart';
import 'package:fitfusion/providers/achievement_provider.dart';
import 'package:fitfusion/providers/calendar_provider.dart';
import 'package:fitfusion/providers/ai_coach_provider.dart';

void main() {
  testWidgets('FitFusion smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
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

    // Verify that the app starts
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
