import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // Color palette
  final Color primaryColor = const Color(0xFF2A2F4F); // Deep navy
  final Color secondaryColor = const Color(0xFF917FB3); // Soft purple
  final Color accentColor = const Color(0xFFE5BEEC); // Light purple
  final Color backgroundColor = const Color(0xFFFDE2F3); // Soft pink

  @override
  void initState() {
    super.initState();
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
        profileImagePath = image.path;
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
            SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: secondaryColor,
            ),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePageScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: secondaryColor,
        ),
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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
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
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: secondaryColor,
              ),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                  gradient: LinearGradient(
                                    colors: [secondaryColor, primaryColor],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _getProfileImage(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to change profile picture',
                              style: GoogleFonts.poppins(
                                color: secondaryColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
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
                      
                      Container(
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
                        child: ElevatedButton(
                          onPressed: updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(
                              'Update Profile',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
              color: Colors.white,
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          );
        },
      );
    } else {
      return const Center(
        child: Icon(
          Icons.person,
          size: 60,
          color: Colors.white,
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
        style: GoogleFonts.poppins(color: primaryColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: secondaryColor),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: secondaryColor.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: secondaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: secondaryColor.withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: secondaryColor.withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: secondaryColor),
          ),
          filled: true,
          fillColor: Colors.white,
          errorStyle: GoogleFonts.poppins(color: Colors.red),
        ),
        validator: validator,
      ),
    );
  }
} 