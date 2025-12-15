import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class AuthService {
  final String baseUrl = "${ApiConfig.baseUrl}"; // Android emulator

  Future<bool> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      print("Register Success: ${response.body}");
      return true;
    } else {
      print("Register Failed: ${response.body}");
      return false;
    }
  }
}
