import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedContentScreen extends StatelessWidget {
  const FeedContentScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("tbl_posts").orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading posts'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data!.docs;
        if (posts.isEmpty) {
          return const Center(child: Text('No artworks yet'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: posts.length,
          itemBuilder: (context, i) {
            final post = posts[i];
            final username = post['username'] ?? 'Unknown Artist';
            final content = post['content'] ?? '';
            final imageUrl = post['image_url'];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          username,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  // Artwork Image
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        imageUrl,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 250,
                            color: Colors.grey[200],
                            child: const Center(child: Text('Image error')),
                          );
                        },
                      ),
                    ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      content,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                    ),
                  ),
                  // Timestamp and Actions
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.thumb_up, color: Colors.blue),
                              onPressed: () {
                                // Handle like action
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.comment, color: Colors.blue),
                              onPressed: () {
                                // Handle comment action
                              },
                            ),
                          ],
                        ),
                        Text(
                          post['timestamp'] != null
                              ? (post['timestamp'] as Timestamp).toDate().toLocal().toString()
                              : '',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
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
    );
  }
}
