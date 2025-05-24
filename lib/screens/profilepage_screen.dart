import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart'; // Import your LoginScreen
import 'homepage_screen.dart'; // Import the HomePage
import 'edit_profile_screen.dart'; // Import the edit profile screen
import 'followers_list_screen.dart'; // Import the FollowersListScreen
import 'following_list_screen.dart'; // Import the FollowingListScreen

class ProfilePageScreen extends StatefulWidget {
  const ProfilePageScreen({Key? key}) : super(key: key);

  @override
  State<ProfilePageScreen> createState() => _ProfilePageScreenState();
}

class _ProfilePageScreenState extends State<ProfilePageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFF2A2F4F); // Deep navy
  final Color secondaryColor = const Color(0xFF917FB3); // Soft purple
  final Color accentColor = const Color(0xFFE5BEEC); // Light purple
  final Color backgroundColor = const Color(0xFFFDE2F3); // Soft pink

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              final userId = FirebaseAuth.instance.currentUser!.uid;
              FirebaseFirestore.instance
                  .collection('tbl_artists')
                  .doc(userId)
                  .get()
                  .then((userData) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(userData: userData),
                  ),
                );
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              icon: Icon(Icons.grid_on, color: Colors.white),
            ),
            Tab(
              icon: Icon(Icons.person_outline, color: Colors.white),
            ),
          ],
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('tbl_artists')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get(),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: secondaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 60, color: secondaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'Profile not found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          final artistData = snapshot.data!;
          final String? profilePicture = artistData.data() is Map<String, dynamic> ? 
              (artistData.data() as Map<String, dynamic>)['profile_picture'] : null;
          
          return TabBarView(
            controller: _tabController,
            children: [
              // Artworks Tab
              _buildArtworksTab(artistData),
              // Account Details Tab
              _buildAccountDetailsTab(artistData, profilePicture),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildArtworksTab(DocumentSnapshot artistData) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Picture
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
                  child: artistData.data() is Map<String, dynamic> && 
                         (artistData.data() as Map<String, dynamic>)['profile_picture'] != null &&
                         (artistData.data() as Map<String, dynamic>)['profile_picture'].toString().isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            (artistData.data() as Map<String, dynamic>)['profile_picture'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.person, size: 50, color: Colors.white);
                            },
                          ),
                        )
                      : Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                // Username
                Text(
                  artistData['username'] ?? 'Unknown Artist',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                // Stats Row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('tbl_posts')
                            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
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
                                userId: FirebaseAuth.instance.currentUser!.uid,
                                username: artistData['username'] ?? 'Unknown Artist',
                              ),
                            ),
                          );
                        },
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('tbl_followers')
                              .where('following_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
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
                                userId: FirebaseAuth.instance.currentUser!.uid,
                                username: artistData['username'] ?? 'Unknown Artist',
                              ),
                            ),
                          );
                        },
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('tbl_followers')
                              .where('follower_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
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
              ],
            ),
          ),
          // Artworks Grid
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tbl_posts')
                .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, postsSnapshot) {
              if (postsSnapshot.hasError) {
                print('Error in posts stream: ${postsSnapshot.error}');
                print('Error stack trace: ${postsSnapshot.stackTrace}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: secondaryColor),
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
                );
              }

              if (postsSnapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: secondaryColor),
                );
              }

              if (!postsSnapshot.hasData) {
                return Center(
                  child: Text(
                    'No data available',
                    style: GoogleFonts.poppins(color: primaryColor),
                  ),
                );
              }

              final posts = postsSnapshot.data!.docs;
              
              // Sort posts by timestamp in memory instead of in query
              try {
                posts.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTimestamp = aData['timestamp'] as Timestamp?;
                  final bTimestamp = bData['timestamp'] as Timestamp?;
                  if (aTimestamp == null && bTimestamp == null) return 0;
                  if (aTimestamp == null) return 1;
                  if (bTimestamp == null) return -1;
                  return bTimestamp.compareTo(aTimestamp);
                });
              } catch (e) {
                print('Error sorting posts: $e');
                // Continue without sorting if there's an error
              }

              if (posts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
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
                        const SizedBox(height: 8),
                        Text(
                          'Share your first artwork!',
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
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.share_outlined,
                                      color: primaryColor.withOpacity(0.5),
                                    ),
                                    onPressed: () {
                                      // Optionally implement share for profile posts
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: primaryColor.withOpacity(0.5),
                                    ),
                                    tooltip: 'Delete Post',
                                    onPressed: () {
                                      _showDeleteConfirmation(context, post.id);
                                    },
                                  ),
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
  }

  Widget _buildAccountDetailsTab(DocumentSnapshot artistData, String? profilePicture) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header with background
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [secondaryColor, primaryColor],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: profilePicture != null && profilePicture.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              profilePicture,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person, size: 60, color: secondaryColor);
                              },
                            ),
                          )
                        : Icon(Icons.person, size: 60, color: secondaryColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          // Name and username
          Text(
            '${artistData['first_name'] ?? ''} ${artistData['last_name'] ?? ''}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          Text(
            '@${artistData['username'] ?? ''}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: secondaryColor,
            ),
          ),
          // Location pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, size: 16, color: secondaryColor),
                const SizedBox(width: 6),
                Text(
                  artistData.data() is Map<String, dynamic> && 
                  (artistData.data() as Map<String, dynamic>).containsKey('location') && 
                  (artistData.data() as Map<String, dynamic>)['location'] != null && 
                  (artistData.data() as Map<String, dynamic>)['location'].toString().isNotEmpty
                    ? (artistData.data() as Map<String, dynamic>)['location']
                    : "No location added",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          // Content Cards
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Bio Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: secondaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Bio',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          artistData.data() is Map<String, dynamic> && 
                          (artistData.data() as Map<String, dynamic>).containsKey('bio') && 
                          (artistData.data() as Map<String, dynamic>)['bio'] != null && 
                          (artistData.data() as Map<String, dynamic>)['bio'].toString().isNotEmpty
                            ? (artistData.data() as Map<String, dynamic>)['bio']
                            : "No bio added yet",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: primaryColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Personal Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline, color: secondaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Personal Information',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        infoItem(Icons.badge, 'First Name', artistData['first_name'] ?? ''),
                        const Divider(color: Colors.grey),
                        infoItem(Icons.person, 'Last Name', artistData['last_name'] ?? ''),
                        const Divider(color: Colors.grey),
                        infoItem(Icons.alternate_email, 'Username', artistData['username'] ?? ''),
                        const Divider(color: Colors.grey),
                        infoItem(Icons.email, 'Email', artistData['email'] ?? ''),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Sign Out Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [secondaryColor, primaryColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: secondaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
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

  Widget infoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: secondaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: secondaryColor,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
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

  void _showDeleteConfirmation(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Post'),
        content: Text('Are you sure you want to permanently delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await FirebaseFirestore.instance.collection('tbl_posts').doc(postId).delete();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Post deleted')),
              );
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
