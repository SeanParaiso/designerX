import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // Import the generated configuration file
import 'screens/signup_screen.dart'; // Updated path
import 'screens/login_screen.dart';   // Updated path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use the generated options
  );
  runApp(const ArtDesignApp());
}

class ArtDesignApp extends StatelessWidget {
  const ArtDesignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Art & Design Showcase',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        textTheme: const TextTheme(
          titleMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: const LoginScreen(), // Initial screen
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Art & Design Showcase'),
        elevation: 4,
      ),
      body: Column(
        children: [
          // Buttons Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCustomButton(
                  context,
                  'Register Artist',
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ArtistForm()),
                  ),
                ),
                _buildCustomButton(
                  context,
                  'Post Artwork',
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PostArtworkPage()),
                  ),
                ),
                _buildCustomButton(
                  context,
                  'View Artists',
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ViewArtistsPage()),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(thickness: 1),

          // Stream of Posts
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
              FirebaseFirestore.instance.collection("tbl_posts").orderBy('timestamp', descending: true).snapshots(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: posts.length,
                  itemBuilder: (context, i) {
                    final post = posts[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if ((post['image_url'] as String).isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(
                                post['image_url'],
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              post['content'] ?? '',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Text(
                              post['timestamp'] != null
                                  ? (post['timestamp'] as Timestamp)
                                  .toDate()
                                  .toLocal()
                                  .toString()
                                  : '',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomButton(BuildContext context, String text, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class ArtistForm extends StatelessWidget {
  const ArtistForm({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController();
    final profilePicController = TextEditingController();
    final bioController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Artist Registration')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _buildInputField(nameController, 'Name'),
            const SizedBox(height: 12),
            _buildInputField(profilePicController, 'Profile Picture URL'),
            const SizedBox(height: 12),
            _buildInputField(bioController, 'Bio', maxLines: 3),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection("tbl_artists").add({
                  "name": nameController.text,
                  "profile_picture": profilePicController.text,
                  "bio": bioController.text,
                }).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Artist Registered!")),
                  );
                  Navigator.pop(context);
                }).catchError((e) => print("Error: $e"));
              },
              child: const Text("Register Artist"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class PostArtworkPage extends StatelessWidget {
  const PostArtworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userIdController = TextEditingController();
    final contentController = TextEditingController();
    final imageUrlController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Post Artwork")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _buildInputField(userIdController, 'User ID (Artist)'),
            const SizedBox(height: 12),
            _buildInputField(contentController, 'Post Content'),
            const SizedBox(height: 12),
            _buildInputField(imageUrlController, 'Image URL'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection("tbl_posts").add({
                  "user_id": userIdController.text,
                  "content": contentController.text,
                  "image_url": imageUrlController.text,
                  "timestamp": FieldValue.serverTimestamp(),
                  "likes_count": 0,
                  "comments_count": 0,
                }).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Artwork Posted!")),
                  );
                  Navigator.pop(context);
                }).catchError((e) => print("Error: $e"));
              },
              child: const Text("Post Artwork"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

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
          final artists = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: artists.length,
            itemBuilder: (context, i) {
              final a = artists[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(a['profile_picture'] ?? ''),
                  ),
                  title: Text(a['name'] ?? ''),
                  subtitle: Text(a['bio'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
