import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's display language and one-time onboarding flags.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider() {
    _load();
  }

  String _languageCode = 'en';
  bool _isLoaded = false;
  bool _hasSelectedLanguage = false;

  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);
  bool get isLoaded => _isLoaded;
  bool get hasSelectedLanguage => _hasSelectedLanguage;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('app_language');
      if (saved == 'en' || saved == 'fr') {
        _languageCode = saved!;
        _hasSelectedLanguage = true;
      }
    } catch (_) {}
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (code != 'en' && code != 'fr') return;
    _languageCode = code;
    _hasSelectedLanguage = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', code);
    notifyListeners();
  }
}
