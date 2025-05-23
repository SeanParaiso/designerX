import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class PostArtworkScreen extends StatefulWidget {
  const PostArtworkScreen({Key? key}) : super(key: key);

  @override
  _PostArtworkScreenState createState() => _PostArtworkScreenState();
}

class _PostArtworkScreenState extends State<PostArtworkScreen> {
  final TextEditingController contentController = TextEditingController();
  String? imageUrl;
  final ImagePicker _picker = ImagePicker();
  String? username;
  bool isLoading = false;
  String? selectedCategory;

  // Color palette
  final Color primaryColor = const Color(0xFF2A2F4F); // Deep navy
  final Color secondaryColor = const Color(0xFF917FB3); // Soft purple
  final Color accentColor = const Color(0xFFE5BEEC); // Light purple
  final Color backgroundColor = const Color(0xFFFDE2F3); // Soft pink

  // Categories with icons
  final List<Map<String, dynamic>> categories = [
    {'name': 'Art', 'icon': Icons.brush},
    {'name': 'Design', 'icon': Icons.palette},
    {'name': 'Photography', 'icon': Icons.camera_alt},
    {'name': 'Digital', 'icon': Icons.computer},
    {'name': 'Traditional', 'icon': Icons.brush_outlined},
  ];

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        imageUrl = image.path;
      });
    }
  }

  Future<void> _postArtwork() async {
    if (imageUrl == null || contentController.text.trim().isEmpty || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields, select a category, and choose an image.'),
          backgroundColor: secondaryColor,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch username from tbl_artists
      final userDoc = await FirebaseFirestore.instance
          .collection('tbl_artists')
          .doc(userId)
          .get();
      final username = userDoc.data()?['username'] ?? 'Unknown';

      String fileName = 'user_uploads/$userId/${DateTime.now().millisecondsSinceEpoch}.png';

      // Upload the image
      if (kIsWeb) {
        final response = await http.get(Uri.parse(imageUrl!));
        final bytes = response.bodyBytes;
        final ref = FirebaseStorage.instance.ref(fileName);
        await ref.putData(bytes);
      } else {
        File imageFile = File(imageUrl!);
        await FirebaseStorage.instance.ref(fileName).putFile(imageFile);
      }

      // Get the download URL
      String downloadUrl = await FirebaseStorage.instance.ref(fileName).getDownloadURL();

      // Use the download URL directly to display the image
      print("Download URL: $downloadUrl"); // Log the URL for debugging

      // Save the URL in Firestore if needed
      await FirebaseFirestore.instance.collection("tbl_posts").add({
        "user_id": userId,
        "content": contentController.text.trim(),
        "image_url": downloadUrl,
        "username": username,
        "category": selectedCategory,
        "timestamp": FieldValue.serverTimestamp(),
        "likes_count": 0,
        "comments_count": 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Artwork posted successfully!'),
            backgroundColor: secondaryColor,
          ),
        );
        Navigator.pop(context);
      }

      print("Image URL: $imageUrl");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error posting artwork: $e'),
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

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = selectedCategory == category['name'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategory = category['name'];
                  });
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: isSelected ? primaryColor : secondaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category['icon'],
                        size: 32,
                        color: isSelected ? Colors.white : secondaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Post Artwork',
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (username != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Posting as @$username',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: secondaryColor,
                          ),
                        ),
                      ),
                    // Image Preview
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: imageUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 60,
                                    color: secondaryColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap to select artwork image',
                                    style: GoogleFonts.poppins(
                                      color: secondaryColor,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: kIsWeb
                                    ? Image.network(
                                        imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Text('Error loading image');
                                        },
                                      )
                                    : Image.file(
                                        File(imageUrl!),
                                        fit: BoxFit.cover,
                                      ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Category Selector
                    _buildCategorySelector(),
                    const SizedBox(height: 24),
                    
                    // Description Field
                    TextFormField(
                      controller: contentController,
                      maxLines: 4,
                      style: GoogleFonts.poppins(color: primaryColor),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: GoogleFonts.poppins(color: secondaryColor),
                        hintText: 'Tell us about your artwork...',
                        hintStyle: GoogleFonts.poppins(
                          color: secondaryColor.withOpacity(0.5),
                        ),
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
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Post Button
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
                        onPressed: _postArtwork,
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
                            'Post Artwork',
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
    );
  }
}
