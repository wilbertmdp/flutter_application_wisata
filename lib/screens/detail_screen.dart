import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_wisata/screens/profile_screen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> data;

  const DetailScreen({super.key, required this.postId, required this.data});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  bool _isSending = false;

  final Color primaryBlue = const Color(0xFF1A3AFF);
  final Color accentGold = const Color(0xFFC5A059);
  final Color darkBlueText = const Color(0xFF1A237E);

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleMaps() async {
    final String location = _getLocationName();

    if (location.trim().isEmpty || location == 'Lokasi tidak tersedia') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lokasi tidak tersedia")));
      return;
    }

    final encodedLocation = Uri.encodeComponent(location);
    final uri = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$encodedLocation",
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak bisa membuka Google Maps")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal membuka Google Maps: $e")));
    }
  }

  Future<void> _addComment() async {
    final commentText = _commentController.text.trim();

    if (commentText.isEmpty) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login untuk mengirim komentar")),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final uid = currentUser.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final userData = userDoc.data();

      final fullName = userData?['fullName']?.toString() ?? 'Anonymous';
      final profileImage = userData?['profileImage']?.toString() ?? '';

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
            'userId': uid,
            'fullName': fullName,
            'profileImage': profileImage,
            'comment': commentText,
            'createdAt': Timestamp.now(),
          });

      _commentController.clear();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengirim komentar: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = _getString('title', fallback: 'Tanpa Judul');
    final String description = _getString(
      'description',
      fallback: 'Tidak ada deskripsi',
    );
    final String location = _getLocationName();
    final String userId = _getString('userId');
    final String fullName = _getString('fullName', fallback: 'Traveler');
    final double rating = _getRating();

    final Timestamp? createdAt = widget.data['createdAt'] is Timestamp
        ? widget.data['createdAt'] as Timestamp
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: primaryBlue,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(tag: widget.postId, child: _buildMainImage()),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: darkBlueText,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Icon(Icons.location_on, color: accentGold, size: 24),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (createdAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(createdAt),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: rating,
                        itemBuilder: (context, index) =>
                            const Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 26,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkBlueText,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  if (userId.isNotEmpty)
                    _buildAuthorCard(context, userId)
                  else
                    _buildSimpleAuthor(fullName),

                  const SizedBox(height: 24),

                  const Text(
                    "DESKRIPSI",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: Color(0xFF1A237E),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey.shade800,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.map),
                      label: const Text(
                        "Buka di Google Maps",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _openGoogleMaps,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Divider(),

                  const SizedBox(height: 10),

                  Text(
                    "KOMENTAR",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: darkBlueText,
                      letterSpacing: 1,
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Tulis komentar...",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: primaryBlue, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _addComment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Kirim Komentar",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildCommentsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getString(String key, {String fallback = ''}) {
    final value = widget.data[key];

    if (value == null) {
      return fallback;
    }

    return value.toString();
  }

  String _getLocationName() {
    final locationName = widget.data['locationName'];
    final location = widget.data['location'];

    if (locationName != null && locationName.toString().trim().isNotEmpty) {
      return locationName.toString();
    }

    if (location != null && location.toString().trim().isNotEmpty) {
      return location.toString();
    }

    return 'Lokasi tidak tersedia';
  }

  double _getRating() {
    final rating = widget.data['rating'];

    if (rating is num) {
      return rating.toDouble();
    }

    return 0.0;
  }

  Widget _buildMainImage() {
    try {
      final image = widget.data['image'];

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
      debugPrint("Error loading detail image: $e");
    }

    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey.shade200,
      child: Icon(Icons.broken_image, size: 70, color: Colors.grey.shade500),
    );
  }

  Widget _buildSimpleAuthor(String fullName) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.blue.shade50,
            child: Icon(Icons.person, color: primaryBlue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              fullName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkBlueText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorCard(BuildContext context, String userId) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildSimpleAuthor(
            _getString('fullName', fallback: 'Traveler'),
          );
        }

        final userData = snapshot.data!.data();

        if (userData == null) {
          return _buildSimpleAuthor(
            _getString('fullName', fallback: 'Traveler'),
          );
        }

        final String fullName = (userData['fullName'] ?? 'Traveler').toString();
        final String email = (userData['email'] ?? '').toString();
        final ImageProvider<Object>? profileImage = _getProfileImage(userData);

        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProfileScreen(userId: userId)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: profileImage,
                  child: profileImage == null
                      ? Icon(Icons.person, color: primaryBlue)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Diposting oleh",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: darkBlueText,
                        ),
                      ),
                      if (email.isNotEmpty)
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                "Gagal memuat komentar: ${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final comments = snapshot.data?.docs ?? [];

        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: Text("Belum ada komentar")),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index].data();

            final fullName = (comment['fullName'] ?? 'Anonymous').toString();
            final commentText = (comment['comment'] ?? '').toString();

            final Timestamp? createdAt = comment['createdAt'] is Timestamp
                ? comment['createdAt'] as Timestamp
                : null;

            final ImageProvider<Object>? commentProfileImage = _getProfileImage(
              comment,
            );

            return Card(
              elevation: 0,
              color: Colors.grey.shade50,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: commentProfileImage,
                  child: commentProfileImage == null
                      ? Icon(Icons.person, color: primaryBlue)
                      : null,
                ),
                title: Text(
                  fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkBlueText,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(commentText),
                    if (createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
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

  String _formatDate(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    return "$day/$month/$year";
  }
}
