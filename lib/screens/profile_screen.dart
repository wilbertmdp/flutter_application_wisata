import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_wisata/screens/detail_screen.dart';
import 'package:flutter_application_wisata/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _uid;

  // Themed colors for the prettier design
  final Color primaryBlue = const Color(0xFF1A3AFF);
  final Color accentGold = const Color(0xFFC5A059);
  final Color darkBlueText = const Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "PROFIL",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // Upgraded to StreamBuilder for instant, reactive database updates
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError ||
              !userSnapshot.hasData ||
              !userSnapshot.data!.exists) {
            return const Center(child: Text("Gagal memuat data profil"));
          }

          final userData = userSnapshot.data!.data() as Map<String, dynamic>;

          return CustomScrollView(
            slivers: [
              // 1. BEAUTIFUL DECORATED HEADER AREA
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryBlue.withOpacity(0.8), // Top gradient
                        Colors.white, // Blends into the main content area
                      ],
                      stops: const [0.0, 0.9], // Control gradient blend
                    ),
                  ),
                  child: Column(
                    children: [
                      // Space for the transparent AppBar
                      const SizedBox(height: kToolbarHeight + 40),

                      // STYLIZED PROFILE PICTURE CONTAINER
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 6,
                          ), // Thick white border
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.blue.shade50,
                          // Safely handle profile image
                          backgroundImage: _getProfileImage(userData),
                          child: _getProfileImage(userData) == null
                              ? Icon(
                                  Icons.person_pin,
                                  size: 70,
                                  color: primaryBlue,
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // USER INFORMATION
                      Text(
                        (userData['fullName'] ?? 'Traveler').toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: darkBlueText,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        (userData['bio'] ?? 'Traveler Explorer // Adventurer')
                            .toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryBlue,
                          letterSpacing: 1.0,
                        ),
                      ),

                      const SizedBox(height: 25),

                      // MODERN ACTION BUTTON
                      ElevatedButton(
                        onPressed: () {
                          // Open the edit screen cleanly
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "EDIT PROFIL",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // 2. THEMED STATISTIK CARDS SECTION
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .where('userId', isEqualTo: _uid)
                            .snapshots(),
                        builder: (context, postSnapshot) {
                          final totalPosts = postSnapshot.hasData
                              ? postSnapshot.data!.docs.length
                              : 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatCard(
                                  totalPosts.toString(),
                                  "Postingan",
                                ),
                                _buildStatCard(
                                  userData['email']?.split('.').first ?? '-',
                                  "Akun",
                                ),
                                _buildStatCard(
                                  "Wisata",
                                  "Aplikasi",
                                  isGolden: true,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),
                      const Divider(height: 1),

                      // SECTION TITLE
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "POSTINGAN SAYA",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 10,
                        color: Colors.white,
                      ), // Gap spacer
                    ],
                  ),
                ),
              ),

              // 3. GRID LIST SECTION (Point to White Background Area)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('userId', isEqualTo: _uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              "Gagal memuat postingan: ${snapshot.error}",
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final posts = snapshot.data?.docs ?? [];

                  if (posts.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Text(
                              "Belum ada postingan",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  // CLIENT-SIDE SORTING
                  posts.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;

                    final Timestamp? aTime = aData['createdAt'] as Timestamp?;
                    final Timestamp? bTime = bData['createdAt'] as Timestamp?;

                    if (aTime == null || bTime == null) return 0;
                    return bTime.compareTo(aTime);
                  });

                  // Render the Grid
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final postId = posts[index].id;
                        final data =
                            posts[index].data() as Map<String, dynamic>;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailScreen(postId: postId, data: data),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.memory(
                                base64Decode(data['image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      }, childCount: posts.length),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // Modern Stat Card Widget Builder
  Widget _buildStatCard(String value, String label, {bool isGolden = false}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isGolden ? accentGold : primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to safely get profile image
  ImageProvider<Object>? _getProfileImage(Map<String, dynamic> userData) {
    try {
      final profileImage = userData['profileImage'];
      if (profileImage != null && profileImage.isNotEmpty) {
        return MemoryImage(base64Decode(profileImage));
      }
    } catch (e) {
      // Silently fail and show default icon
      debugPrint('Error loading profile image: $e');
    }
    return null;
  }
}
