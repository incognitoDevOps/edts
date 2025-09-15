import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CacheService {
  static const String _cachePrefix = 'cache_';
  static const String _timestampPrefix = 'timestamp_';
  static const Duration _defaultCacheExpiry = Duration(hours: 1);

  static Future<void> cacheData(String key, dynamic data, {Duration? expiry}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_timestampPrefix$key';
    
    await prefs.setString(cacheKey, jsonEncode(data));
    await prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<T?> getCachedData<T>(String key, {Duration? expiry}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix$key';
    final timestampKey = '$_timestampPrefix$key';
    
    final cachedData = prefs.getString(cacheKey);
    final timestamp = prefs.getInt(timestampKey);
    
    if (cachedData == null || timestamp == null) return null;
    
    final cacheExpiry = expiry ?? _defaultCacheExpiry;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    
    if (DateTime.now().difference(cacheTime) > cacheExpiry) {
      await clearCache(key);
      return null;
    }
    
    try {
      return jsonDecode(cachedData) as T;
    } catch (e) {
      await clearCache(key);
      return null;
    }
  }

  static Future<void> clearCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_cachePrefix$key');
    await prefs.remove('$_timestampPrefix$key');
  }

  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (String key in keys) {
      if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  static Future<T?> fetchWithCache<T>(
    String cacheKey,
    Future<T> Function() fetchFunction, {
    Duration? expiry,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cachedData = await getCachedData<T>(cacheKey, expiry: expiry);
      if (cachedData != null) return cachedData;
    }

    if (await isOnline()) {
      try {
        final freshData = await fetchFunction();
        await cacheData(cacheKey, freshData, expiry: expiry);
        return freshData;
      } catch (e) {
        final cachedData = await getCachedData<T>(cacheKey, expiry: Duration(days: 30));
        return cachedData;
      }
    } else {
      final cachedData = await getCachedData<T>(cacheKey, expiry: Duration(days: 30));
      return cachedData;
    }
  }
}