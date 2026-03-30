import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const apiKey = "xxxx"; // replace with your API key

  Future<String> summarize(String text) async {
    final response = await http.post(
      Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey"
      ),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": "Summarize this note in a few sentences:\n$text"}
            ]
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("API error: ${response.statusCode} ${response.body}");
    }

    final data = jsonDecode(response.body);
    final candidates = data["candidates"];
    if (candidates == null || candidates.isEmpty) return "No summary available.";

    return candidates[0]["content"]["parts"][0]["text"] ?? "No summary returned.";
  }
}