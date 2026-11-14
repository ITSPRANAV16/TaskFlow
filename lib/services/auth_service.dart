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

/// Manages native Google Sign-In and Google Drive authorization tokens for SpendMate.
class AuthService with ChangeNotifier {
  static const String _userKey = 'spendmate_auth_user_v1';
  static const String driveScope = 'https://www.googleapis.com/auth/drive.appdata';

  UserProfile? _currentUser;
  GoogleSignInAccount? _googleAccount;
  bool _isLoading = false;
  bool _isGoogleInitialized = false;

  UserProfile? get currentUser => _currentUser;
  GoogleSignInAccount? get googleAccount => _googleAccount;
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

    try {
      await GoogleSignIn.instance.initialize();
      _isGoogleInitialized = true;

      // Try lightweight re-authentication
      final account =
          await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (account != null) {
        _googleAccount = account;
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

  /// Request authorization headers with Google Drive scope.
  Future<Map<String, String>?> getDriveAuthHeaders({bool promptIfNecessary = true}) async {
    if (_googleAccount == null) {
      try {
        _googleAccount =
            await GoogleSignIn.instance.attemptLightweightAuthentication();
      } catch (e) {
        debugPrint('Failed to get cached account: $e');
      }
    }

    if (_googleAccount == null) return null;

    try {
      return await _googleAccount!.authorizationClient.authorizationHeaders(
        [driveScope],
        promptIfNecessary: promptIfNecessary,
      );
    } catch (e) {
      debugPrint('Failed to get Drive authorization headers: $e');
      return null;
    }
  }

  /// Native Google Account Chooser & Sign-in
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
      _googleAccount = account;

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

  /// Sign out from Google Account without deleting any local transaction data
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Sign-out error: $e');
    }
    _currentUser = null;
    _googleAccount = null;
    await _saveUser();
    notifyListeners();
  }
}
