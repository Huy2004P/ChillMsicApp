import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  static String? _cachedWorkingModel;
  static String? _cachedWorkingVersion;

  /// Dynamic discovery of available models supported by this API key.
  /// Queries both v1beta and v1 endpoints to list all models.
  static Future<List<Map<String, String>>> _discoverModels(String apiKey) async {
    final List<String> versions = ['v1beta', 'v1'];
    final List<Map<String, String>> discovered = [];

    for (final version in versions) {
      try {
        final url = Uri.parse('https://generativelanguage.googleapis.com/$version/models?key=$apiKey');
        final response = await http.get(url).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
          final modelsList = data['models'] as List?;
          if (modelsList != null) {
            for (final m in modelsList) {
              if (m is Map) {
                final name = m['name'] as String?; // e.g. "models/gemini-1.5-flash"
                final methods = m['supportedGenerationMethods'] as List?;
                if (name != null && methods != null && methods.contains('generateContent')) {
                  // Clean name: "models/gemini-1.5-flash" -> "gemini-1.5-flash"
                  final cleanName = name.replaceFirst('models/', '');
                  discovered.add({
                    'model': cleanName,
                    'version': version,
                  });
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[GeminiService] Error discovering models for version $version: $e');
      }
    }
    return discovered;
  }

  static Future<String> generateContent({
    required String apiKey,
    required String prompt,
  }) async {
    // Try the cached working model first to save latency
    if (_cachedWorkingModel != null && _cachedWorkingVersion != null) {
      try {
        final text = await _tryModel(apiKey, prompt, _cachedWorkingModel!, _cachedWorkingVersion!);
        if (text != null) return text;
      } catch (_) {
        // Cache stale or model failed, reset and probe again
        _cachedWorkingModel = null;
        _cachedWorkingVersion = null;
      }
    }

    // Attempt dynamic discovery first
    try {
      final List<Map<String, String>> discovered = await _discoverModels(apiKey);
      if (discovered.isNotEmpty) {
        // Sort/prioritize models to try flash/fast/latest models first, avoiding experimental or heavy models unless necessary
        discovered.sort((a, b) {
          final aName = a['model']!.toLowerCase();
          final bName = b['model']!.toLowerCase();
          
          int score(String name) {
            if (name.contains('1.5-flash')) return 1;
            if (name.contains('2.0-flash') || name.contains('2.5-flash')) return 2;
            if (name.contains('flash')) return 3;
            if (name.contains('1.5-pro')) return 4;
            if (name.contains('pro')) return 5;
            return 10; // other/experimental/legacy
          }
          
          return score(aName).compareTo(score(bName));
        });

        debugPrint('[GeminiService] Discovered models: ${discovered.map((e) => "${e['version']}/${e['model']}").toList()}');

        for (final item in discovered) {
          final model = item['model']!;
          final version = item['version']!;
          try {
            debugPrint('[GeminiService] Probing discovered model: $version/$model');
            final text = await _tryModel(apiKey, prompt, model, version);
            if (text != null) {
              // Cache successful config
              _cachedWorkingModel = model;
              _cachedWorkingVersion = version;
              debugPrint('[GeminiService] Dynamic discovery succeeded! Cached: $version/$model');
              return text;
            }
          } catch (e) {
            debugPrint('[GeminiService] Probing failed for $version/$model: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[GeminiService] Dynamic discovery failed: $e');
    }

    // Static fallback list if dynamic discovery returned nothing or failed
    final List<String> models = [
      'gemini-1.5-flash',
      'gemini-1.5-pro',
      'gemini-pro',
      'gemini-2.5-flash',
      'gemini-2.0-flash-exp',
      'gemini-1.0-pro',
    ];
    final List<String> apiVersions = ['v1beta', 'v1'];

    debugPrint('[GeminiService] Falling back to static list probing');
    for (final model in models) {
      for (final version in apiVersions) {
        try {
          debugPrint('[GeminiService] Probing static model: $version/$model');
          final text = await _tryModel(apiKey, prompt, model, version);
          if (text != null) {
            // Cache successful config
            _cachedWorkingModel = model;
            _cachedWorkingVersion = version;
            debugPrint('[GeminiService] Static probing succeeded! Cached: $version/$model');
            return text;
          }
        } catch (_) {}
      }
    }
    throw Exception('Tất cả các mô hình Gemini đều bị lỗi hoặc không hỗ trợ API Key này.');
  }

  static Future<String?> _tryModel(
    String apiKey,
    String prompt,
    String model,
    String version,
  ) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/$version/models/$model:generateContent?key=$apiKey');
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ]
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map?;
        final parts = content?['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          final text = parts[0]['text'] as String?;
          if (text != null && text.isNotEmpty) {
            return text;
          }
        }
      }
    }
    return null;
  }
}
