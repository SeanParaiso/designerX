import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/postArtwork'); // Use named route
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
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

// Profile Page
class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Profile Page'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navigate back to SignupScreen after signing out
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignupScreen()),
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

void _showAccountDetails(BuildContext context) async {
  try {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot artistDoc = await FirebaseFirestore.instance.collection('tbl_artists').doc(userId).get();

    if (artistDoc.exists) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Account Details'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text('First Name: ${artistDoc['first_name']}'),
                  Text('Last Name: ${artistDoc['last_name']}'),
                  Text('Username: ${artistDoc['username']}'),
                  Text('Email: ${artistDoc['email']}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: const Text('Close'),
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

void _signOut(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  // Navigate back to SignupScreen after signing out
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => const SignupScreen()),
  );
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
        BottomNavigationBarItem(icon: Icon(Icons.art_track), label: 'Art'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      currentIndex: selectedIndex,
      onTap: onItemTapped,
    );
  }
}