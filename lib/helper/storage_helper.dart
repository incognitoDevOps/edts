// TODO Implement this library.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static Future<void> saveData(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, jsonEncode(data));
  }

  static Future<List<Map<String, dynamic>>> loadList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
    }
    return [];
  }
}
