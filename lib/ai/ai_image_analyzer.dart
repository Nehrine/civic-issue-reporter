import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';

class GeminiService {
  final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: GeminiConfig.apiKey,
  );

  Future<String?> analyzeImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = TextPart(
        "Analyze this image for a civic issue app. Identify the issue (e.g., pothole, garbage). "
        "Return the response in this format:\n"
        "Title: [Short Title]\n"
        "Description: [Brief description]\n"
        "Severity: [High/Medium/Low]\n"
        "Department: [Relevant Department]"
      );

      final imagePart = DataPart('image/jpeg', imageBytes);
      final content = [Content.multi([prompt, imagePart])];

      final response = await _model.generateContent(content);
      return response.text;
    } catch (e) {
      print("Gemini Service Error: $e");
      return null;
    }
  }
}