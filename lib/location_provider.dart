import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_model.dart';

class LocationProvider with ChangeNotifier {
  List<LocationModel> _locations = [];

  List<LocationModel> get locations => _locations;

  void addLocation(LocationModel location) {
    _locations.add(location);
    saveLocations();
    notifyListeners();
  }

  void removeLocation(int index) {
    _locations.removeAt(index);
    saveLocations();
    notifyListeners();
  }

  void updateLocation(int index, LocationModel updatedLocation) {
    if (index >= 0 && index < _locations.length) {
      _locations[index] = updatedLocation;
      saveLocations();
      notifyListeners();
    }
  }

  Future<void> loadLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = prefs.getStringList('locations') ?? [];
    _locations = locationsJson.map((json) => LocationModel.fromMap(Map<String, dynamic>.from(jsonDecode(json)))).toList();
    notifyListeners();
  }

  Future<void> saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final locationsJson = _locations.map((location) => jsonEncode(location.toMap())).toList();
    await prefs.setStringList('locations', locationsJson);
  }
}