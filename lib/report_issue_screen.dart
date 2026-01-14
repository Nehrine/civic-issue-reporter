import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _submitIssue() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Issue submitted successfully!'),
        ),
      );

      _titleController.clear();
      _descriptionController.clear();
      _locationController.clear();

      setState(() {
        _selectedImage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Issue'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Issue Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // IMAGE PICKER
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: _selectedImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 8),
                                    Text('Tap to add image'),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_selectedImage!.path),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Issue Title',
                          prefixIcon: Icon(Icons.report_problem),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter issue title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please describe the issue';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter location';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _submitIssue,
                icon: const Icon(Icons.send),
                label: const Text('Submit Issue'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

