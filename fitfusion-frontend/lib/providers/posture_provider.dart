import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitfusion/services/posture_service.dart';

class PostureProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _exercises = [];
  String? _selectedExercise;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  String? _error;
  Map<String, dynamic>? _lastResult;
  List<Map<String, dynamic>> _analysisHistory = [];

  // ── Getters ────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get exercises => _exercises;
  String? get selectedExercise => _selectedExercise;
  File? get selectedImage => _selectedImage;
  bool get isLoading => _isLoading;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;
  Map<String, dynamic>? get lastResult => _lastResult;
  List<Map<String, dynamic>> get analysisHistory => _analysisHistory;
  bool get canAnalyze => _selectedExercise != null && _selectedImage != null;

  // ── Load Exercises ─────────────────────────────────────────────────────────
  Future<void> loadExercises() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _exercises = await PostureService.getExercises();
    } catch (e) {
      _error = e.toString();
      debugPrint('PostureProvider loadExercises error: $e');
      // Provide fallback local exercises so UI works even if API is offline
      _exercises = _fallbackExercises();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Selection ──────────────────────────────────────────────────────────────
  void selectExercise(String exercise) {
    _selectedExercise = exercise;
    notifyListeners();
  }

  void setImage(File image) {
    _selectedImage = image;
    notifyListeners();
  }

  void clearImage() {
    _selectedImage = null;
    notifyListeners();
  }

  // ── Analyze ────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> analyze() async {
    if (!canAnalyze) return null;
    _isAnalyzing = true;
    _error = null;
    notifyListeners();
    try {
      final result = await PostureService.analyzePosture(
        imageFile: _selectedImage!,
        exercise: _selectedExercise!,
      );
      _lastResult = result;
      _analysisHistory.insert(0, {
        ...result,
        'analyzedAt': DateTime.now().toIso8601String(),
        'exerciseName': _selectedExercise,
      });
      return result;
    } catch (e) {
      _error = e.toString();
      debugPrint('PostureProvider analyze error: $e');
      return null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  // ── History ────────────────────────────────────────────────────────────────
  Future<void> saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('posture_history', json.encode(_analysisHistory));
    } catch (e) {
      debugPrint('PostureProvider saveHistory error: $e');
    }
  }

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('posture_history');
      if (historyJson != null) {
        _analysisHistory = List<Map<String, dynamic>>.from(
          json.decode(historyJson) as List,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PostureProvider loadHistory error: $e');
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────
  void reset() {
    _selectedExercise = null;
    _selectedImage = null;
    _error = null;
    _lastResult = null;
    notifyListeners();
  }

  // ── Fallback exercises (offline mode) ─────────────────────────────────────
  List<Map<String, dynamic>> _fallbackExercises() {
    return [
      {
        'id': 'squat',
        'name': 'Squat',
        'emoji': '🏋️',
        'description': 'Lower body compound movement',
        'available': true,
      },
      {
        'id': 'pushup',
        'name': 'Push Up',
        'emoji': '💪',
        'description': 'Upper body pushing movement',
        'available': true,
      },
      {
        'id': 'plank',
        'name': 'Plank',
        'emoji': '🧘',
        'description': 'Core stability exercise',
        'available': true,
      },
    ];
  }
}
