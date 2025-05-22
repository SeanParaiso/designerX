import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_screen.dart'; // Import your SignupScreen
import 'homepage_screen.dart'; // Import the HomePage
import 'edit_profile_screen.dart'; // Import the edit profile screen

class ProfilePageScreen extends StatelessWidget {
  const ProfilePageScreen({Key? key}) : super(key: key);

  // Color palette
  final Color primaryColor = const Color(0xFF2A2F4F); // Deep navy
  final Color secondaryColor = const Color(0xFF917FB3); // Soft purple
  final Color accentColor = const Color(0xFFE5BEEC); // Light purple
  final Color backgroundColor = const Color(0xFFFDE2F3); // Soft pink

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
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile header with background
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Background container with gradient
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
                    
                    // Profile picture
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
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return CircularProgressIndicator(
                                        color: secondaryColor,
                                      );
                                    },
                                  ),
                                )
                              : Icon(Icons.person, size: 60, color: secondaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Spacing for profile picture overflow
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupScreen()),
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: Text(
                        'Sign Out',
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
        },
      ),
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
}
