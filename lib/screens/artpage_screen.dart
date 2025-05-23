import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtPageScreen extends StatefulWidget {
  const ArtPageScreen({Key? key}) : super(key: key);

  @override
  State<ArtPageScreen> createState() => _ArtPageScreenState();
}

class _ArtPageScreenState extends State<ArtPageScreen> {
  String selectedCategory = 'All';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Color palette
  final Color primaryColor = const Color(0xFF2A2F4F); // Deep navy
  final Color secondaryColor = const Color(0xFF917FB3); // Soft purple
  final Color accentColor = const Color(0xFFE5BEEC); // Light purple
  final Color backgroundColor = const Color(0xFFFDE2F3); // Soft pink

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Filter posts based on search query
  List<QueryDocumentSnapshot> filterPosts(List<QueryDocumentSnapshot> posts, String query) {
    if (query.isEmpty) return posts;
    
    query = query.toLowerCase();
    return posts.where((post) {
      final data = post.data() as Map<String, dynamic>;
      final content = (data['content'] ?? '').toString().toLowerCase();
      final username = (data['username'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();
      
      return content.contains(query) || 
             username.contains(query) || 
             category.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Explore Art',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by title, username, or category...',
                  hintStyle: GoogleFonts.poppins(
                    color: secondaryColor.withOpacity(0.5),
                  ),
                  prefixIcon: Icon(Icons.search, color: secondaryColor),
                  suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: secondaryColor),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                    : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Categories Row
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _buildCategoryChip('All', selectedCategory == 'All'),
                _buildCategoryChip('Art', selectedCategory == 'Art'),
                _buildCategoryChip('Design', selectedCategory == 'Design'),
                _buildCategoryChip('Photography', selectedCategory == 'Photography'),
                _buildCategoryChip('Digital', selectedCategory == 'Digital'),
                _buildCategoryChip('Traditional', selectedCategory == 'Traditional'),
              ],
            ),
          ),
          // Art Content Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: selectedCategory == 'All'
                  ? FirebaseFirestore.instance
                      .collection("tbl_posts")
                      .orderBy('timestamp', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection("tbl_posts")
                      .where('category', isEqualTo: selectedCategory)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
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
                        Text(
                          snapshot.error.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: secondaryColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: secondaryColor,
                    ),
                  );
                }

                var posts = snapshot.data?.docs ?? [];
                
                // Apply search filter
                if (searchQuery.isNotEmpty) {
                  posts = filterPosts(posts, searchQuery);
                }

                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.art_track_outlined, size: 60, color: secondaryColor),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'No artworks found for "$searchQuery"'
                              : selectedCategory == 'All'
                                  ? 'No artworks available'
                                  : 'No artworks in $selectedCategory category',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isNotEmpty
                              ? 'Try different search terms'
                              : selectedCategory == 'All'
                                  ? 'Be the first to share your artwork!'
                                  : 'Try a different category or share your artwork!',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index].data() as Map<String, dynamic>;
                    final imageUrl = post['image_url'] as String?;
                    final title = post['content'] as String?;
                    final username = post['username'] as String?;
                    final category = post['category'] as String?;

                    return GestureDetector(
                      onTap: () {
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          _showFullScreenImage(context, imageUrl, title ?? '', username ?? '');
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
                              ),
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
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (username != null)
                                        Expanded(
                                          child: Text(
                                            '@$username',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: secondaryColor,
                                            ),
                                          ),
                                        ),
                                      if (category != null)
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
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = label;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [secondaryColor, primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : secondaryColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl, String title, String username) {
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
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 60, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading image',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '@$username',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
