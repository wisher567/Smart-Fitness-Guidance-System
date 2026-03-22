import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fitfusion/services/api_service.dart';

class HydrationProvider extends ChangeNotifier {
  final _api = ApiService.instance;

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _todayData;
  Map<String, dynamic>? _weeklyData;
  Map<String, dynamic>? _goal;
  DateTime? _lastFetch;
  Timer? _autoRefresh;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get todayData => _todayData;
  Map<String, dynamic>? get weeklyData => _weeklyData;
  Map<String, dynamic>? get goal => _goal;

  // Computed
  int get totalMl => _todayData?['summary']?['totalMl'] ?? 0;
  int get goalMl => _todayData?['summary']?['goalMl'] ?? _goal?['dailyGoalMl'] ?? 2500;
  double get percent => goalMl > 0 ? (totalMl / goalMl).clamp(0.0, 1.0) : 0.0;
  bool get goalReached => _todayData?['summary']?['goalReached'] == true;
  List<dynamic> get logs => _todayData?['logs'] ?? [];

  void startAutoRefresh() {
    _autoRefresh?.cancel();
    _autoRefresh = Timer.periodic(const Duration(seconds: 30), (_) => loadToday(silent: true));
  }

  void stopAutoRefresh() {
    _autoRefresh?.cancel();
    _autoRefresh = null;
  }

  Future<void> loadToday({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    // Cache: skip if fetched within 30 seconds
    if (silent && _lastFetch != null && DateTime.now().difference(_lastFetch!).inSeconds < 30) return;

    try {
      final resp = await _api.getTodayHydration();
      if (resp.success && resp.data != null) {
        _todayData = resp.data;
        _lastFetch = DateTime.now();
      } else {
        if (!silent) _error = resp.error ?? 'Failed to load hydration data';
      }
    } catch (e) {
      if (!silent) _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadWeekly() async {
    try {
      final resp = await _api.getWeeklyHydration();
      if (resp.success && resp.data != null) {
        _weeklyData = resp.data;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> loadGoal() async {
    try {
      final resp = await _api.getHydrationGoal();
      if (resp.success && resp.data != null) {
        _goal = resp.data?['goal'] is Map ? resp.data!['goal'] as Map<String, dynamic> : resp.data;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> logWater(int amount, String type, String icon, {String? note}) async {
    try {
      final resp = await _api.logWater(amount, type, icon, note: note);
      if (resp.success && resp.data != null) {
        await loadToday(silent: true);
        return resp.data;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deleteLog(String logId) async {
    try {
      final resp = await _api.deleteHydrationLog(logId);
      if (resp.success) {
        await loadToday(silent: true);
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> setGoal(int goalMl, bool reminders, int intervalHours) async {
    try {
      final resp = await _api.setHydrationGoal(goalMl, reminders, intervalHours);
      if (resp.success) {
        await loadGoal();
        await loadToday(silent: true);
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
