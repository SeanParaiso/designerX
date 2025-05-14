import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/comment_screen.dart';

class FeedContentScreen extends StatelessWidget {
  const FeedContentScreen({Key? key}) : super(key: key);

  Future<void> _likePost(String postId, bool isLiked) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final postRef = FirebaseFirestore.instance.collection("tbl_posts").doc(postId);
    final likesRef = FirebaseFirestore.instance.collection("tbl_likes").doc('${userId}_$postId');

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      
      if (isLiked) {
        // Unlike post
        transaction.delete(likesRef);
        transaction.update(postRef, {
          'likes_count': (postSnapshot.data()?['likes_count'] ?? 0) - 1,
        });
      } else {
        // Like post
        transaction.set(likesRef, {
          'user_id': userId,
          'post_id': postId,
          'timestamp': FieldValue.serverTimestamp(),
        });
        transaction.update(postRef, {
          'likes_count': (postSnapshot.data()?['likes_count'] ?? 0) + 1,
        });
      }
    });
  }

  Future<void> _navigateToComments(BuildContext context, String postId, String postUsername) async {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => CommentScreen(postId: postId, postUsername: postUsername),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
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
            final postId = post.id;
            final username = post['username'] ?? 'Unknown Artist';
            final content = post['content'] ?? '';
            final imageUrl = post['image_url'];
            final likesCount = post['likes_count'] ?? 0;
            final commentsCount = post['comments_count'] ?? 0;

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
                        width: double.infinity,
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
                            StreamBuilder<DocumentSnapshot>(
                              stream: currentUserId != null
                                  ? FirebaseFirestore.instance
                                      .collection("tbl_likes")
                                      .doc('${currentUserId}_$postId')
                                      .snapshots()
                                  : null,
                              builder: (context, likeSnapshot) {
                                final isLiked = likeSnapshot.hasData && likeSnapshot.data!.exists;
                                return Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                        color: isLiked ? Colors.blue : Colors.grey,
                                      ),
                                      onPressed: currentUserId == null
                                          ? null
                                          : () => _likePost(postId, isLiked),
                                    ),
                                    Text('$likesCount', style: TextStyle(fontSize: 12)),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.comment_outlined, color: Colors.blue),
                                  onPressed: () => _navigateToComments(context, postId, username),
                                ),
                                Text('$commentsCount', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          post['timestamp'] != null
                              ? (post['timestamp'] as Timestamp).toDate().toLocal().toString().substring(0, 16)
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
