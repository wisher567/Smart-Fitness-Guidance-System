import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fitfusion/services/api_service.dart';

class LocationProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Position? _currentPosition;
  List<dynamic> _classes = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get currentPosition => _currentPosition;
  List<dynamic> get classes => _classes;

  DateTime? _lastFetch;
  static const _cacheDuration = Duration(minutes: 5);

  Future<void> fetchClasses({bool force = false}) async {
    if (!force && _lastFetch != null && DateTime.now().difference(_lastFetch!) < _cacheDuration && _classes.isNotEmpty) {
      return;
    }

    _isLoading = true;
    _error = null;
    // Don't notify here to prevent map from jumping unnecessarily while silently refreshing

    final response = await ApiService.instance.getClasses();
    if (response.success) {
      _classes = response.data ?? [];
      _lastFetch = DateTime.now();
    } else {
      _error = response.error;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _error = 'Location services are disabled.';
      notifyListeners();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _error = 'Location permissions are denied';
        notifyListeners();
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _error = 'Location permissions are permanently denied, we cannot request permissions.';
      notifyListeners();
      return;
    } 

    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      _error = null;
    } catch (e) {
      _error = 'Failed to get location: $e';
    }
    
    notifyListeners();
  }
}
