import 'package:http/http.dart' as http;
import 'dart:convert'; // Pour jsonDecode


class ApiRouter {
  ApiRouter({this.baseUrl = "http://localhost:8000"});

  final String baseUrl;

  Future<dynamic> fetchData(String endpoint, {String method = 'GET', Map<String, dynamic> body = const {}, String token = ''}) async {
    final response = switch (method) {
      'GET' => await http.get(Uri.parse('$baseUrl/$endpoint')),
      'POST' => await http.post(Uri.parse('$baseUrl/$endpoint'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer ${token}"},
        body: json.encode(body)
      ),
      'PUT' => await http.put(Uri.parse('$baseUrl/$endpoint'),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer ${token}"},
        body: json.encode(body)
      ),
      'DELETE' => await http.delete(Uri.parse('$baseUrl/$endpoint')),
      String() => throw UnimplementedError(),
    };
    print("statusCode: ${response.statusCode}");
    print("body: ${response.body}");
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load data');
  }
}
