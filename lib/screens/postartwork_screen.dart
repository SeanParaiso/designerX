import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PostArtworkScreen extends StatefulWidget {
  const PostArtworkScreen({Key? key}) : super(key: key);

  @override
  _PostArtworkScreenState createState() => _PostArtworkScreenState();
}

class _PostArtworkScreenState extends State<PostArtworkScreen> {
  final TextEditingController contentController = TextEditingController();
  String? imageUrl;
  final ImagePicker _picker = ImagePicker();
  String? username;

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imageUrl = image.path; // Store the image path
      });
    }
  }

  Future<void> _postArtwork() async {
    if (imageUrl != null && contentController.text.isNotEmpty) {
      try {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        print("User ID: $userId"); // Debug: Log the user ID

        // Fetch the username from the tbl_artists collection
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("tbl_artists").doc(userId).get();
        print("User Document: ${userDoc.data()}"); // Debug: Log the user document

        if (userDoc.exists) {
          // Cast the data to a Map<String, dynamic>
          Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

          // Check if the username field exists
          if (userData != null && userData.containsKey('username')) {
            username = userData['username'];
            print("Username: $username"); // Debug: Log the username
          } else {
            throw Exception("Username field does not exist");
          }
        } else {
          throw Exception("User not found");
        }

        // Save artwork details to Firestore
        await FirebaseFirestore.instance.collection("tbl_posts").add({
          "user_id": userId,
          "content": contentController.text,
          "image_url": imageUrl,
          "username": username, // Add username to the post
          "timestamp": FieldValue.serverTimestamp(),
          "likes_count": 0,
          "comments_count": 0,
        });

        // Navigate back to the feed after posting
        Navigator.pop(context);
      } catch (e) {
        print("Error posting artwork: $e");
      }
    } else {
      // Show an error message if fields are empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields and select an image.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post Artwork')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (username != null) // Display username if available
              Text(
                username!,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: imageUrl == null
                    ? const Center(child: Text('Tap to select an image'))
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(imageUrl!),
                                fit: BoxFit.cover,
                              ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: 'Artwork Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _postArtwork,
              child: const Text('Post Artwork'),
            ),
          ],
        ),
      ),
    );
  }
}
