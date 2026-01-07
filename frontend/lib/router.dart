import 'package:http/http.dart' as http;
import 'dart:convert'; // Pour jsonDecode


class Router {
  Router({this.baseUrl = "http://localhost:8000"});

  final String baseUrl;

  Future<dynamic> fetchData(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load data');
  }
}
