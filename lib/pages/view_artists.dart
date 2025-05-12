import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewArtistsPage extends StatelessWidget {
  const ViewArtistsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Artists')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("tbl_artists").snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var artist = docs[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(artist['profile_picture'] ?? ''),
                ),
                title: Text(artist['name'] ?? ''),
                subtitle: Text(artist['bio'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
