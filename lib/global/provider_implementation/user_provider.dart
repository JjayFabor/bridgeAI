import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Map<String, dynamic>? getLessonFromCache(String topic) {
    return lessonCache[topic];
  }

  Future<void> setLessonInCache(String topic, Map<String, dynamic> lesson) async {
    lessonCache[topic] = lesson;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lessonCache', jsonEncode(lessonCache));
  }

  Future<void> loadLessonCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString('lessonCache');
    if (cacheString != null) {
      lessonCache = Map<String, Map<String, dynamic>>.from(jsonDecode(cacheString));
      notifyListeners();
    }
  }
}
