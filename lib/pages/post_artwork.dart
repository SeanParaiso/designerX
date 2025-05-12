import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostArtworkPage extends StatelessWidget {
  const PostArtworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    var userIdController = TextEditingController();
    var contentController = TextEditingController();
    var imageUrlController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Post Artwork")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextFormField(
              controller: userIdController,
              decoration: const InputDecoration(labelText: 'User ID (Artist)'),
            ),
            TextFormField(
              controller: contentController,
              decoration: const InputDecoration(labelText: 'Post Content'),
            ),
            TextFormField(
              controller: imageUrlController,
              decoration: const InputDecoration(labelText: 'Image URL'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                var userId = userIdController.text;
                var content = contentController.text;
                var imageUrl = imageUrlController.text;

                FirebaseFirestore.instance.collection("tbl_posts").add({
                  "user_id": userId,
                  "content": content,
                  "image_url": imageUrl,
                  "timestamp": FieldValue.serverTimestamp(),
                  "likes_count": 0,
                  "comments_count": 0,
                }).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Artwork Posted!")),
                  );
                }).catchError((e) => print("Post failed: $e"));
              },
              child: const Text("Post Artwork"),
            )
          ],
        ),
      ),
    );
  }
}
