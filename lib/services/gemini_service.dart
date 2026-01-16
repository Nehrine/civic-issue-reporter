import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart'; // Ensure this file exists with your API key

class GeminiService {
  // 1. Initialize the model
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: GeminiConfig.apiKey,
  );

  // 2. The function to call from UI
  Future<String?> analyzeImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      // The Prompt
      final prompt = TextPart(
        "You are an AI assistant for a Civic Issue App. "
        "Analyze this image. If it is a civic issue (pothole, garbage, etc.), describe it. "
        "If it is not a civic issue, say 'Not a civic issue'."
        "Format: Title - Description - Severity (Low/Medium/High)"
      );

      final imagePart = DataPart('image/jpeg', imageBytes);

      final content = [
        Content.multi([prompt, imagePart])
      ];

      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      print("Gemini Error: $e");
      return null;
    }
  }
}