import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'profilepage_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final DocumentSnapshot userData;

  const EditProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Form controllers
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController usernameController;
  late TextEditingController bioController;
  late TextEditingController locationController;
  String? profileImagePath;
  String? existingProfilePicUrl;
  
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    final data = widget.userData.data() as Map<String, dynamic>? ?? {};
    
    firstNameController = TextEditingController(text: data['first_name'] ?? '');
    lastNameController = TextEditingController(text: data['last_name'] ?? '');
    usernameController = TextEditingController(text: data['username'] ?? '');
    bioController = TextEditingController(text: data['bio'] ?? '');
    locationController = TextEditingController(text: data['location'] ?? '');
    existingProfilePicUrl = data['profile_picture'];
  }

  @override
  void dispose() {
    // Dispose controllers
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    bioController.dispose();
    locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        profileImagePath = image.path; // Store the image path
      });
    }
  }

  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // For demonstration, we're just using the path as the URL
        // In a real app, you would upload the image to Firebase Storage first
        final String profilePicture = profileImagePath ?? existingProfilePicUrl ?? '';

        await FirebaseFirestore.instance.collection('tbl_artists').doc(user.uid).update({
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'username': usernameController.text.trim(),
          'bio': bioController.text.trim(),
          'location': locationController.text.trim(),
          'profile_picture': profilePicture,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          
          // Navigate back to profile page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePageScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFFFF9844), // Instagram-like orange
                Color(0xFFFF5F6D), // Pinkish-orange
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture Preview & Selection
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey, width: 2),
                                  color: Colors.grey[200],
                                ),
                                child: ClipOval(
                                  child: _getProfileImage(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to change profile picture',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Form Fields
                      _buildInputField(
                        controller: firstNameController,
                        label: 'First Name',
                        hint: 'Enter your first name',
                        icon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      
                      _buildInputField(
                        controller: lastNameController,
                        label: 'Last Name',
                        hint: 'Enter your last name',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      
                      _buildInputField(
                        controller: usernameController,
                        label: 'Username',
                        hint: 'Enter your username',
                        icon: Icons.alternate_email,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                      
                      _buildInputField(
                        controller: locationController,
                        label: 'Location',
                        hint: 'Enter your location',
                        icon: Icons.location_on,
                      ),
                      
                      _buildInputField(
                        controller: bioController,
                        label: 'Bio',
                        hint: 'Tell us about yourself',
                        icon: Icons.info_outline,
                        maxLines: 4,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9844),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Update Profile',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _getProfileImage() {
    if (profileImagePath != null) {
      // If a new image is selected, show it from file
      return kIsWeb
          ? Image.network(
              profileImagePath!,
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            )
          : Image.file(
              File(profileImagePath!),
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            );
    } else if (existingProfilePicUrl != null && existingProfilePicUrl!.isNotEmpty) {
      // If there's an existing URL, show that image
      return Image.network(
        existingProfilePicUrl!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(
              Icons.person,
              size: 60,
              color: Colors.grey,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
    } else {
      // If no image is selected or available, show placeholder
      return const Center(
        child: Icon(
          Icons.person,
          size: 60,
          color: Colors.grey,
        ),
      );
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        validator: validator,
      ),
    );
  }
} 