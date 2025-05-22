import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../screens/comment_screen.dart';

class FeedContentScreen extends StatelessWidget {
  const FeedContentScreen({Key? key}) : super(key: key);

  // Color palette
  final Color primaryColor = const Color(0xFF2A2F4F); // Deep navy
  final Color secondaryColor = const Color(0xFF917FB3); // Soft purple
  final Color accentColor = const Color(0xFFE5BEEC); // Light purple
  final Color backgroundColor = const Color(0xFFFDE2F3); // Soft pink

  Future<void> _likePost(String postId, bool isLiked) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final postRef = FirebaseFirestore.instance.collection("tbl_posts").doc(postId);
    final likesRef = FirebaseFirestore.instance.collection("tbl_likes").doc('${userId}_$postId');

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final postSnapshot = await transaction.get(postRef);
      
      if (isLiked) {
        transaction.delete(likesRef);
        transaction.update(postRef, {
          'likes_count': (postSnapshot.data()?['likes_count'] ?? 0) - 1,
        });
      } else {
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

  Future<void> _sharePost(String username, String content, String? imageUrl) async {
    String shareText = 'Check out this artwork by $username on The Artchive!\n\n$content';
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await Share.share(shareText, subject: 'Artwork from The Artchive');
    } else {
      await Share.share(shareText, subject: 'Artwork from The Artchive');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            backgroundColor,
            Colors.white,
          ],
        ),
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("tbl_posts").orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: secondaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading posts',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: secondaryColor,
              ),
            );
          }
          final posts = snapshot.data!.docs;
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.art_track_outlined, size: 60, color: secondaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'No artworks yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to share your artwork!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            );
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
              final timestamp = post['timestamp'] as Timestamp?;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [secondaryColor, primaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.transparent,
                              child: Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                                if (timestamp != null)
                                  Text(
                                    _getTimeAgo(timestamp.toDate()),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: secondaryColor.withOpacity(0.7),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Artwork Image
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Hero(
                        tag: 'post_$postId',
                        child: GestureDetector(
                          onTap: () {
                            // Show full-screen image
                            _showFullScreenImage(context, imageUrl);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              height: 300,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 300,
                                  color: accentColor.withOpacity(0.2),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: secondaryColor,
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 300,
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported_outlined,
                                          color: secondaryColor,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Failed to load image',
                                          style: GoogleFonts.poppins(
                                            color: secondaryColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        content,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: primaryColor.withOpacity(0.8),
                          height: 1.5,
                        ),
                      ),
                    ),
                    // Actions Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: primaryColor.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
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
                                  return Row(
                                    children: [
                                      IconButton(
                                        icon: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 300),
                                          child: Icon(
                                            isLiked ? Icons.favorite : Icons.favorite_border,
                                            key: ValueKey<bool>(isLiked),
                                            color: isLiked ? Colors.red : primaryColor.withOpacity(0.5),
                                          ),
                                        ),
                                        onPressed: currentUserId == null
                                            ? null
                                            : () => _likePost(postId, isLiked),
                                      ),
                                      Text(
                                        '$likesCount',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.comment_outlined,
                                      color: primaryColor.withOpacity(0.5),
                                    ),
                                    onPressed: () => _navigateToComments(context, postId, username),
                                  ),
                                  Text(
                                    '$commentsCount',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.share_outlined,
                              color: primaryColor.withOpacity(0.5),
                            ),
                            onPressed: () => _sharePost(username, content, imageUrl),
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

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
