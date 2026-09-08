# FitFusion - Flutter Material 3 Fitness Tracker 🏃‍♂️⚡

FitFusion is an enterprise-grade, portfolio-defining fitness tracking mobile application built with **Flutter**, **Firebase Cloud Firestore & Auth**, **Provider**, **fl_chart**, and **Flutter Animate**.

## 📁 Clean Architecture Directory Structure

```
fitfusion/
├── pubspec.yaml
├── README.md
├── assets/
│   ├── images/
│   └── icons/
└── lib/
    ├── main.dart                      # App entry point with MultiProvider & ThemeMode
    ├── models/
    │   ├── workout_model.dart         # Workout entity with Firestore serialization
    │   ├── user_goals_model.dart      # Daily steps, water, sleep, calories targets
    │   ├── user_profile_model.dart    # User profile, streak count, metrics
    │   └── achievement_model.dart     # Badges, milestones, and reward criteria
    ├── theme/
    │   ├── app_colors.dart            # Material 3 dynamic color scheme (Primary Emerald/Indigo)
    │   ├── app_typography.dart        # Outfit & Plus Jakarta Sans typography
    │   └── app_theme.dart             # Complete Light and Dark ThemeData
    ├── services/
    │   ├── firebase_auth_service.dart # Google & Email Authentication
    │   ├── firestore_service.dart     # Cloud Firestore real-time streams & CRUD
    │   └── local_storage_service.dart # SharedPreferences caching & offline-first sync
    ├── providers/
    │   ├── auth_provider.dart         # Auth state machine & session management
    │   ├── fitness_provider.dart      # Workouts, active minutes, steps, water, streak
    │   ├── goals_provider.dart        # Goal settings, recalculation & confetti trigger
    │   └── theme_provider.dart        # Dark/Light mode toggle with persistence
    ├── screens/
    │   ├── splash_screen.dart         # Animated pulsing logo with gradient backdrop
    │   ├── onboarding_screen.dart     # 3-page interactive onboarding carousel
    │   ├── auth/
    │   │   ├── login_screen.dart      # Google Sign-in & email credentials
    │   │   └── register_screen.dart   # New user registration & target goal setup
    │   ├── home/
    │   │   └── home_screen.dart       # Steps, calorie rings, streak, water tracker
    │   ├── activity/
    │   │   ├── activity_screen.dart   # Workout feed, search, filter chips
    │   │   └── add_workout_modal.dart # Workout logging with duration & intensity
    │   ├── progress/
    │   │   └── progress_screen.dart   # Weekly/Monthly fl_chart graphs, BMI gauge
    │   ├── goals/
    │   │   └── goals_screen.dart      # Interactive sliders, circular rings, celebration
    │   └── profile/
    │       └── profile_screen.dart    # Profile metrics, dark mode, units, export
    ├── widgets/
    │   ├── circular_goal_ring.dart    # Multi-ring concentric goal visualizer
    │   ├── workout_card.dart          # Dismissible swipe-to-delete workout card
    │   ├── stat_pill.dart             # Quick glance stat card with icon & delta
    │   ├── water_intake_widget.dart   # Interactive quick-add water bottle visualizer
    │   └── gradient_button.dart       # Material 3 tactile elevated gradient button
    ├── animations/
    │   ├── pulse_animation.dart       # Heartbeat/flame animation controller
    │   └── confetti_celebration.dart  # Confetti controller for goal milestones
    └── utils/
        ├── bmi_calculator.dart        # BMI formula & health classification category
        └── date_formatter.dart        # Human-readable timestamps and weekly labels
```

## 🚀 How to Run FitFusion on Flutter

1. **Clone or navigate to the project directory:**
   ```bash
   cd fitfusion
   ```
2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configure Firebase:**
   - Run `flutterfire configure` to generate `firebase_options.dart`.
   - Enable **Authentication** (Email/Password + Google Sign-In) in Firebase Console.
   - Enable **Cloud Firestore** and deploy security rules.
4. **Run the application:**
   ```bash
   flutter run
   ```
