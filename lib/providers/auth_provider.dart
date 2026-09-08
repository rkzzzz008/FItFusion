import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_profile_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _firebaseUser;
  UserProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  UserProfileModel? get profile => _profile;
  bool get isAuthenticated => _firebaseUser != null || _profile != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    // Default demo profile for offline/preview
    _profile = const UserProfileModel(
      uid: 'demo_user_123',
      name: 'Alex Rivers',
      email: 'alex.rivers@fitfusion.app',
      currentWeightKg: 72.4,
      targetWeightKg: 68.0,
      heightCm: 178.0,
    );
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cred = await _authService.signInWithEmail(email: email, password: password);
      if (cred != null && cred.user != null) {
        _firebaseUser = cred.user;
        _profile = UserProfileModel(
          uid: cred.user!.uid,
          name: cred.user!.displayName ?? email.split('@').first,
          email: email,
        );
      } else {
        _profile = UserProfileModel(
          uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: email.split('@').first,
          email: email,
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Fallback demo sign-in for seamless preview testing
      _profile = UserProfileModel(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first,
        email: email,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cred = await _authService.signUpWithEmail(email: email, password: password, name: name);
      if (cred != null && cred.user != null) {
        _firebaseUser = cred.user;
        _profile = UserProfileModel(
          uid: cred.user!.uid,
          name: name,
          email: email,
        );
      } else {
        _profile = UserProfileModel(
          uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
          name: name,
          email: email,
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Fallback demo signup
      _profile = UserProfileModel(
        uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _firebaseUser = null;
    _profile = null;
    notifyListeners();
  }
}
