import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_screen.dart'; // Import your SignupScreen
import 'feedcontent_screen.dart'; // Import your FeedContentScreen
import 'artpage_screen.dart'; // Import your ArtPageScreen
import 'profilepage_screen.dart'; // Import your ProfilePageScreen
import 'postartwork_screen.dart'; // Import your PostArtworkScreen

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Color palette matching login/signup screens
  final Color primaryColor = const Color(0xFF2A2F4F); // Deep navy
  final Color secondaryColor = const Color(0xFF917FB3); // Soft purple
  final Color accentColor = const Color(0xFFE5BEEC); // Light purple
  final Color backgroundColor = const Color(0xFFFDE2F3); // Soft pink
  final Color buttonGradientStart = const Color(0xFF917FB3); // Soft purple
  final Color buttonGradientEnd = const Color(0xFF2A2F4F); // Deep navy

  // List of pages for bottom navigation
  final List<Widget> _pages = [
    const FeedContentScreen(), // Updated to use FeedContentScreen
    const ArtPageScreen(),      // Updated to use ArtPageScreen
    const ProfilePageScreen(),  // Updated to use ProfilePageScreen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _selectedIndex == 0 ? _buildAppBar(context) : null,
      body: Container(
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
        child: _pages[_selectedIndex], // Display the selected page
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
      ),
    );
  }
  
  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'The Artchive',
        style: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: primaryColor.withOpacity(0.3),
              offset: const Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              buttonGradientStart,
              buttonGradientEnd,
            ],
          ),
        ),
      ),
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 28, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PostArtworkScreen()),
            );
          },
        ),
        const SizedBox(width: 8), // Extra spacing on the right
      ],
    );
  }
}

// Home Content Page
class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Text('Welcome to the Home Page!'),
    );
  }
}

// Art Page
class ArtPage extends StatelessWidget {
  const ArtPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Text('Art Page'),
    );
  }
}

// Profile Page with updated styling
class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF2A2F4F);
    final Color secondaryColor = const Color(0xFF917FB3);
    final Color buttonGradientStart = const Color(0xFF917FB3);
    final Color buttonGradientEnd = const Color(0xFF2A2F4F);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Profile',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [buttonGradientStart, buttonGradientEnd],
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
            child: ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Sign Out',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showAccountDetails(BuildContext context) async {
  final Color primaryColor = const Color(0xFF2A2F4F);
  final Color secondaryColor = const Color(0xFF917FB3);

  try {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot artistDoc = await FirebaseFirestore.instance.collection('tbl_artists').doc(userId).get();

    if (artistDoc.exists) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              'Account Details',
              style: GoogleFonts.playfairDisplay(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  _buildDetailRow('First Name', artistDoc['first_name'], secondaryColor),
                  _buildDetailRow('Last Name', artistDoc['last_name'], secondaryColor),
                  _buildDetailRow('Username', artistDoc['username'], secondaryColor),
                  _buildDetailRow('Email', artistDoc['email'], secondaryColor),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      print("User details not found.");
    }
  } catch (e) {
    print("Error fetching user details: $e");
    // Optionally show a dialog to the user
  }
}

Widget _buildDetailRow(String label, String value, Color secondaryColor) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: secondaryColor,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              color: secondaryColor.withOpacity(0.8),
            ),
          ),
        ),
      ],
    ),
  );
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final Color primaryColor;
  final Color secondaryColor;

  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.primaryColor,
    required this.secondaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: selectedIndex == 0 ? primaryColor : secondaryColor),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.art_track, color: selectedIndex == 1 ? primaryColor : secondaryColor),
            label: 'Art',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: selectedIndex == 2 ? primaryColor : secondaryColor),
            label: 'Profile',
          ),
        ],
        currentIndex: selectedIndex,
        onTap: onItemTapped,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryColor,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(),
      ),
    );
  }
}