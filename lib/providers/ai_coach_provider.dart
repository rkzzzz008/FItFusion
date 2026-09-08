import 'package:flutter/foundation.dart';
import '../models/chat_message_model.dart';
import '../models/user_profile_model.dart';
import '../services/ai_coach_service.dart';
import 'fitness_provider.dart';
import 'achievement_provider.dart';

class AICoachProvider with ChangeNotifier {
  final AICoachService _service = AICoachService();

  final List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  String _dailyTip = "Hydration accelerates fat burn! Aim for 2.5L+ water today.";
  String _todaysRecommendation = "30-min Metabolic HIIT or Upper Body Circuit.";
  bool _isInitialized = false;

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String get dailyTip => _dailyTip;
  String get todaysRecommendation => _todaysRecommendation;
  bool get isInitialized => _isInitialized;

  AICoachProvider() {
    // Initial dummy data will be updated upon first context sync
  }

  void initContext({
    required UserProfileModel? profile,
    required FitnessProvider fitness,
    required AchievementProvider? achievements,
  }) {
    if (_isInitialized && _messages.isNotEmpty) return;

    final context = UserFitnessContext.fromProviders(
      profile: profile,
      fitness: fitness,
      achievements: achievements,
    );

    _dailyTip = _service.getDailyTip(context);
    _todaysRecommendation = _service.getTodaysRecommendation(context);

    if (_messages.isEmpty) {
      _messages.add(_service.generateWelcomeMessage(context));
    }
    _isInitialized = true;
    notifyListeners();
  }

  void refreshTips({
    required UserProfileModel? profile,
    required FitnessProvider fitness,
    required AchievementProvider? achievements,
  }) {
    final context = UserFitnessContext.fromProviders(
      profile: profile,
      fitness: fitness,
      achievements: achievements,
    );
    _dailyTip = _service.getDailyTip(context);
    _todaysRecommendation = _service.getTodaysRecommendation(context);
    notifyListeners();
  }

  Future<void> sendMessage(
    String userText, {
    required UserProfileModel? profile,
    required FitnessProvider fitness,
    required AchievementProvider? achievements,
  }) async {
    final trimmed = userText.trim();
    if (trimmed.isEmpty) return;

    // 1. Add User Message
    final userMsg = ChatMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: trimmed,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    _isTyping = true;
    notifyListeners();

    try {
      // 2. Build live context from providers
      final context = UserFitnessContext.fromProviders(
        profile: profile,
        fitness: fitness,
        achievements: achievements,
      );

      // 3. Process prompt via AI service
      final response = await _service.processPrompt(
        prompt: trimmed,
        context: context,
      );

      // 4. Add AI response message
      final aiMsg = ChatMessageModel(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: response.text,
        sender: MessageSender.ai,
        timestamp: DateTime.now(),
        workoutPlan: response.workoutPlan,
        nutritionPlan: response.nutritionPlan,
      );

      _messages.add(aiMsg);
    } catch (e) {
      _messages.add(
        ChatMessageModel(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          content: "I encountered a brief hiccup. Let's try again! You can ask me about workout suggestions, meal plans, or motivation.",
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  void clearChat({
    required UserProfileModel? profile,
    required FitnessProvider fitness,
    required AchievementProvider? achievements,
  }) {
    _messages.clear();
    final context = UserFitnessContext.fromProviders(
      profile: profile,
      fitness: fitness,
      achievements: achievements,
    );
    _messages.add(_service.generateWelcomeMessage(context));
    notifyListeners();
  }
}
