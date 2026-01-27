import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _kGeminiApiKey = 'gemini_api_key';

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
}
