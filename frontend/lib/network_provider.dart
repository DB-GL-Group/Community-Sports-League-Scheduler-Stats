import 'package:flutter/material.dart';

import 'router.dart';

class NetworkProvider extends ChangeNotifier {
  bool _isConnected = false;
  bool _isChecking = false;
  String _baseUrl = '';
  String? _error;

  bool get isConnected => _isConnected;
  bool get isChecking => _isChecking;
  String get baseUrl => _baseUrl;
  String? get error => _error;

  void setConnectedBaseUrl(String url) {
    _baseUrl = url.trim();
    _isConnected = _baseUrl.isNotEmpty;
    _error = null;
    notifyListeners();
  }

  void setBaseUrl(String url) {
    _baseUrl = url.trim();
    _isConnected = false;
    _error = null;
    notifyListeners();
  }

  Future<bool> connect(ApiRouter apiRouter, String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      _error = 'Address is required';
      _isConnected = false;
      notifyListeners();
      return false;
    }

    _isChecking = true;
    _error = null;
    notifyListeners();

    try {
      final hasApi = _hasApiPath(trimmed);
      final looksDirect = _looksDirectBackend(trimmed);
      final primary = hasApi || looksDirect ? trimmed : _appendApi(trimmed);
      final fallback = primary == trimmed ? _appendApi(trimmed) : trimmed;

      if (await _tryConnect(apiRouter, primary)) {
        _isConnected = true;
        _error = null;
        return true;
      }
      if (fallback != primary && await _tryConnect(apiRouter, fallback)) {
        _isConnected = true;
        _error = null;
        return true;
      }

      _isConnected = false;
      _error = 'Unable to reach the backend';
      return false;
    } catch (_) {
      _isConnected = false;
      _error = 'Unable to reach the backend';
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<bool> _tryConnect(ApiRouter apiRouter, String baseUrl) async {
    apiRouter.setBaseUrl(baseUrl);
    _baseUrl = apiRouter.getBaseUrl();
    final response = await apiRouter.fetchData('health');
    return response is Map && response['status'] == 'ok';
  }

  bool _hasApiPath(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url.contains('/api');
    return uri.pathSegments.contains('api');
  }

  bool _looksDirectBackend(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasPort) {
      return uri.port == 8000;
    }
    return url.contains(':8000');
  }

  String _appendApi(String url) {
    final trimmed = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    return '$trimmed/api';
  }
}
