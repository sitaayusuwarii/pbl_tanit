import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _apiKey = 'ISI_API_KEY_KAMU';

  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$_apiKey';

  Future<String> sendMessageWithImageAndText({
    required String text,
    dynamic image, // sementara abaikan image
  }) async {
    final body = {
      'contents': [
        {
          'parts': [
            {'text': text}
          ]
        }
      ]
    };

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final data = jsonDecode(response.body);

    return data['candidates'][0]['content']['parts'][0]['text'];
  }
}
