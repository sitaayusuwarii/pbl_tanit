import 'package:google_generative_ai/google_generative_ai.dart';
import 'secrets.dart';

class ChatService {
  late final GenerativeModel _model;
  late final ChatSession _chat;

  ChatService() {
    _model = GenerativeModel(
      model: "gemini-1.5-flash",
      apiKey: GEMINI_API_KEY,
    );
    _chat = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    final response = await _chat.sendMessage(
      Content.text(message),
    );

    return response.text ?? "Maaf, tidak ada jawaban.";
  }
}
