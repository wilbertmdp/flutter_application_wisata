import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> data;

  const DetailScreen({
    super.key,
    required this.postId,
    required this.data,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final TextEditingController _commentController =
      TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _openGoogleMaps() async {
    final location =
        Uri.encodeComponent(widget.data['locationName']);

    final url =
        "https://www.google.com/maps/search/?api=1&query=$location";

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final uid =
          FirebaseAuth.instance.currentUser!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final fullName =
          userDoc.data()?['fullName'] ?? 'Anonymous';

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'userId': uid,
        'fullName': fullName,
        'comment':
            _commentController.text.trim(),
        'createdAt': Timestamp.now(),
      });

      _commentController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengirim komentar: $e',
          ),
        ),
      );
    }

    setState(() {
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.memory(
                base64Decode(data['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'],
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          data['locationName'],
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      RatingBarIndicator(
                        rating:
                            (data['rating'] as num)
                                .toDouble(),
                        itemBuilder:
                            (context, index) =>
                                const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 25,
                      ),

                      const SizedBox(width: 10),

                      Text(
                        data['rating'].toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        data['fullName'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Deskripsi",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    data['description'],
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon:
                          const Icon(Icons.map),
                      label: const Text(
                        "Buka di Google Maps",
                      ),
                      onPressed:
                          _openGoogleMaps,
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Divider(),

                  const SizedBox(height: 10),

                  const Text(
                    "Komentar",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller:
                        _commentController,
                    maxLines: 3,
                    decoration:
                        InputDecoration(
                      hintText:
                          "Tulis komentar...",
                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isSending
                              ? null
                              : _addComment,
                      child:
                          _isSending
                              ? const CircularProgressIndicator()
                              : const Text(
                                  "Kirim Komentar",
                                ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore
                        .instance
                        .collection('posts')
                        .doc(widget.postId)
                        .collection(
                          'comments',
                        )
                        .orderBy(
                          'createdAt',
                          descending: true,
                        )
                        .snapshots(),
                    builder:
                        (
                          context,
                          snapshot,
                        ) {
                          if (snapshot
                                  .connectionState ==
                              ConnectionState
                                  .waiting) {
                            return const Center(
                              child:
                                  CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot
                                  .hasData ||
                              snapshot
                                  .data!
                                  .docs
                                  .isEmpty) {
                            return const Padding(
                              padding:
                                  EdgeInsets.all(
                                20,
                              ),
                              child: Center(
                                child: Text(
                                  "Belum ada komentar",
                                ),
                              ),
                            );
                          }

                          final comments =
                              snapshot
                                  .data!
                                  .docs;

                          return ListView.builder(
                            shrinkWrap:
                                true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount:
                                comments.length,
                            itemBuilder:
                                (
                                  context,
                                  index,
                                ) {
                                  final comment =
                                      comments[index]
                                              .data()
                                          as Map<
                                            String,
                                            dynamic
                                          >;

                                  return Card(
                                    margin:
                                        const EdgeInsets.only(
                                      bottom:
                                          10,
                                    ),
                                    child: ListTile(
                                      leading:
                                          const CircleAvatar(
                                        child:
                                            Icon(
                                          Icons.person,
                                        ),
                                      ),
                                      title:
                                          Text(
                                        comment[
                                            'fullName'],
                                      ),
                                      subtitle:
                                          Text(
                                        comment[
                                            'comment'],
                                      ),
                                    ),
                                  );
                                },
                          );
                        },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}