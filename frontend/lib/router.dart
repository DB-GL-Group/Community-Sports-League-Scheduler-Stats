import 'package:http/http.dart' as http;
import 'dart:convert'; // Pour jsonDecode


typedef SessionExpiredCallback = Future<void> Function();


class ApiRouter {
  ApiRouter({String? baseUrl, this.onSessionExpired})
      : baseUrl = baseUrl ?? "";

  String baseUrl;
  final SessionExpiredCallback? onSessionExpired;
  static bool _sessionDialogOpen = false;

  String getBaseUrl() => baseUrl;

  void setBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    baseUrl = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  Future<dynamic> fetchData(String endpoint, {String method = 'GET', Map<String, dynamic> body = const {}, String token = ''}) async {
    final headers = <String, String>{
      "Content-Type": "application/json",
      if (token.isNotEmpty) "Authorization": "Bearer $token",
    };
    final response = switch (method) {
      'GET' => await http.get(Uri.parse('$baseUrl/$endpoint'), headers: headers),
      'POST' => await http.post(Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: json.encode(body)
      ),
      'PUT' => await http.put(Uri.parse('$baseUrl/$endpoint'),
        headers: headers,
        body: json.encode(body)
      ),
      'DELETE' => await http.delete(Uri.parse('$baseUrl/$endpoint'), headers: headers),
      String() => throw UnimplementedError(),
    };
    print("statusCode: ${response.statusCode}");
    print("body: ${response.body}");
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return {};
      }
    }
    if (response.statusCode == 401 && response.body.contains('Token expired')) {
      if (onSessionExpired != null && !_sessionDialogOpen) {
        _sessionDialogOpen = true;
        await onSessionExpired!();
        _sessionDialogOpen = false;
      }
    }
    throw Exception('Failed to load data');
  }
}
