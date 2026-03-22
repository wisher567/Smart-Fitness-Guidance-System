import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitfusion/services/api_config.dart';
import 'package:fitfusion/services/api_response.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static ApiService get instance => _instance;

  // ── Helper: build auth headers ──
  Future<Map<String, String>> _authHeaders() async {
    String? token;
    try {
      // 1. Try to get a fresh token from Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        token = await user.getIdToken();
      }
    } catch (e) {
      debugPrint("Firebase auth error logic ignored: $e");
    }

    // 2. Fallback to SharedPreferences if Firebase fails or is not initialized
    if (token == null) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('auth_token');
    }

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _log(String method, String url, {int? status, dynamic body, dynamic response}) {
    if (kDebugMode) {
      print('🌐 API [$method] $url');
      if (body != null) print('📦 Body: $body');
      if (status != null) print('🔄 Status: $status');
      if (response != null) print('📥 Response: $response');
    }
  }

  // Generic Request Handler
  Future<ApiResponse<T>> _request<T>(
    String method,
    String endpoint, {
    dynamic body,
    Map<String, String>? queryParams,
    bool isRetry = false,
  }) async {
    try {
      final headers = await _authHeaders();
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      _log(method, uri.toString(), body: body);

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(ApiConfig.timeout);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(ApiConfig.timeout);
          break;
        case 'PATCH':
          response = await http.patch(uri, headers: headers, body: jsonEncode(body)).timeout(ApiConfig.timeout);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(ApiConfig.timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      _log(method, uri.toString(), status: response.statusCode, response: response.body);

      // Handle token expiration & retry
      if (response.statusCode == 401 && !isRetry) {
        // Here you would implement your refresh token logic
        // For now, we will just return the error, but this is the hook for generic retry
        // bool refreshed = await _refreshToken();
        // if(refreshed) return _request(method, endpoint, body: body, queryParams: queryParams, isRetry: true);
        return ApiResponse.error('Unauthorized: Session expired');
      }

      final dynamic data = response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(data as T);
      } else {
        return ApiResponse.error(data is Map && data['error'] != null ? data['error'] : 'Error ${response.statusCode}');
      }
    } catch (e) {
      _log(method, endpoint, response: 'Exception: $e');
      return ApiResponse.error(e.toString());
    }
  }

  // ══════════════════════════════════════
  //  USER PROFILE
  // ══════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> getUserProfile() {
    return _request('GET', '/users/profile');
  }

  Future<ApiResponse<Map<String, dynamic>>> getDailySummary() {
    return _request('GET', '/users/daily-summary');
  }

  Future<ApiResponse<Map<String, dynamic>>> saveUserProfile({
    required String name,
    required int age,
    required double weight,
    required double height,
    required String fitnessGoal,
    required String fitnessLevel,
    String? phone,
  }) {
    return _request('POST', '/users/profile', body: {
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'fitnessGoal': fitnessGoal,
      'fitnessLevel': fitnessLevel,
      if (phone != null) 'phone': phone,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> uploadAvatarBytes(Uint8List bytes, String filename) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/profile/avatar');
      
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..files.add(http.MultipartFile.fromBytes(
          'avatar',
          bytes,
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ));

      final streamedResponse = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.success(data);
      }
      return ApiResponse.error(data['error'] ?? 'Upload failed');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> updateAvatarUrl(String photoUrl) {
    return _request('POST', '/users/profile/avatar', body: {
      'photoUrl': photoUrl,
      if (photoUrl.isEmpty) 'remove': 'true',
    });
  }

  // ══════════════════════════════════════
  //  CHATBOT
  // ══════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> sendChatMessage(String message) {
    // Note: chatbot might need longer timeout
    return _request('POST', '/chatbot/message', body: {'message': message});
  }

  Future<ApiResponse<Map<String, dynamic>>> getChatHistory() {
    return _request('GET', '/chatbot/history');
  }

  Future<ApiResponse<Map<String, dynamic>>> clearChatHistory() {
    return _request('DELETE', '/chatbot/clear');
  }

  // ══════════════════════════════════════
  //  WORKOUTS
  // ══════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> getWorkoutRecommendation() {
    return _request('GET', '/workouts/recommend');
  }

  Future<ApiResponse<Map<String, dynamic>>> getWorkoutHistory() {
    return _request('GET', '/workouts/history');
  }

  Future<ApiResponse<Map<String, dynamic>>> completeWorkout(String workoutId, int rating) {
    return _request('POST', '/workouts/$workoutId/complete', body: {'rating': rating});
  }

  /// Log a completed workout session when no backend workoutId exists.
  Future<ApiResponse<Map<String, dynamic>>> logCompletedWorkout({
    required String exerciseName,
    required String sets,
    required String reps,
    required int caloriesBurned,
    required int durationSeconds,
    int rating = 5,
  }) {
    return _request('POST', '/workouts/log', body: {
      'exerciseName': exerciseName,
      'sets': sets,
      'reps': reps,
      'caloriesBurned': caloriesBurned,
      'durationSeconds': durationSeconds,
      'rating': rating,
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getExerciseInstructions({
    required String exerciseName,
    required String difficulty,
    required int sets,
    required String reps,
  }) {
    return _request('POST', '/workouts/instructions', body: {
      'exerciseName': exerciseName,
      'difficulty': difficulty,
      'sets': sets,
      'reps': reps,
    });
  }

  // ══════════════════════════════════════
  //  NUTRITION & MEALS
  // ══════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> getNutritionPlan() {
    return _request('GET', '/nutrition/plan');
  }
  
  Future<ApiResponse<Map<String, dynamic>>> getLatestNutritionTargets() {
    return _request('GET', '/nutrition/latest');
  }

  Future<ApiResponse<Map<String, dynamic>>> scanMeal(List<int> imageBytes, String filename, String category) async {
    try {
      final headers = await _authHeaders();
      final uri = Uri.parse('${ApiConfig.baseUrl}/meals/scan');
      final request = http.MultipartRequest('POST', uri)
        ..headers.addAll(headers)
        ..fields['category'] = category
        ..files.add(http.MultipartFile.fromBytes(
          'image', 
          imageBytes, 
          filename: filename,
          contentType: MediaType('image', 'jpeg'),
        ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return ApiResponse.success(data);
      return ApiResponse.error(data['error'] ?? 'Scan failed');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> logMeal(String mealId, String category, [String notes = '']) {
    return _request('POST', '/meals/log', body: {'mealId': mealId, 'category': category, 'notes': notes});
  }

  Future<ApiResponse<Map<String, dynamic>>> saveCustomMeal({
    required String name,
    required String category,
    required int calories,
    required int protein,
    required int carbs,
    required int fats,
  }) {
    return _request('POST', '/meals/custom', body: {
      'name': name,
      'category': category.toLowerCase(),
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getDailyMeals() {
    return _request('GET', '/meals/log/today');
  }

  Future<ApiResponse<Map<String, dynamic>>> getWeeklyMealsReport() {
    return _request('GET', '/meals/report/weekly');
  }

  Future<ApiResponse<Map<String, dynamic>>> getMealLibrary({String? category, String? search}) {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;
    return _request('GET', '/meals/library', queryParams: params);
  }

  Future<ApiResponse<Map<String, dynamic>>> toggleMealFavorite(String mealId) {
    return _request('PATCH', '/meals/$mealId/favorite');
  }

  Future<ApiResponse<dynamic>> deleteMeal(String mealId) {
    return _request('DELETE', '/meals/$mealId');
  }

  // ══════════════════════════════════════
  //  LEADERBOARD & ADMIN
  // ══════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> getLeaderboard() {
    return _request('GET', '/leaderboard');
  }
  
  Future<ApiResponse<List<dynamic>>> getClasses() async {
    // Specially typed dynamic to match list response if any
    final resp = await _request<dynamic>('GET', '/admin/classes');
    if (resp.success) {
      if (resp.data is List) {
        return ApiResponse.success(resp.data as List<dynamic>);
      } else if (resp.data is Map && resp.data['classes'] != null) {
        return ApiResponse.success(resp.data['classes']);
      }
      return ApiResponse.success([]);
    }
    return ApiResponse.error(resp.error ?? 'Unknown error');
  }
  
  Future<ApiResponse<Map<String, dynamic>>> checkInClass(String classId) {
    return _request('POST', '/admin/attendance', body: {'classId': classId});
  }

  // ── Hydration ──────────────────────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> logWater(int amount, String type, String icon, {String? note}) {
    return _request('POST', '/hydration/log', body: {
      'amount': amount, 'type': type, 'icon': icon, if (note != null) 'note': note,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getTodayHydration({String? date}) {
    final q = date != null ? '?date=$date' : '';
    return _request('GET', '/hydration/today$q');
  }

  Future<ApiResponse<Map<String, dynamic>>> getWeeklyHydration() {
    return _request('GET', '/hydration/weekly');
  }

  Future<ApiResponse<Map<String, dynamic>>> getHydrationGoal() {
    return _request('GET', '/hydration/goal');
  }

  Future<ApiResponse<Map<String, dynamic>>> setHydrationGoal(int goalMl, bool reminders, int intervalHours) {
    return _request('POST', '/hydration/goal', body: {
      'dailyGoalMl': goalMl, 'reminderEnabled': reminders, 'reminderIntervalHours': intervalHours,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteHydrationLog(String logId) {
    return _request('DELETE', '/hydration/log/$logId');
  }

  // ── Calories ───────────────────────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> getCalorieDashboard() {
    return _request('GET', '/calories/dashboard');
  }

  Future<ApiResponse<Map<String, dynamic>>> getWeeklyCalories() {
    return _request('GET', '/calories/weekly');
  }

  Future<ApiResponse<Map<String, dynamic>>> getCalorieGoals() {
    return _request('GET', '/calories/goals');
  }

  Future<ApiResponse<Map<String, dynamic>>> setCalorieGoals(int calories, int protein, int carbs, int fats) {
    return _request('POST', '/calories/goals', body: {
      'dailyCalories': calories, 'protein': protein, 'carbs': carbs, 'fats': fats,
    });
  }

  // ══════════════════════════════════════
  //  PAYMENTS & SUBSCRIPTIONS
  // ══════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> getPlans() {
    return _request('GET', '/payments/plans');
  }

  Future<ApiResponse<Map<String, dynamic>>> subscribePlan({
    required String planId,
    required Map<String, dynamic> cardDetails,
  }) {
    return _request('POST', '/payments/subscribe', body: {
      'planId': planId,
      'cardDetails': cardDetails,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getSubscription() {
    return _request('GET', '/payments/subscription');
  }

  Future<ApiResponse<Map<String, dynamic>>> getPaymentHistory() {
    return _request('GET', '/payments/history');
  }

  Future<ApiResponse<Map<String, dynamic>>> getPaymentById(String paymentId) {
    return _request('GET', '/payments/history/$paymentId');
  }

  Future<ApiResponse<Map<String, dynamic>>> cancelSubscription() {
    return _request('POST', '/payments/cancel');
  }

  Future<ApiResponse<Map<String, dynamic>>> getSavedCards() {
    return _request('GET', '/payments/cards');
  }

  Future<ApiResponse<Map<String, dynamic>>> addSavedCard(Map<String, dynamic> cardData) {
    return _request('POST', '/payments/cards', body: cardData);
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteSavedCard(String cardId) {
    return _request('DELETE', '/payments/cards/$cardId');
  }

  // ══════════════════════════════════════
  //  EQUIPMENT ALERTS
  // ══════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> submitEquipmentAlert(Map<String, dynamic> data) {
    return _request('POST', '/admin/alerts', body: data);
  }

  Future<ApiResponse<Map<String, dynamic>>> getMyEquipmentAlerts() {
    return _request('GET', '/admin/alerts/my');
  }

  // ══════════════════════════════════════
  //  TRAINER PORTAL
  // ══════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> getTrainerDashboard() {
    return _request('GET', '/trainer/dashboard');
  }

  Future<ApiResponse<Map<String, dynamic>>> getTrainerClients() {
    return _request('GET', '/trainer/clients');
  }

  Future<ApiResponse<Map<String, dynamic>>> getTrainerClientDetail(String uid) {
    return _request('GET', '/trainer/clients/$uid');
  }

  Future<ApiResponse<Map<String, dynamic>>> getTrainerClasses() {
    return _request('GET', '/trainer/classes');
  }

  Future<ApiResponse<Map<String, dynamic>>> getTrainerPlans() {
    return _request('GET', '/trainer/plans');
  }

  Future<ApiResponse<Map<String, dynamic>>> createTrainerPlan(Map<String, dynamic> data) {
    return _request('POST', '/trainer/plans', body: data);
  }

  Future<ApiResponse<Map<String, dynamic>>> getTrainerChatClients() {
    return _request('GET', '/trainer/chat/clients');
  }

  Future<ApiResponse<Map<String, dynamic>>> getTrainerChatHistory(String uid) {
    return _request('GET', '/trainer/chat/$uid');
  }

  Future<ApiResponse<Map<String, dynamic>>> sendTrainerMessage(String uid, String text) {
    return _request('POST', '/trainer/chat/$uid', body: {'text': text});
  }

  Future<ApiResponse<Map<String, dynamic>>> updateTrainerProfile(Map<String, dynamic> data) {
    return _request('PATCH', '/trainer/profile', body: data);
  }

  // ══════════════════════════════════════
  //  CLASSES & ENROLLMENT
  // ══════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> getUpcomingClasses() {
    return _request('GET', '/admin/classes/all');
  }

  Future<ApiResponse<Map<String, dynamic>>> enrollInClass(String classId) {
    return _request('POST', '/admin/classes/$classId/enroll', body: {});
  }

  Future<ApiResponse<Map<String, dynamic>>> cancelEnrollment(String classId) {
    return _request('DELETE', '/admin/classes/$classId/enroll');
  }

  // ══════════════════════════════════════
  //  TRAINER REQUESTS
  // ══════════════════════════════════════

  Future<ApiResponse<Map<String, dynamic>>> getTrainers() {
    return _request('GET', '/admin/trainers');
  }

  Future<ApiResponse<Map<String, dynamic>>> createTrainerRequest(String trainerId, String message, {String? preferredDate, String? preferredTime}) {
    return _request('POST', '/admin/trainer-requests', body: {
      'trainerId': trainerId,
      'message': message,
      if (preferredDate != null) 'preferredDate': preferredDate,
      if (preferredTime != null) 'preferredTime': preferredTime,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> getMyTrainerRequests() {
    return _request('GET', '/admin/trainer-requests/my');
  }

  // =======================
  // Contact Admin Endpoints
  // =======================

  Future<ApiResponse<Map<String, dynamic>>> getMyContactMessages() async {
    return _request('GET', '/users/my-messages');
  }

  Future<ApiResponse<Map<String, dynamic>>> sendContactAdminMessage(String subject, String message, String category) async {
    return _request('POST', '/users/contact-admin', 
      body: {
        'subject': subject,
        'message': message,
        'category': category,
      }
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> replyToAdminMessage(String messageId, String reply) {
    return _request('POST', '/users/messages/$messageId/reply', body: {
      'reply': reply,
    });
  }
}

