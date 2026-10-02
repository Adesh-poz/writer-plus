import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String keyFontFamily = 'pref_font_family';
  static const String keyFontSize = 'pref_font_size';

  static final _prefs = SharedPreferencesAsync();

  static Future<void> saveFontFamily(String family) async {
    await _prefs.setString(keyFontFamily, family);
  }

  static Future<String?> getFontFamily() async {
    return await _prefs.getString(keyFontFamily);
  }

  static Future<void> clearFontFamily() async {
    await _prefs.remove(keyFontFamily);
  }

  static Future<void> saveFontSize(String size) async {
    await _prefs.setString(keyFontSize, size);
  }

  static Future<String?> getFontSize() async {
    return await _prefs.getString(keyFontSize);
  }

  static Future<void> clearFontSize() async {
    await _prefs.remove(keyFontSize);
  }
}
