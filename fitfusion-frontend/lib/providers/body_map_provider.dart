import 'package:flutter/material.dart';

class BodyMapProvider extends ChangeNotifier {
  bool _isFrontView = true;

  bool get isFrontView => _isFrontView;

  void toggleView() {
    _isFrontView = !_isFrontView;
    notifyListeners();
  }
}
