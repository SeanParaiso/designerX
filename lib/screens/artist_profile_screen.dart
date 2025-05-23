import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'following_list_screen.dart';
import 'followers_list_screen.dart';

class ArtistProfileScreen extends StatelessWidget {
  final String artistId;
  final String artistUsername;

  const ArtistProfileScreen({
    Key? key,
    required this.artistId,
    required this.artistUsername,
  }) : super(key: key);

  // Color palette
  final Color primaryColor = const Color(0xFF2A2F4F); // Deep navy
  final Color secondaryColor = const Color(0xFF917FB3); // Soft purple
  final Color accentColor = const Color(0xFFE5BEEC); // Light purple
  final Color backgroundColor = const Color(0xFFFDE2F3); // Soft pink

  Future<void> _followUser(String artistId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    // Check if already following
    final existingFollow = await FirebaseFirestore.instance
        .collection('tbl_followers')
        .where('follower_id', isEqualTo: currentUserId)
        .where('following_id', isEqualTo: artistId)
        .get();

    if (existingFollow.docs.isEmpty) {
      // Add new follow relationship
      await FirebaseFirestore.instance.collection('tbl_followers').add({
        'follower_id': currentUserId,
        'following_id': artistId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _unfollowUser(String artistId) async {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    
    // Find and delete the follow relationship
    final followRef = await FirebaseFirestore.instance
        .collection('tbl_followers')
        .where('follower_id', isEqualTo: currentUserId)
        .where('following_id', isEqualTo: artistId)
        .get();

    if (followRef.docs.isNotEmpty) {
      await followRef.docs.first.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnProfile = currentUserId == artistId;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          artistUsername,
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
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('tbl_artists').doc(artistId).snapshots(),
        builder: (context, artistSnapshot) {
          if (artistSnapshot.hasError) {
            return Center(
              child: Text(
                'Error loading profile',
                style: GoogleFonts.poppins(color: primaryColor),
              ),
            );
          }

          if (artistSnapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: secondaryColor),
            );
          }

          final artistData = artistSnapshot.data?.data() as Map<String, dynamic>?;
          if (artistData == null) {
            return Center(
              child: Text(
                'Artist not found',
                style: GoogleFonts.poppins(color: primaryColor),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
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
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        artistData['username'] ?? 'Unknown Artist',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      if (artistData['bio'] != null && artistData['bio'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            artistData['bio'],
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: primaryColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      if (artistData['location'] != null && artistData['location'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: secondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                artistData['location'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isOwnProfile) ...[
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('tbl_followers')
                              .where('follower_id', isEqualTo: currentUserId)
                              .where('following_id', isEqualTo: artistId)
                              .snapshots(),
                          builder: (context, followSnapshot) {
                            final isFollowing = followSnapshot.data?.docs.isNotEmpty ?? false;
                            return ElevatedButton(
                              onPressed: () {
                                if (isFollowing) {
                                  _unfollowUser(artistId);
                                } else {
                                  _followUser(artistId);
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
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                              ),
                              child: Text(
                                isFollowing ? 'Following' : 'Follow',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                // Stats Row
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: primaryColor.withOpacity(0.1)),
                      bottom: BorderSide(color: primaryColor.withOpacity(0.1)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('tbl_posts')
                            .where('user_id', isEqualTo: artistId)
                            .snapshots(),
                        builder: (context, postsSnapshot) {
                          final postsCount = postsSnapshot.data?.docs.length ?? 0;
                          return _buildStatColumn('Posts', postsCount.toString());
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowersListScreen(
                                userId: artistId,
                                username: artistData['username'] ?? 'Unknown Artist',
                              ),
                            ),
                          );
                        },
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('tbl_followers')
                              .where('following_id', isEqualTo: artistId)
                              .snapshots(),
                          builder: (context, followersSnapshot) {
                            final followersCount = followersSnapshot.data?.docs.length ?? 0;
                            return _buildStatColumn('Followers', followersCount.toString());
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowingListScreen(
                                userId: artistId,
                                username: artistData['username'] ?? 'Unknown Artist',
                              ),
                            ),
                          );
                        },
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('tbl_followers')
                              .where('follower_id', isEqualTo: artistId)
                              .snapshots(),
                          builder: (context, followingSnapshot) {
                            final followingCount = followingSnapshot.data?.docs.length ?? 0;
                            return _buildStatColumn('Following', followingCount.toString());
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Artworks Grid
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Artworks',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tbl_posts')
                      .where('user_id', isEqualTo: artistId)
                      .snapshots(),
                  builder: (context, postsSnapshot) {
                    if (postsSnapshot.hasError) {
                      print('Error in posts stream: ${postsSnapshot.error}');
                      return Container(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 60,
                                color: secondaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading artworks',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please try again later',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (postsSnapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(color: secondaryColor),
                        ),
                      );
                    }

                    if (!postsSnapshot.hasData) {
                      return Container(
                        height: 200,
                        child: Center(
                          child: Text(
                            'No data available',
                            style: GoogleFonts.poppins(color: primaryColor),
                          ),
                        ),
                      );
                    }

                    final posts = postsSnapshot.data!.docs;

                    if (posts.isEmpty) {
                      return Container(
                        height: 200,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.art_track_outlined,
                                  size: 60,
                                  color: secondaryColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No artworks yet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        try {
                          final post = posts[index];
                          final data = post.data() as Map<String, dynamic>?;
                          
                          if (data == null) {
                            return Container(
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: secondaryColor,
                                  size: 40,
                                ),
                              ),
                            );
                          }

                          final imageUrl = data['image_url'] as String?;
                          final title = data['content'] as String?;
                          final category = data['category'] as String?;

                          return GestureDetector(
                            onTap: () {
                              if (imageUrl != null && imageUrl.isNotEmpty) {
                                _showFullScreenImage(context, imageUrl);
                              }
                            },
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (imageUrl != null && imageUrl.isNotEmpty)
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        child: Image.network(
                                          imageUrl,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: accentColor.withOpacity(0.2),
                                              child: Center(
                                                child: Icon(
                                                  Icons.image_not_supported_outlined,
                                                  color: secondaryColor,
                                                  size: 40,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.2),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported_outlined,
                                            color: secondaryColor,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (title != null && title.isNotEmpty || category != null)
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (title != null && title.isNotEmpty)
                                            Text(
                                              title,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: primaryColor,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          if (category != null) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                category,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 10,
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        } catch (e) {
                          print('Error building item at index $index: $e');
                          return Container(
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.error_outline,
                                color: secondaryColor,
                                size: 40,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: secondaryColor,
          ),
        ),
      ],
    );
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