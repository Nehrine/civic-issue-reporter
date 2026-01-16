import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'ai/ai_image_analyzer.dart'; // ✅ This is the correct import now

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  final TextEditingController _reportController = TextEditingController();
  final GeminiService _geminiService = GeminiService(); // Now works because we fixed the import

  // 1. Show Choice: Camera or Gallery
  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Photo Gallery'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    );
  }

  // 2. Pick Image & Trigger AI
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _reportController.text = "Loading AI analysis..."; // Temporary text
        _isAnalyzing = true;
      });
      _analyzeImage();
    }
  }

  // 3. The AI Logic
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;

    try {
      final result = await _geminiService.analyzeImage(_selectedImage!);
      
      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
        if (result != null) {
          _reportController.text = result; // ✅ AI Result goes here
        } else {
          _reportController.text = "Could not identify issue. Please type manually.";
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _reportController.text = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Image Tap Area
            GestureDetector(
              onTap: () => _showPicker(context),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Tap to add photo'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Loading Indicator
            if (_isAnalyzing)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(),
              ),

            // AI Text Field
            TextField(
              controller: _reportController, // ✅ Connects to AI
              decoration: const InputDecoration(
                labelText: 'Issue Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report Submitted!')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Submit Issue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}