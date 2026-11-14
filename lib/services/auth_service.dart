import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        photoUrl: json['photoUrl'] as String?,
      );
}

/// Manages Google Sign-In and User Authentication Profile for SpendMate.
class AuthService with ChangeNotifier {
  static const String _userKey = 'spendmate_auth_user_v1';

  UserProfile? _currentUser;
  bool _isLoading = false;
  bool _isGoogleInitialized = false;

  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        _currentUser = UserProfile.fromJson(jsonDecode(userJson));
        notifyListeners();
      } catch (e) {
        debugPrint('Error restoring user session: $e');
      }
    }

    // Initialize GoogleSignIn 7.x
    try {
      await GoogleSignIn.instance.initialize();
      _isGoogleInitialized = true;

      // Try restoring existing sign-in
      final account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (account != null) {
        _currentUser = UserProfile(
          id: account.id,
          name: account.displayName ?? 'Google User',
          email: account.email,
          photoUrl: account.photoUrl,
        );
        await _saveUser();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Google Sign-In initialization: $e');
    }
  }

  Future<void> _saveUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
    } else {
      await prefs.remove(_userKey);
    }
  }

  /// Sign in with Google Account
  Future<UserProfile?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!_isGoogleInitialized) {
        await GoogleSignIn.instance.initialize();
        _isGoogleInitialized = true;
      }

      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();
      _currentUser = UserProfile(
        id: account.id,
        name: account.displayName ?? 'Google User',
        email: account.email,
        photoUrl: account.photoUrl,
      );
      await _saveUser();
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _currentUser;
  }

  /// Demo / Local Google Account Sign-In (for quick testing or offline setup)
  Future<UserProfile> signInWithCustomAccount({
    required String name,
    required String email,
  }) async {
    _currentUser = UserProfile(
      id: 'local_${email.hashCode}',
      name: name,
      email: email,
      photoUrl: null,
    );
    await _saveUser();
    notifyListeners();
    return _currentUser!;
  }

  /// Sign out from Google Account without deleting any local transaction data
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Sign-out error: $e');
    }
    _currentUser = null;
    await _saveUser();
    notifyListeners();
  }
}
