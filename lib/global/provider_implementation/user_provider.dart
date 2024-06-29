import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic>? _profileData;
  Map<String, Map<String, dynamic>> lessonCache = {};

  Map<String, dynamic>? get profileData => _profileData;

  void setProfileData(Map<String, dynamic> data) {
    _profileData = data;
    notifyListeners();
  }

  Map<String, dynamic>? getLessonFromCache(String topic) {
    return lessonCache[topic];
  }

  void setLessonInCache(String topic, Map<String, dynamic> lesson) {
    lessonCache[topic] = lesson;
    notifyListeners();
  }
}
