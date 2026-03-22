import 'package:flutter/foundation.dart';
import 'package:fitfusion/services/api_service.dart';

class WorkoutProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _workoutHistory = [];
  Map<String, dynamic>? _recommendation;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get workoutHistory => _workoutHistory;
  Map<String, dynamic>? get recommendation => _recommendation;

  DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 5);

  Future<void> fetchHistory({bool force = false}) async {
    if (!force && _lastFetch != null && DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return; // Use cached data
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.instance.getWorkoutHistory();
    if (response.success) {
      _workoutHistory = response.data?['history'] ?? [];
      _lastFetch = DateTime.now();
    } else {
      _error = response.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> completeWorkout(String workoutId, int rating) async {
    final response = await ApiService.instance.completeWorkout(workoutId, rating);
    if (response.success) {
      // Force refresh next time history is requested
      _lastFetch = null;
      return true;
    }
    return false;
  }
}
