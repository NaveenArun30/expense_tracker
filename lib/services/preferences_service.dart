import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _kGeminiApiKey = 'gemini_api_key';
  static const String _kCurrencyCode = 'currency_code';

  Future<void> saveGeminiApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kGeminiApiKey, apiKey);
  }

  Future<String?> getGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kGeminiApiKey);
  }

  Future<void> clearGeminiApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGeminiApiKey);
  }

  Future<void> saveCurrencyCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrencyCode, code);
  }

  Future<String?> getCurrencyCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCurrencyCode);
  }
}
