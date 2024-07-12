import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CountryProvider with ChangeNotifier {
  List<String> _countries = [];
  bool _isLoading = true;
  bool _hasError = false;

  List<String> get countries => _countries;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  Future<void> fetchCountries() async {
    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:5000/countries'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _countries = data.cast<String>();
        _isLoading = false;
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      _isLoading = false;
      _hasError = true;
    }
    notifyListeners();
  }
}
