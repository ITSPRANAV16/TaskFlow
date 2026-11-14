import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages App Lock, Biometric Authentication, and Secure PIN for SpendMate.
class SecurityService with ChangeNotifier {
  static const String _keyAppLockEnabled = 'spendmate_app_lock_enabled';
  static const String _keyUseBiometrics = 'spendmate_use_biometrics';
  static const String _keyPinHash = 'spendmate_pin_hash';

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isAppLockEnabled = false;
  bool _useBiometrics = true;
  String? _pinHash;
  bool _isAuthenticated = false;
  bool _canCheckBiometrics = false;

  bool get isAppLockEnabled => _isAppLockEnabled;
  bool get useBiometrics => _useBiometrics;
  bool get hasPin => _pinHash != null && _pinHash!.isNotEmpty;
  bool get isAuthenticated => _isAuthenticated;
  bool get canCheckBiometrics => _canCheckBiometrics;

  SecurityService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _isAppLockEnabled = prefs.getBool(_keyAppLockEnabled) ?? false;
    _useBiometrics = prefs.getBool(_keyUseBiometrics) ?? true;
    _pinHash = prefs.getString(_keyPinHash);

    try {
      _canCheckBiometrics = await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('Error checking biometric hardware: $e');
      _canCheckBiometrics = false;
    }

    // If app lock is not enabled, mark as already authenticated
    if (!_isAppLockEnabled) {
      _isAuthenticated = true;
    }
    notifyListeners();
  }

  /// Hash PIN using SHA-256 for secure local storage.
  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  /// Set or update the 4-digit security PIN.
  Future<bool> setPin(String pin) async {
    if (pin.length != 4) return false;
    final prefs = await SharedPreferences.getInstance();
    final hash = _hashPin(pin);
    final saved = await prefs.setString(_keyPinHash, hash);
    if (saved) {
      _pinHash = hash;
      notifyListeners();
    }
    return saved;
  }

  /// Verify entered PIN against stored SHA-256 hash.
  bool verifyPin(String enteredPin) {
    if (_pinHash == null) return false;
    final match = _hashPin(enteredPin) == _pinHash;
    if (match) {
      _isAuthenticated = true;
      notifyListeners();
    }
    return match;
  }

  /// Toggle App Lock ON / OFF.
  Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppLockEnabled, enabled);
    _isAppLockEnabled = enabled;
    if (!enabled) {
      _isAuthenticated = true;
    }
    notifyListeners();
  }

  /// Toggle Biometrics preference.
  Future<void> setUseBiometrics(bool use) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseBiometrics, use);
    _useBiometrics = use;
    notifyListeners();
  }

  /// Trigger biometric authentication (Fingerprint / Face ID).
  Future<bool> authenticateWithBiometrics() async {
    if (!_canCheckBiometrics || !_useBiometrics) return false;
    try {
      final success = await _localAuth.authenticate(
        localizedReason: 'SpendMate आर्थिक सुरक्षिततेसाठी अनलॉक करा',
        biometricOnly: true,
      );
      if (success) {
        _isAuthenticated = true;
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  /// Lock the app (called when app is minimized or manually locked).
  void lockApp() {
    if (_isAppLockEnabled) {
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  /// Force unlock (e.g. during reset or setup).
  void unlock() {
    _isAuthenticated = true;
    notifyListeners();
  }
}
