import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const String _keyServerUrl = 'api_server_url';
  static const String _keyGeminiKey = 'gemini_api_key';
  static const String _keyPlaylists = 'user_playlists';
  static const String _keySearchHistory = 'search_history';
  static const String _keyRecentPlayed = 'recent_played';
  static const String _keyDownloadedSongs = 'downloaded_songs';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- API Server URL ---
  static String getApiServerUrl() {
    return _prefs?.getString(_keyServerUrl) ??
        'http://music-api.vanhuy2004h.io.vn';
  }

  static Future<void> saveApiServerUrl(String url) async {
    await _prefs?.setString(_keyServerUrl, url);
  }

  // --- Gemini API Key ---
  static String getGeminiApiKey() {
    return _prefs?.getString(_keyGeminiKey) ?? '';
  }

  static Future<void> saveGeminiApiKey(String key) async {
    await _prefs?.setString(_keyGeminiKey, key);
  }

  // --- Search History ---
  static List<String> getSearchHistory() {
    return _prefs?.getStringList(_keySearchHistory) ?? [];
  }

  static Future<void> saveSearchHistory(List<String> history) async {
    await _prefs?.setStringList(_keySearchHistory, history);
  }

  // --- Playlists ---
  // Store playlists as a JSON-encoded list of maps: [{"id": "uuid", "title": "name", "songIds": ["id1", "id2"]}]
  static List<Map<String, dynamic>> getPlaylists() {
    final String? data = _prefs?.getString(_keyPlaylists);
    if (data == null || data.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> savePlaylists(
    List<Map<String, dynamic>> playlists,
  ) async {
    final String encoded = jsonEncode(playlists);
    await _prefs?.setString(_keyPlaylists, encoded);
  }

  // --- Recently Played ---
  // Store recently played songs as JSON objects
  static List<Map<String, dynamic>> getRecentPlayed() {
    final String? data = _prefs?.getString(_keyRecentPlayed);
    if (data == null || data.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveRecentPlayed(List<Map<String, dynamic>> list) async {
    final String encoded = jsonEncode(list);
    await _prefs?.setString(_keyRecentPlayed, encoded);
  }

  // --- Downloaded Songs ---
  static List<Map<String, dynamic>> getDownloadedSongs() {
    final String? data = _prefs?.getString(_keyDownloadedSongs);
    if (data == null || data.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDownloadedSongs(
    List<Map<String, dynamic>> list,
  ) async {
    final String encoded = jsonEncode(list);
    await _prefs?.setString(_keyDownloadedSongs, encoded);
  }

  // --- App Locale ---
  static const String _keyLocale = 'app_locale';
  static String getLocale() {
    return _prefs?.getString(_keyLocale) ?? 'vi';
  }

  static Future<void> saveLocale(String locale) async {
    await _prefs?.setString(_keyLocale, locale);
  }

  // --- Theme Accent Color ---
  static const String _keyAccentColor = 'theme_accent_color';
  static int getAccentColor() {
    return _prefs?.getInt(_keyAccentColor) ??
        0xFF0054FF; // Default to Cobalt Blue
  }

  static Future<void> saveAccentColor(int colorValue) async {
    await _prefs?.setInt(_keyAccentColor, colorValue);
  }

  // --- Lyric Font Size Multiplier ---
  static const String _keyLyricFontSize = 'lyric_font_size_multiplier';
  static double getLyricFontSizeMultiplier() {
    return _prefs?.getDouble(_keyLyricFontSize) ?? 1.0;
  }

  static Future<void> saveLyricFontSizeMultiplier(double multiplier) async {
    await _prefs?.setDouble(_keyLyricFontSize, multiplier);
  }

  // --- Weekly Listening Stats ---
  static const String _keyWeeklyStats = 'weekly_listening_stats';
  static Map<String, int> getWeeklyListeningStats() {
    final String? data = _prefs?.getString(_keyWeeklyStats);
    if (data == null || data.isEmpty) {
      return {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };
    }
    try {
      final Map<String, dynamic> decoded = jsonDecode(data);
      return decoded.map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };
    }
  }

  static Future<void> saveWeeklyListeningStats(Map<String, int> stats) async {
    final String encoded = jsonEncode(stats);
    await _prefs?.setString(_keyWeeklyStats, encoded);
  }

  // --- Crossfade Duration ---
  static const String _keyCrossfadeSeconds = 'crossfade_seconds';
  static int getCrossfadeSeconds() {
    return _prefs?.getInt(_keyCrossfadeSeconds) ?? 0;
  }

  static Future<void> saveCrossfadeSeconds(int seconds) async {
    await _prefs?.setInt(_keyCrossfadeSeconds, seconds);
  }
}
