import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _profileData;

  Map<String, dynamic>? get profileData => _profileData;

  void setProfileData(Map<String, dynamic> data) {
    _profileData = data;
    notifyListeners();
  }
}
