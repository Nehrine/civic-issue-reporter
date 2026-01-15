import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewIssuesScreen extends StatelessWidget {
  const ViewIssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported Issues'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('issues')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final issues = snapshot.data!.docs;

          if (issues.isEmpty) {
            return const Center(child: Text('No issues reported yet'));
          }

          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue['title'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(issue['description']),
                      const SizedBox(height: 6),

                      Text(
                        '📍 ${issue['location']}',
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 12),

                      // UPVOTE & FLAG BUTTONS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.thumb_up),
                                onPressed: () {
                                  issue.reference.update({
                                    'upvotes': FieldValue.increment(1),
                                  });
                                },
                              ),
                              Text(issue['upvotes'].toString()),
                            ],
                          ),

                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.flag),
                                onPressed: () {
                                  issue.reference.update({
                                    'flags': FieldValue.increment(1),
                                  });
                                },
                              ),
                              Text(issue['flags'].toString()),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
