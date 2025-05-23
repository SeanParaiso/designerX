import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class CommentScreen extends StatefulWidget {
  final String postId;
  final String postUsername;

  const CommentScreen({
    Key? key,
    required this.postId,
    required this.postUsername,
  }) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isSubmitting = false;

  // Color palette
  final Color primaryColor = const Color(0xFF2A2F4F); // Deep navy
  final Color secondaryColor = const Color(0xFF917FB3); // Soft purple
  final Color accentColor = const Color(0xFFE5BEEC); // Light purple
  final Color backgroundColor = const Color(0xFFFDE2F3); // Soft pink

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty || _currentUser == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = _currentUser!.uid;
      DocumentSnapshot userDoc = await _firestore.collection("tbl_artists").doc(userId).get();
      
      String username = 'Anonymous';
      if (userDoc.exists) {
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null && userData.containsKey('username')) {
          username = userData['username'];
        }
      }

      await _firestore.collection('tbl_comments').add({
        'post_id': widget.postId,
        'user_id': userId,
        'content': _commentController.text.trim(),
        'username': username,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('tbl_posts').doc(widget.postId);
        final postSnapshot = await transaction.get(postRef);
        
        transaction.update(postRef, {
          'comments_count': (postSnapshot.data()?['comments_count'] ?? 0) + 1,
        });
      });

      _commentController.clear();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding comment: $error'),
          backgroundColor: secondaryColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      final batch = _firestore.batch();
      final commentRef = _firestore.collection('tbl_comments').doc(commentId);
      final postRef = _firestore.collection('tbl_posts').doc(widget.postId);
      final postDoc = await postRef.get();
      final currentCommentsCount = postDoc.data()?['comments_count'] ?? 0;
      
      batch.delete(commentRef);
      
      if (currentCommentsCount > 0) {
        batch.update(postRef, {
          'comments_count': currentCommentsCount - 1
        });
      }
      
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Comment deleted successfully'),
          backgroundColor: secondaryColor,
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting comment: $error'),
          backgroundColor: secondaryColor,
        ),
      );
    }
  }

  void _showDeleteDialog(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Comment',
          style: GoogleFonts.poppins(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this comment?',
          style: GoogleFonts.poppins(color: primaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: secondaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(commentId);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Comments',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [secondaryColor, primaryColor],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('tbl_comments')
                  .where('post_id', isEqualTo: widget.postId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: secondaryColor,
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(color: primaryColor),
                    ),
                  );
                }
                
                final comments = snapshot.data?.docs ?? [];
                
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      'No comments yet. Be the first to comment!',
                      style: GoogleFonts.poppins(
                        color: primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final commentId = comment.id;
                    final userId = comment['user_id'];
                    final timestamp = comment['timestamp'] as Timestamp?;
                    final username = comment['username'] ?? 'Anonymous';
                    final isCurrentUserComment = _currentUser != null && _currentUser!.uid == userId;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('tbl_artists')
                                      .doc(userId)
                                      .snapshots(),
                                  builder: (context, artistSnapshot) {
                                    String? profilePicUrl;
                                    if (artistSnapshot.hasData && artistSnapshot.data!.exists) {
                                      final artistData = artistSnapshot.data!.data() as Map<String, dynamic>?;
                                      profilePicUrl = artistData?['profile_picture'];
                                    }

                                    return Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [secondaryColor, primaryColor],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.transparent,
                                        backgroundImage: profilePicUrl != null && profilePicUrl.isNotEmpty
                                            ? NetworkImage(profilePicUrl)
                                            : null,
                                        child: profilePicUrl == null || profilePicUrl.isEmpty
                                            ? Icon(Icons.person, size: 18, color: Colors.white)
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    username,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                if (timestamp != null)
                                  Text(
                                    timestamp.toDate().toLocal().toString().substring(0, 16),
                                    style: GoogleFonts.poppins(
                                      color: secondaryColor.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                if (isCurrentUserComment)
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    onPressed: () => _showDeleteDialog(commentId),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comment['content'] ?? '',
                              style: GoogleFonts.poppins(
                                color: primaryColor.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: GoogleFonts.poppins(
                        color: secondaryColor.withOpacity(0.5),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: secondaryColor.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: secondaryColor.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: secondaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [secondaryColor, primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: SizedBox(
                    height: 48,
                    width: 48,
                    child: _isSubmitting
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _currentUser == null ? null : _addComment,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 