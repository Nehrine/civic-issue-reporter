import 'package:flutter/material.dart';

class IssueListScreen extends StatefulWidget {
  const IssueListScreen({super.key});

  @override
  State<IssueListScreen> createState() => _IssueListScreenState();
}

class _IssueListScreenState extends State<IssueListScreen> {
  // Dummy issues for now
  List<Map<String, dynamic>> issues = [
    {
      'title': 'Pothole on Main Street',
      'description': 'There is a large pothole near the bus stop.',
      'upvotes': 3,
      'flagged': false,
    },
    {
      'title': 'Street light not working',
      'description': 'The street light is off near my home.',
      'upvotes': 5,
      'flagged': false,
    },
    {
      'title': 'Garbage not collected',
      'description': 'Garbage has not been collected for 1 week.',
      'upvotes': 2,
      'flagged': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Issue List'),
      ),
      body: ListView.builder(
        itemCount: issues.length,
        itemBuilder: (context, index) {
          final issue = issues[index];
          return Card(
            margin: const EdgeInsets.all(10),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    issue['title'],
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(issue['description']),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Upvote Button
                      IconButton(
                        icon: const Icon(Icons.thumb_up),
                        onPressed: () {
                          setState(() {
                            issue['upvotes'] += 1;
                          });
                        },
                      ),
                      Text(issue['upvotes'].toString()),
                      const SizedBox(width: 20),
                      // Flag Button
                      IconButton(
                        icon: Icon(
                          Icons.flag,
                          color: issue['flagged'] ? Colors.red : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            issue['flagged'] = !issue['flagged'];
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
