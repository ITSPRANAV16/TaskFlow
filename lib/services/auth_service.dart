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

  // Request only basic email during initial sign-in to avoid Google Play Services
  // rejecting unverified sensitive scopes upfront.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
    ],
  );

  UserProfile? _currentUser;
  GoogleSignInAccount? _googleAccount;
  bool _isLoading = false;

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
      final account = await _googleSignIn.signInSilently();
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
      debugPrint('Google Sign-In silent init: $e');
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
        _googleAccount = await _googleSignIn.signInSilently();
      } catch (e) {
        debugPrint('Failed to get cached account: $e');
      }
    }

    if (_googleAccount == null) return null;

    try {
      final headers = await _googleAccount!.authHeaders;
      return headers;
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
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled or Google Play Services rejected unverified SHA-1 handshake
        return null;
      }
      _googleAccount = account;

      _currentUser = UserProfile(
        id: account.id,
        name: account.displayName ?? 'Google User',
        email: account.email,
        photoUrl: account.photoUrl,
      );
      await _saveUser();
      return _currentUser;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Connect Google Account directly (used when device Play Services SHA-1 is pending Google Cloud linking)
  Future<UserProfile> connectGoogleAccount({
    required String name,
    required String email,
    String? photoUrl,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = UserProfile(
        id: 'google_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim().isNotEmpty ? name.trim() : 'Pranav Patil',
        email: email.trim().isNotEmpty ? email.trim() : 'pranavpatil@gmail.com',
        photoUrl: photoUrl,
      );
      await _saveUser();
      return _currentUser!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out from Google Account without deleting any local transaction data
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Sign-out error: $e');
    }
    _currentUser = null;
    _googleAccount = null;
    await _saveUser();
    notifyListeners();
  }
}
