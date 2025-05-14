import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      // Get the username from tbl_artists collection
      final userId = _currentUser!.uid;
      DocumentSnapshot userDoc = await _firestore.collection("tbl_artists").doc(userId).get();
      
      String username = 'Anonymous';
      if (userDoc.exists) {
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null && userData.containsKey('username')) {
          username = userData['username'];
        }
      }

      // Add comment to tbl_comments
      await _firestore.collection('tbl_comments').add({
        'post_id': widget.postId,
        'user_id': userId,
        'content': _commentController.text.trim(),
        'username': username,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update comments count in tbl_posts
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
        SnackBar(content: Text('Error adding comment: $error')),
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
      // Start a batch operation
      final batch = _firestore.batch();
      
      // Reference to the comment document to delete
      final commentRef = _firestore.collection('tbl_comments').doc(commentId);
      
      // Reference to the post to update the comments count
      final postRef = _firestore.collection('tbl_posts').doc(widget.postId);
      
      // Get current post data to update the comments count
      final postDoc = await postRef.get();
      final currentCommentsCount = postDoc.data()?['comments_count'] ?? 0;
      
      // Delete the comment
      batch.delete(commentRef);
      
      // Update the comments count in the post document
      if (currentCommentsCount > 0) {
        batch.update(postRef, {
          'comments_count': currentCommentsCount - 1
        });
      }
      
      // Commit the batch
      await batch.commit();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment deleted successfully')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting comment: $error')),
      );
    }
  }

  void _showDeleteDialog(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(commentId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Column(
        children: [
          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('tbl_comments')
                  .where('post_id', isEqualTo: widget.postId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final comments = snapshot.data?.docs ?? [];
                
                if (comments.isEmpty) {
                  return const Center(child: Text('No comments yet. Be the first to comment!'));
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
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey[300],
                                  child: const Icon(Icons.person, size: 18, color: Colors.white),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (timestamp != null)
                                  Text(
                                    timestamp.toDate().toLocal().toString().substring(0, 16),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                if (isCurrentUserComment)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    onPressed: () => _showDeleteDialog(commentId),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(comment['content'] ?? ''),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Comment input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  width: 48,
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : IconButton(
                          icon: const Icon(Icons.send, color: Colors.blue),
                          onPressed: _currentUser == null ? null : _addComment,
                        ),
                ),
              ],
            ),
          ),
          // Add padding for bottom insets
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
} 