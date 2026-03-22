import 'package:flutter/foundation.dart';
import 'package:fitfusion/services/api_service.dart';

class NutritionProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  Map<String, dynamic>? _todayMeals;
  Map<String, dynamic>? _weeklyReport;
  Map<String, dynamic>? _nutritionTargets;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get todayMeals => _todayMeals;
  Map<String, dynamic>? get weeklyReport => _weeklyReport;
  Map<String, dynamic>? get nutritionTargets => _nutritionTargets;

  DateTime? _lastFetchToday;
  DateTime? _lastFetchWeekly;
  DateTime? _lastFetchTargets;
  static const _cacheDuration = Duration(minutes: 5);

  Future<void> fetchTodayMeals({bool force = false}) async {
    if (!force && _lastFetchToday != null && DateTime.now().difference(_lastFetchToday!) < _cacheDuration && _todayMeals != null) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.instance.getDailyMeals();
    if (response.success) {
      _todayMeals = response.data;
      _lastFetchToday = DateTime.now();
    } else {
      _error = response.error;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchWeeklyReport({bool force = false}) async {
    if (!force && _lastFetchWeekly != null && DateTime.now().difference(_lastFetchWeekly!) < _cacheDuration && _weeklyReport != null) {
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.instance.getWeeklyMealsReport();
    if (response.success) {
      _weeklyReport = response.data;
      _lastFetchWeekly = DateTime.now();
    } else {
      _error = response.error;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchNutritionTargets({bool force = false}) async {
    if (!force && _lastFetchTargets != null && DateTime.now().difference(_lastFetchTargets!) < _cacheDuration && _nutritionTargets != null) {
      return;
    }
    final response = await ApiService.instance.getLatestNutritionTargets();
    if (response.success) {
      _nutritionTargets = response.data?['plan'];
      _lastFetchTargets = DateTime.now();
      notifyListeners();
    }
  }

  // Helper method used by UI to invalidate cache after adding a meal
  void invalidateCache() {
    _lastFetchToday = null;
    _lastFetchWeekly = null;
    notifyListeners();
  }
}
