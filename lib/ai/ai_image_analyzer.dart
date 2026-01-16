import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  // ⚠️ PASTE YOUR WORKING API KEY HERE
  static const String apiKey = "AIzaSyCLsgVpxDZx23OI-KUzkXPhwF5IlkpVaCs"; 

  // 🚀 THE FAILOVER LIST: It will try these one by one until it works
  final List<String> _modelsToTry = [
    "gemini-1.5-flash-001", // Best
    "gemini-1.5-flash",     // Alternate
    "gemini-pro-vision",    // Old Reliable (Backup)
    "gemini-2.5-flash",
    "gemini-2.5-pro",
    "gemini-2.0-flash-exp",
    "gemini-2.0-flash",
    "gemini-2.0-flash-001",
    "gemini-2.0-flash-exp-image-generation"
  ];

  Future<Map<String, String>> analyzeImage(File imageFile) async {
    final List<int> imageBytes = await imageFile.readAsBytes();
    final String base64Image = base64Encode(imageBytes);

    String lastError = "";

    // 🔄 LOOP THROUGH MODELS
    for (String modelName in _modelsToTry) {
      print("Attempting to connect to: $modelName...");
      
      try {
        final result = await _attemptRequest(modelName, base64Image);
        if (result != null) {
           print("✅ SUCCESS with $modelName!");
           return result; // It worked! Stop trying.
        }
      } catch (e) {
        print("❌ Failed with $modelName: $e");
        lastError = e.toString();
        // Continue to the next model in the list...
      }
    }

    // If all failed
    return {
      "title": "Connection Error", 
      "description": "All AI models failed. Please check your internet or API key.", 
      "letter": "Error: $lastError"
    };
  }

  Future<Map<String, String>?> _attemptRequest(String modelName, String base64Image) async {
    final Uri url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey'
    );

    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text": "Analyze this image for civic issues. Return pure JSON with 3 fields: 'title', 'description', 'letter' (formal complaint letter)."
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image
              }
            }
          ]
        }
      ]
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      String rawText = jsonResponse['candidates']?[0]['content']?['parts']?[0]['text'] ?? "{}";
      rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();

      try {
        final Map<String, dynamic> parsed = jsonDecode(rawText);
        return {
          "title": parsed['title'] ?? "Issue Detected",
          "description": parsed['description'] ?? "No description.",
          "letter": parsed['letter'] ?? "No letter generated."
        };
      } catch (e) {
        // If JSON fails but text exists, return text as description
        return {
          "title": "Issue Detected", 
          "description": rawText, 
          "letter": "Could not format letter automatically."
        };
      }
    } 
    
    // If 404 (Not Found) or 400 (Bad Request), throw error to trigger the next model
    throw "Server Error ${response.statusCode}";
  }
}