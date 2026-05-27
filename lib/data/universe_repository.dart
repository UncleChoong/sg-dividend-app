import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sg_dividend/data/models.dart';

class UniverseRepository {
  static const cacheKey = 'sg_dividend.universe_json';
  static const bundledAsset = 'assets/bundled_universe.json';
  static const defaultRemoteUrl = String.fromEnvironment(
    'UNIVERSE_URL',
    defaultValue: 'https://CHANGE_ME.r2.dev/sg_dividend_universe.json',
  );

  final String remoteUrl;
  final Dio _dio;

  UniverseRepository({String? remoteUrl, Dio? dio})
      : remoteUrl = remoteUrl ?? defaultRemoteUrl,
        _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 8),
                                       receiveTimeout: const Duration(seconds: 8)));

  Future<Universe> load() async {
    try {
      final resp = await _dio.get<String>(remoteUrl,
          options: Options(responseType: ResponseType.plain));
      final body = resp.data;
      if (body != null && body.isNotEmpty) {
        final u = Universe.fromJson(jsonDecode(body) as Map<String, dynamic>);
        await _saveCache(body);
        return u;
      }
    } catch (_) {/* fall through */}

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      try {
        return Universe.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {/* fall through */}
    }

    final asset = await rootBundle.loadString(bundledAsset);
    return Universe.fromJson(jsonDecode(asset) as Map<String, dynamic>);
  }

  Future<void> _saveCache(String body) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, body);
  }
}
