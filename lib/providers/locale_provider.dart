import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_strings.dart';

enum AppLanguage { english, marathi }

/// Manages App Locale (English/Marathi), Guest Mode state, and Onboarding status.
class LocaleProvider with ChangeNotifier {
  static const String _prefLanguageKey = 'spendmate_language_v1';
  static const String _prefGuestKey = 'spendmate_guest_mode_v1';
  static const String _prefOnboardingKey = 'spendmate_onboarding_done_v1';

  AppLanguage _language = AppLanguage.english;
  bool _isGuestMode = false;
  bool _isOnboardingDone = false;

  AppLanguage get language => _language;
  bool get isMarathi => _language == AppLanguage.marathi;
  bool get isGuestMode => _isGuestMode;
  bool get isOnboardingDone => _isOnboardingDone;

  LocaleProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final langStr = prefs.getString(_prefLanguageKey);
    if (langStr == 'mr') {
      _language = AppLanguage.marathi;
    } else {
      _language = AppLanguage.english;
    }

    _isGuestMode = prefs.getBool(_prefGuestKey) ?? false;
    _isOnboardingDone = prefs.getBool(_prefOnboardingKey) ?? false;
    notifyListeners();
  }

  String tr(String key) {
    return AppStrings.get(key, isMarathi: isMarathi);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    if (_language == lang) return;
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefLanguageKey, lang == AppLanguage.marathi ? 'mr' : 'en');
    notifyListeners();
  }

  Future<void> setGuestMode(bool isGuest) async {
    _isGuestMode = isGuest;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefGuestKey, isGuest);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _isOnboardingDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefOnboardingKey, true);
    notifyListeners();
  }
}

