import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _apiKey = 'AIzaSyC452LfUkqvtCUms_dJw7jQP_aqx8H7f7E';
  static const String _baseUrl =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  Future<String> sendMessageWithImageAndText({
    required String text,
  }) async {
    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    final body = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": text}
          ]
        }
      ]
    };

    final response = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['candidates'][0]['content']['parts'][0]['text']
          ?? 'Tidak ada jawaban';
    } else {
      throw Exception('Gagal menghubungi AI');
    }
  }
}
