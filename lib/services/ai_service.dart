import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // Free API Key from https://console.groq.com/keys
  static const String _apiKey = "API_KEY";

  Future<Map<String, dynamic>?> getSmartRevision(String text) async {
    final url = Uri.parse("https://api.groq.com/openai/v1/chat/completions");

    // Safety: Stay within free tier token limits
    String safeText = text;
    if (text.length > 4000) {
      safeText = text.substring(0, 4000) + "... [Text truncated]";
    }

    try {
      final prompt = '''
        You are an Elite Academic Professor. Analyze the provided study notes and return a highly detailed topic-wise structured JSON response.
        
        Notes content: "$safeText"
        
        REQUIREMENTS:
        1. "summary": This MUST be a single STRING. Identify major topics and use "## TOPIC NAME" headings INSIDE the string. Explain each topic in depth.
        2. "keyPoints": List of at least 7 detailed takeaway points.
        3. "formulas": List of formulas with explanations.
        4. "keywords": List of technical terms.
        5. "definitions": List of "Term: Definition" strings.
        6. "shortQuestions": Exactly 10 short-answer questions.
        7. "longQuestions": Exactly 5 in-depth long-answer questions.

        CRITICAL: The "summary" field value must be a STRING, not an object.
        
        JSON STRUCTURE EXAMPLE:
        {
          "summary": "## Topic 1\\nContent here...\\n\\n## Topic 2\\nContent here...",
          "keyPoints": ["..."],
          "formulas": ["..."],
          "keywords": ["..."],
          "definitions": ["..."],
          "shortQuestions": ["..."],
          "longQuestions": ["..."]
        }
      ''';

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": [
            {
              "role": "system",
              "content": "You are a professional academic assistant. You only output valid JSON. You never wrap the 'summary' content in a nested object; it is always a single string."
            },
            {
              "role": "user",
              "content": prompt
            }
          ],
          "response_format": {"type": "json_object"},
          "temperature": 0.2 // Very low temperature for high structure consistency
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
