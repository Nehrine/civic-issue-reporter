import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ai/ai_image_analyzer.dart'; // Ensure this matches your file path

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  final TextEditingController _reportController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  
  // Store full address and coordinates
  String? _currentAddress;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  // 1. Get Location & Address
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enable GPS")));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // A. Get Coordinates
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // B. Convert to Address (Reverse Geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Format: "Street, Locality, Postal Code"
        String address = "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}";
        
        if (mounted) {
          setState(() {
            _currentAddress = address;
            // Add to text box nicely if not already there
            if (!_reportController.text.contains("Location:")) {
               _reportController.text += "\n\n📍 Location: $address";
            }
          });
        }
      }
    } catch (e) {
      print("Location Error: $e");
    }
  }

  // 2. Open Google Maps (Updated Logic)
  Future<void> _openMap() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wait for location to be detected..."))
      );
      return;
    }

    // Use the 'geo' scheme which opens the Maps app directly
    final Uri mapUri = Uri.parse("geo:$_latitude,$_longitude?q=$_latitude,$_longitude");

    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri);
      } else {
        // Fallback to web link if app isn't installed
        final Uri webUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$_latitude,$_longitude");
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print("Map Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open Maps")));
      }
    }
  }

  // 3. Pick Image Function
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _reportController.text = "Loading AI analysis...";
        _isAnalyzing = true;
      });
      // Start both tasks
      await _analyzeImage();
      await _getCurrentLocation(); 
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    try {
      final result = await _geminiService.analyzeImage(_selectedImage!);
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        if (result != null) {
          _reportController.text = result;
        } else {
           _reportController.text = "Could not identify issue. Please type manually.";
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _reportController.text = "Error connecting to AI. Check Internet.";
      });
    }
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
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic to disable button if AI is running OR box is empty
    bool canSubmit = !_isAnalyzing && _reportController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showPicker(context),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: _selectedImage == null
                    ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                        Text('Tap to add photo'),
                      ])
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            if (_isAnalyzing) const LinearProgressIndicator(),
            
            const SizedBox(height: 16),

            // Location Display & Button
            if (_currentAddress != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_currentAddress!, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
                      onPressed: _openMap, // OPENS GOOGLE MAPS
                      tooltip: "View on Map",
                    )
                  ],
                ),
              ),

            TextField(
              controller: _reportController,
              decoration: const InputDecoration(labelText: 'Issue Description', border: OutlineInputBorder()),
              maxLines: 6,
              // Update state when text changes to enable/disable button
              onChanged: (text) {
                setState(() {}); 
              },
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // Conditional Color: Purple if ready, Grey if not
                  backgroundColor: canSubmit ? Colors.deepPurple : Colors.grey, 
                  foregroundColor: Colors.white
                ),
                // Disable button (null) if not ready
                onPressed: canSubmit ? () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report Submitted!')));
                    Navigator.pop(context);
                } : null, 
                child: Text(_isAnalyzing ? 'Analyzing...' : 'Submit Issue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}