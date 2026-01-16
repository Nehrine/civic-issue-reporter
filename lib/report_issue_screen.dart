import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai/ai_image_analyzer.dart'; 

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  
  // Text Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _letterController = TextEditingController();
  
  final GeminiService _geminiService = GeminiService();
  String? _currentAddress;

  // 1. Get Location
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";
        });
      }
    } catch (e) {
      print("Location Error: $e");
    }
  }

  // 2. Analyze Image
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isAnalyzing = true;
      });
      await _getCurrentLocation();
      
      // ✅ CORRECT WAY TO HANDLE THE MAP RESULT
      try {
        final Map<String, String> result = await _geminiService.analyzeImage(_selectedImage!);
        
        setState(() {
          _isAnalyzing = false;
          // Unpack the 3 items into their own boxes
          _titleController.text = result['title'] ?? "Issue Detected";
          _descController.text = result['description'] ?? "No description generated.";
          // Add location to the letter automatically
          String letterBody = result['letter'] ?? "";
          _letterController.text = "$letterBody\n\nLocation: ${_currentAddress ?? 'Unknown'}";
        });
      } catch (e) {
        setState(() {
          _isAnalyzing = false;
          _descController.text = "Error analyzing image: $e";
        });
      }
    }
  }

  // 3. Send Email
  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: '', 
      queryParameters: {
        'subject': _titleController.text,
        'body': _letterController.text,
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }

  // 4. Submit to Community
  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('reports').add({
      'userId': user.uid,
      'userEmail': user.email,
      'title': _titleController.text,
      'description': _descController.text,
      'letter': _letterController.text,
      'location': _currentAddress ?? "Unknown",
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Pending',
      'upvotes': 0,
      'flags': 0,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report Published!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Box
            GestureDetector(
              onTap: () => _showPicker(context),
              child: Container(
                height: 180,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                child: _selectedImage == null
                    ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                    : Image.file(_selectedImage!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
            if (_isAnalyzing) const LinearProgressIndicator(),
            
            if (_currentAddress != null) 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text("📍 $_currentAddress", style: const TextStyle(color: Colors.blue)),
              ),

            const SizedBox(height: 10),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Issue Title", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _descController, maxLines: 2, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
            
            const SizedBox(height: 20),
            const Text("Formal Complaint Letter", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            
            TextField(
              controller: _letterController, 
              maxLines: 8, 
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mail, color: Colors.deepPurple),
                  onPressed: _sendEmail,
                  tooltip: "Open in Mail App",
                )
              )
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
              onPressed: _submitReport,
              child: const Text("Submit Report"),
            )
          ],
        ),
      ),
    );
  }

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
        });
  }
}