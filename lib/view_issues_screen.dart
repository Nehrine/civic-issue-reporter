import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewIssuesScreen extends StatelessWidget {
  const ViewIssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], 
      appBar: AppBar(title: const Text('Community Reports')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports') // Matches your database collection
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 60, color: Colors.green),
                  SizedBox(height: 10),
                  Text('No issues reported yet!', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          final issues = snapshot.data!.docs;

          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              final data = issue.data() as Map<String, dynamic>;
              final String docId = issue.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Placeholder Image Box
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 40, color: Colors.deepPurple),
                            Text("Image Preview Not Available", style: TextStyle(color: Colors.deepPurple)),
                            Text("(Cloud Storage not configured)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    
                    // 2. Report Details
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  data['title'] ?? 'No Title',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              // Status Chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  data['status'] ?? 'Pending',
                                  style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(data['description'] ?? 'No description provided.'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  data['location'] ?? 'Unknown Location',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // 3. Interactive Buttons (Upvote & Flag)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Upvote
                          TextButton.icon(
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('reports')
                                  .doc(docId)
                                  .update({'upvotes': FieldValue.increment(1)});
                            },
                            icon: const Icon(Icons.thumb_up, color: Colors.blue),
                            label: Text(
                              "Upvote (${data['upvotes'] ?? 0})",
                              style: const TextStyle(color: Colors.blue),
                            ),
                          ),
                          Container(width: 1, height: 24, color: Colors.grey.shade300), // Separator
                          // Flag
                          TextButton.icon(
                            onPressed: () {
                              FirebaseFirestore.instance
                                  .collection('reports')
                                  .doc(docId)
                                  .update({'flags': FieldValue.increment(1)});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Issue flagged for review.")),
                              );
                            },
                            icon: const Icon(Icons.flag, color: Colors.red),
                            label: Text(
                              "Flag (${data['flags'] ?? 0})",
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}