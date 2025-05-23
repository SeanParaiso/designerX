import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'artist_profile_screen.dart';

class FollowersListScreen extends StatelessWidget {
  final String userId;
  final String username;

  const FollowersListScreen({
    Key? key,
    required this.userId,
    required this.username,
  }) : super(key: key);

  // Color palette
  final Color primaryColor = const Color(0xFF2A2F4F);
  final Color secondaryColor = const Color(0xFF917FB3);
  final Color accentColor = const Color(0xFFE5BEEC);
  final Color backgroundColor = const Color(0xFFFDE2F3);

  Future<void> _followUser(String followerId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    // Check if already following
    final existingFollow = await FirebaseFirestore.instance
        .collection('tbl_followers')
        .where('follower_id', isEqualTo: currentUserId)
        .where('following_id', isEqualTo: followerId)
        .get();

    if (existingFollow.docs.isEmpty) {
      // Add new follow relationship
      await FirebaseFirestore.instance.collection('tbl_followers').add({
        'follower_id': currentUserId,
        'following_id': followerId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _unfollowUser(String followerId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    // Find and delete the follow relationship
    final followRef = await FirebaseFirestore.instance
        .collection('tbl_followers')
        .where('follower_id', isEqualTo: currentUserId)
        .where('following_id', isEqualTo: followerId)
        .get();

    if (followRef.docs.isNotEmpty) {
      await followRef.docs.first.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Followers',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tbl_followers')
            .where('following_id', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading followers list',
                style: GoogleFonts.poppins(color: primaryColor),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: secondaryColor),
            );
          }

          final followersDocs = snapshot.data?.docs ?? [];

          if (followersDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 60, color: secondaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'No followers yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: followersDocs.length,
            itemBuilder: (context, index) {
              final followerDoc = followersDocs[index];
              final followerId = followerDoc['follower_id'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('tbl_artists')
                    .doc(followerId)
                    .get(),
                builder: (context, artistSnapshot) {
                  if (!artistSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final artistData = artistSnapshot.data!.data() as Map<String, dynamic>?;
                  if (artistData == null) {
                    return const SizedBox.shrink();
                  }

                  final isCurrentUser = followerId == currentUserId;

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArtistProfileScreen(
                                artistId: followerId,
                                artistUsername: artistData['username'] ?? 'Unknown Artist',
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [secondaryColor, primaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('tbl_artists')
                                  .doc(followerId)
                                  .snapshots(),
                              builder: (context, artistSnapshot) {
                                String? profilePicUrl;
                                if (artistSnapshot.hasData && artistSnapshot.data!.exists) {
                                  final artistData = artistSnapshot.data!.data() as Map<String, dynamic>?;
                                  profilePicUrl = artistData?['profile_picture'];
                                }

                                return CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: profilePicUrl != null && profilePicUrl.isNotEmpty
                                      ? NetworkImage(profilePicUrl)
                                      : null,
                                  child: profilePicUrl == null || profilePicUrl.isEmpty
                                      ? Icon(Icons.person, color: Colors.white)
                                      : null,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      title: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArtistProfileScreen(
                                artistId: followerId,
                                artistUsername: artistData['username'] ?? 'Unknown Artist',
                              ),
                            ),
                          );
                        },
                        child: Text(
                          artistData['username'] ?? 'Unknown Artist',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      subtitle: Text(
                        artistData['bio'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: secondaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: isCurrentUser
                          ? null
                          : StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('tbl_followers')
                                  .where('follower_id', isEqualTo: currentUserId)
                                  .where('following_id', isEqualTo: followerId)
                                  .snapshots(),
                              builder: (context, followSnapshot) {
                                final isFollowing = followSnapshot.data?.docs.isNotEmpty ?? false;
                                return ElevatedButton(
                                  onPressed: () {
                                    if (isFollowing) {
                                      _unfollowUser(followerId);
                                    } else {
                                      _followUser(followerId);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isFollowing ? Colors.white : primaryColor,
                                    foregroundColor: isFollowing ? primaryColor : Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      side: BorderSide(
                                        color: primaryColor,
                                        width: isFollowing ? 1 : 0,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isFollowing ? Icons.check : Icons.add,
                                        size: 18,
                                        color: isFollowing ? primaryColor : Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isFollowing ? 'Following' : 'Follow',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 