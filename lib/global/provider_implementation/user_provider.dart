import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _profileData;
  Map<String, Map<String, dynamic>> lessonCache = {};

  Map<String, dynamic>? get profileData => _profileData;

  void setProfileData(Map<String, dynamic> profileData) {
    _profileData = profileData;
    notifyListeners();
  }

  void clearProfileData() {
    _profileData = null;
    notifyListeners();
  }
}
