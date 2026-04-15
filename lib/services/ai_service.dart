import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // Free API Key from https://console.groq.com/keys
  static const String _apiKey = "MY API Key";

  Future<Map<String, dynamic>?> getSmartRevision(String text) async {
    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

    try {
      final prompt = '''
        You are a Master Academic Professor. Your task is to transform raw study notes into a comprehensive, high-level educational guide.
        
        Notes content: "$text"
        
        Analyze the text deeply and provide a response in the following JSON format:
        {
          "summary": "A comprehensive topic-wise guide. Identify EVERY major sub-topic in the notes. For each sub-topic, provide a clear heading (e.g., ## TOPIC NAME) followed by a paragraph explaining the core concepts, theories, and logic in exhaustive detail. Do not be brief; explain as if you are writing a textbook chapter.",
          "keyPoints": ["Extremely detailed takeaway 1 with sub-context", "Extremely detailed takeaway 2 with sub-context", "Ensure every important fact is captured here as a detailed point."],
          "formulas": ["List every single formula found. Format: 'Formula Name: [Formula] - Explanation of variables'"],
          "keywords": ["Technical terms", "Theories", "Historical figures", "Specific jargon"],
          "definitions": ["Concept Name: A detailed academic definition with a use-case or example if possible"]
        }
      ''';

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You are a specialized academic summarizer. You convert messy notes into structured, exhaustive, topic-by-topic educational guides. You always output valid JSON."
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
          "response_format": {"type": "json_object"},
          "temperature": 0.5 // Higher temperature for more expressive, detailed explanations
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String? responseText = data['choices']?[0]['message']?['content'];
        
        if (responseText != null) {
          return jsonDecode(responseText) as Map<String, dynamic>;
        }
      } else {
        print("Groq API Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("AI Service (Groq) Error: $e");
    }
    
    return null;
  }
}
