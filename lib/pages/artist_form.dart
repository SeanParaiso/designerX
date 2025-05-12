import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArtistForm extends StatelessWidget {
  const ArtistForm({super.key});

  @override
  Widget build(BuildContext context) {
    var nameController = TextEditingController();
    var profilePicController = TextEditingController();
    var bioController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Artist Registration')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              controller: profilePicController,
              decoration: const InputDecoration(labelText: 'Profile Picture URL'),
            ),
            TextFormField(
              controller: bioController,
              decoration: const InputDecoration(labelText: 'Bio'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                var name = nameController.text;
                var profilePic = profilePicController.text;
                var bio = bioController.text;

                FirebaseFirestore.instance.collection("tbl_artists").add({
                  "name": name,
                  "profile_picture": profilePic,
                  "bio": bio,
                }).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Artist Registered!")),
                  );
                }).catchError((e) => print("Failed to add artist: $e"));
              },
              child: const Text("Register Artist"),
            ),
          ],
        ),
      ),
    );
  }
}
