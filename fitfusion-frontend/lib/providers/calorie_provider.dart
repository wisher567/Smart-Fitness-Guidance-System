import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fitfusion/services/api_service.dart';

class CalorieProvider extends ChangeNotifier {
  final ApiService _api = ApiService.instance;

  // Goal
  String fitnessGoal = 'weight_loss';

  // Targets (from backend)
  int targetCalories = 2000;
  double targetProtein = 126;
  double targetCarbs   = 225;
  double targetFats    = 56;
  double targetFiber   = 30;

  // Today consumed (from food logs)
  int totalCaloriesConsumed = 0;
  double totalProtein = 0;
  double totalCarbs   = 0;
  double totalFats    = 0;
  double totalFiber   = 0;
  int mealsCount = 0;

  // Today burned (from workouts)
  int totalCaloriesBurned = 0;
  List<Map<String, dynamic>> completedWorkouts = [];

  // Calculated
  int caloriesRemaining = 2000;
  int netCalories = 0;
  int percentComplete = 0;
  String status = 'under';

  // Hydration
  int hydrationMl = 0;
  int hydrationTargetMl = 2500;

  // Weekly
  List<Map<String, dynamic>> weeklyData = [];
  double weeklyAvgCalories = 0;
  String aiInsight = '';

  // UI State
  String selectedRange = 'today';
  void setSelectedRange(String val) {
    selectedRange = val;
    notifyListeners();
  }

  bool isLoading = false;
  bool isRefreshing = false;
  String? error;

  // ── MAIN FETCH (calls single endpoint) ──
  Future<void> fetchTodayData({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      error = null;
      notifyListeners();
    }

    try {
      // Single API call gets everything
      final result = await _api.getDailySummary();

      if (result.success) {
        final Map<String, dynamic> s = result.data?['summary'] ?? {};

        fitnessGoal = s['fitnessGoal'] ?? 'weight_loss';

        // Targets
        targetCalories = s['targetCalories'] ?? 2000;
        targetProtein  = (s['targetProtein'] ?? 126).toDouble();
        targetCarbs    = (s['targetCarbs']   ?? 225).toDouble();
        targetFats     = (s['targetFats']    ?? 56).toDouble();
        targetFiber    = (s['targetFiber']   ?? 30).toDouble();

        // Consumed
        totalCaloriesConsumed = s['totalCaloriesConsumed'] ?? 0;
        totalProtein = (s['totalProtein'] ?? 0).toDouble();
        totalCarbs   = (s['totalCarbs']   ?? 0).toDouble();
        totalFats    = (s['totalFats']    ?? 0).toDouble();
        totalFiber   = (s['totalFiber']   ?? 0).toDouble();
        mealsCount   = s['mealsCount']    ?? 0;

        // Burned
        totalCaloriesBurned = s['totalCaloriesBurned'] ?? 0;
        completedWorkouts   = List<Map<String,dynamic>>.from(
          s['completedWorkouts'] ?? []);

        // Calculated
        caloriesRemaining = s['caloriesRemaining'] ?? 0;
        netCalories       = s['netCalories']       ?? 0;
        percentComplete   = s['percentComplete']   ?? 0;
        status            = s['status']            ?? 'under';
      }

    } catch (e) {
      error = e.toString();
      debugPrint('CalorieProvider fetchTodayData error: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  // ── INSTANT UPDATE after workout (no API call needed) ──
  // Called immediately when user finishes exercise
  // Then fetchTodayData() runs in background to confirm
  void onWorkoutCompleted(int caloriesBurned, String workoutName) {
    totalCaloriesBurned += caloriesBurned;
    completedWorkouts.add({
      'exerciseName': workoutName,
      'caloriesBurned': caloriesBurned,
      'completedAt': DateTime.now().toIso8601String(),
    });

    // Recalculate remaining
    _recalculate();
    notifyListeners();

    // Background sync with backend after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      fetchTodayData(silent: true);
    });
  }

  // ── INSTANT UPDATE after meal logged ──
  // Called immediately when user saves a scanned meal
  void onMealLogged(Map<String, dynamic> nutrition) {
    totalCaloriesConsumed += (nutrition['calories'] ?? 0) as int;
    totalProtein += (nutrition['protein'] ?? 0).toDouble();
    totalCarbs   += (nutrition['carbs']   ?? 0).toDouble();
    totalFats    += (nutrition['fats']    ?? 0).toDouble();
    totalFiber   += (nutrition['fiber']   ?? 0).toDouble();
    mealsCount++;

    _recalculate();
    notifyListeners();

    // Background sync with backend after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      fetchTodayData(silent: true);
    });
  }

  // ── Recalculate derived values ──
  void _recalculate() {
    netCalories = totalCaloriesConsumed - totalCaloriesBurned;

    if (fitnessGoal == 'weight_loss') {
      caloriesRemaining = targetCalories - totalCaloriesConsumed
        + totalCaloriesBurned;
    } else {
      caloriesRemaining = targetCalories - totalCaloriesConsumed;
    }

    if (caloriesRemaining < 0) caloriesRemaining = 0;

    percentComplete = targetCalories > 0
      ? ((totalCaloriesConsumed / targetCalories) * 100).round()
      : 0;
  }

  // ── Weekly data ──
  Future<void> fetchWeeklyData() async {
    try {
      final result = await _api.getWeeklyCalories();
      if (result.success && result.data != null) {
        weeklyData = List<Map<String,dynamic>>.from(
          result.data?['chartData'] ?? []); // Adjust per backend structure
        weeklyAvgCalories =
          (result.data?['stats']?['avgCalories'] ?? 0).toDouble();
        aiInsight = result.data?['insights']?['overall'] ?? '';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Weekly data error: $e');
    }
  }
}
