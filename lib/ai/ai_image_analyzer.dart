import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  // ⚠️ YOUR KEY GOES HERE
  static const String apiKey = "AIzaSyBYyQStrybSps6Po5Brggo8_mndKICdROM"; 

  Future<String?> analyzeImage(File imageFile) async {
    final List<int> imageBytes = await imageFile.readAsBytes();
    final String base64Image = base64Encode(imageBytes);

    // 1. Try the most common model name first
    String modelToUse = "gemini-2.5-flash"; 

    try {
      return await _sendRequest(modelToUse, base64Image);
    } catch (e) {
      print("⚠️ Standard model failed. Checking available models...");
      
      // 2. If 404, ASK GOOGLE what models are allowed
      await _printAvailableModels();
      
      return "AI Error: Model not found. Check Debug Console for valid model names.";
    }
  }

  Future<String> _sendRequest(String modelName, String base64Image) async {
    final Uri url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey'
    );

    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {"text": "You are a civic reporter. Identify the issue (e.g. Pothole). Title and 2 sentences."},
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
      return jsonResponse['candidates']?[0]['content']?['parts']?[0]['text'] ?? "No text found";
    } else {
      throw "Error ${response.statusCode}";
    }
  }

  // 🔍 DEBUG TOOL: Lists all models your key can actually use
  Future<void> _printAvailableModels() async {
    final Uri url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'
    );
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("\n✅ === VALID MODELS FOR YOUR KEY ===");
        for (var m in data['models']) {
          // Filter for models that support image generation
          if (m['supportedGenerationMethods'].contains('generateContent')) {
             print("👉 ${m['name'].toString().split('/').last}"); 
          }
        }
        print("==================================\n");
      } else {
        print("❌ Could not list models: ${response.body}");
      }
    } catch (e) {
      print("❌ Connection error listing models: $e");
    }
  }
}