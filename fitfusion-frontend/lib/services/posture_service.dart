import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitfusion/services/api_config.dart';

class PostureService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Get auth token from Firebase first, fallback to SharedPreferences
  static Future<String?> _getToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
    } catch (e) {
      debugPrint('Firebase token error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// POST /posture/analyze — multipart form with image + exercise
  static Future<Map<String, dynamic>> analyzePosture({
    required File imageFile,
    required String exercise,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$baseUrl/posture/analyze');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['exercise'] = exercise;

    final ext = imageFile.path.toLowerCase();
    final mimeType = ext.endsWith('.png') ? 'image/png' : 'image/jpeg';

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    try {
      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📸 Posture analyze: ${response.statusCode}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Analysis failed (${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// GET /posture/exercises — list of available exercises
  static Future<List<Map<String, dynamic>>> getExercises() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/posture/exercises');
    final headers = <String, String>{
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('🏋️ Posture exercises: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['exercises'] ?? []);
      }
      throw Exception('Failed to load exercises (${response.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Network error: $e');
    }
  }

  /// POST /posture/realtime/frame — send a single base64 frame for live analysis
  static Future<Map<String, dynamic>> analyzeRealtimeFrame({
    required String imageBase64,
    required String exercise,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');

    final uri = Uri.parse('$baseUrl/posture/realtime/frame');

    final response = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'image': imageBase64,
            'exercise': exercise,
            'timestamp':
                DateTime.now().millisecondsSinceEpoch.toDouble(),
          }),
        )
        .timeout(const Duration(seconds: 4));

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Frame analysis failed: ${response.statusCode}');
  }

  /// GET /posture/realtime/status — health check for the AI service
  static Future<Map<String, dynamic>> checkRealtimeStatus() async {
    final token = await _getToken();
    final uri = Uri.parse('$baseUrl/posture/realtime/status');
    final response = await http.get(
      uri,
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 5));
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
