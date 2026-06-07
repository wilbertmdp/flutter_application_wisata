import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_wisata/screens/detail_screen.dart';
import 'package:flutter_application_wisata/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // Optional parameter to view external user profiles

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _targetUid;
  bool _isCurrentUser = false;

  final Color primaryBlue = const Color(0xFF1A3AFF);
  final Color accentGold = const Color(0xFFC5A059);
  final Color darkBlueText = const Color(0xFF1A237E);

  @override
  void initState() {
    super.initState();

    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null && widget.userId == null) {
      _targetUid = null;
      _isCurrentUser = false;
      return;
    }

    _targetUid = widget.userId ?? currentUid;
    _isCurrentUser = _targetUid == currentUid;
  }

  @override
  Widget build(BuildContext context) {
    if (_targetUid == null) {
      return const Scaffold(body: Center(child: Text("User belum login")));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isCurrentUser ? "PROFIL SAYA" : "PROFIL TRAVELER",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_targetUid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userSnapshot.hasError) {
            return Center(
              child: Text("Gagal memuat data profil: ${userSnapshot.error}"),
            );
          }

          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return const Center(child: Text("Data profil tidak ditemukan"));
          }

          final userData = userSnapshot.data!.data();

          if (userData == null) {
            return const Center(child: Text("Data profil kosong"));
          }

          final profileImage = _getProfileImage(userData);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [primaryBlue.withOpacity(0.8), Colors.white],
                      stops: const [0.0, 0.9],
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: kToolbarHeight + 40),

                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 6),
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
                          backgroundImage: profileImage,
                          child: profileImage == null
                              ? Icon(
                                  Icons.person_pin,
                                  size: 70,
                                  color: primaryBlue,
                                )
                              : null,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          (userData['fullName'] ?? 'Traveler')
                              .toString()
                              .toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: darkBlueText,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          (userData['bio'] ?? 'Traveler Explorer // Adventurer')
                              .toString()
                              .toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryBlue,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      if (_isCurrentUser)
                        ElevatedButton(
                          onPressed: () {
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
                        )
                      else
                        const SizedBox(height: 10),

                      const SizedBox(height: 35),

                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .where('userId', isEqualTo: _targetUid)
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
                                  (userData['email'] ?? '-')
                                      .toString()
                                      .split('.')
                                      .first,
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
                            _isCurrentUser
                                ? "POSTINGAN SAYA"
                                : "POSTINGAN TRAVELER",
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
                      ),
                    ],
                  ),
                ),
              ),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .where('userId', isEqualTo: _targetUid)
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

                  final posts = snapshot.data?.docs.toList() ?? [];

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

                  posts.sort((a, b) {
                    final aData = a.data();
                    final bData = b.data();

                    final aTime = aData['createdAt'];
                    final bTime = bData['createdAt'];

                    if (aTime is Timestamp && bTime is Timestamp) {
                      return bTime.compareTo(aTime);
                    }

                    return 0;
                  });

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
                        final data = posts[index].data();

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
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: _buildPostImage(data),
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
              fontSize: 18,
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

  ImageProvider<Object>? _getProfileImage(Map<String, dynamic> userData) {
    try {
      final profileImage = userData['profileImage'];

      if (profileImage is String && profileImage.trim().isNotEmpty) {
        return MemoryImage(base64Decode(profileImage));
      }
    } catch (e) {
      debugPrint("Error loading profile image: $e");
    }

    return null;
  }

  Widget _buildPostImage(Map<String, dynamic> data) {
    try {
      final image = data['image'];

      if (image is String && image.trim().isNotEmpty) {
        final Uint8List imageBytes = base64Decode(image);

        return Image.memory(
          imageBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _imagePlaceholder();
          },
        );
      }
    } catch (e) {
      debugPrint("Error loading post image: $e");
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Icon(Icons.broken_image, color: Colors.grey.shade500),
    );
  }
}
