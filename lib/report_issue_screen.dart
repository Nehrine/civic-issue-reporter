import 'dart:async'; // Needed for Timeout safety
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for Copy functionality
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
  bool _isSubmitting = false;
  
  // Text Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _letterController = TextEditingController();
  
  final GeminiService _geminiService = GeminiService();
  String? _currentAddress;
  double? _latitude;
  double? _longitude;

  // 1. Get Location (With Permission Checks)
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if GPS is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable GPS Location.')));
      return;
    }

    // Check Permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are permanently denied. Go to Settings.')));
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

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

  // 2. Open Google Maps
  Future<void> _openGoogleMaps() async {
    if (_latitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location not found yet.")));
      return;
    }
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude");
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not launch Maps.")));
      }
    } catch (e) {
      print(e);
    }
  }

  // 3. Analyze Image
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isAnalyzing = true;
      });
      await _getCurrentLocation();
      
      try {
        final Map<String, String> result = await _geminiService.analyzeImage(_selectedImage!);
        setState(() {
          _isAnalyzing = false;
          _titleController.text = result['title'] ?? "Issue Detected";
          _descController.text = result['description'] ?? "No description generated.";
          _recipientController.text = "commissioner@kochi.gov.in"; // Default Email
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

  // 4. Send Email (FIXED: Removes + signs using manual encoding)
  Future<void> _sendEmail() async {
    final String recipient = _recipientController.text.trim();
    final String subject = "Civic Complaint: ${_titleController.text}";
    final String body = _letterController.text;

    // Helper function to force spaces to be %20 instead of +
    String? encodeQueryParameters(Map<String, String> params) {
      return params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
    }

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: recipient, 
      query: encodeQueryParameters(<String, String>{
        'subject': subject,
        'body': body,
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No email app found.")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error launching mail: $e")));
    }
  }

  // 5. Copy Text
  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _letterController.text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Letter copied to clipboard!")));
  }

  // 6. Submit Report (FIXED: 10-Second Timeout)
  Future<void> _submitReport() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a Title!")));
      return;
    }
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not logged in! Please restart app.")));
      return;
    }
    
    setState(() => _isSubmitting = true);

    try {
      // 10-Second Timeout to stop infinite loading
      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user.uid,
        'userEmail': user.email,
        'title': _titleController.text,
        'description': _descController.text,
        'letter': _letterController.text,
        'location': _currentAddress ?? "Unknown",
        'latitude': _latitude, 
        'longitude': _longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Pending',
        'upvotes': 0,
        'flags': 0,
      }).timeout(const Duration(seconds: 10));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report Published Successfully!')));
        Navigator.pop(context);
      }
    } on TimeoutException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Network Timeout: Database connection blocked. Try Mobile Data."),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          )
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
            
            // Location Row
            if (_currentAddress != null) 
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text("$_currentAddress", style: const TextStyle(color: Colors.blue, fontSize: 12))),
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.green),
                      onPressed: _openGoogleMaps,
                      tooltip: "Open in Maps",
                    )
                  ],
                ),
              ),

            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Issue Title", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: _descController, maxLines: 2, decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder())),
            
            const SizedBox(height: 20),
            const Text("Official Complaint Details", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),

            // Recipient Email Field
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: "Authority Email (To:)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.alternate_email)
              ),
            ),
            const SizedBox(height: 10),
            
            // Letter Field
            TextField(
              controller: _letterController, 
              maxLines: 8, 
              decoration: const InputDecoration(
                labelText: "Formal Letter",
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              )
            ),

            // Action Buttons Row
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text("Copy Text"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
                  onPressed: _sendEmail,
                  icon: const Icon(Icons.mail),
                  label: const Text("Send Mail"),
                ),
              ],
            ),

            const SizedBox(height: 20),
            
            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, 
                foregroundColor: Colors.white, 
                padding: const EdgeInsets.all(16)
              ),
              onPressed: _isSubmitting ? null : _submitReport,
              child: _isSubmitting 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text("Submit Report"),
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