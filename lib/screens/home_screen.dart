import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_wisata/screens/detail_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final List<String> categories = [
    "All",
    "Beaches",
    "Mountains",
    "Culinary",
  ];

  String selectedCategory = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  const Text(
                    "Jelajah",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // SEARCH
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search destinations...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CATEGORY
            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];

                  return Padding(
                    padding:
                        const EdgeInsets.only(left: 12),
                    child: ChoiceChip(
                      label: Text(category),
                      selected:
                          selectedCategory == category,
                      onSelected: (_) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 15),

            // POSTS
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .orderBy(
                      'createdAt',
                      descending: true,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child:
                          Text("Terjadi kesalahan"),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child:
                          CircularProgressIndicator(),
                    );
                  }

                  var posts = snapshot.data!.docs;

                  if (selectedCategory != "All") {
                    posts = posts.where((doc) {
                      final data =
                          doc.data() as Map<String, dynamic>;

                      return data['category'] ==
                          selectedCategory;
                    }).toList();
                  }

                  if (posts.isEmpty) {
                    return const Center(
                      child: Text(
                        "Belum ada postingan wisata",
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: posts.length,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    itemBuilder: (context, index) {
                      final QueryDocumentSnapshot doc =
                        posts[index];

                      final data =
                          doc.data() as Map<String, dynamic>;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DetailScreen(
                                data: data, postId: doc.id,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 20,
                          ),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey
                                    .withOpacity(
                                  0.2,
                                ),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                            child: Stack(
                              children: [
                                Image.memory(
                                  base64Decode(
                                    data['image'],
                                  ),
                                  height: 250,
                                  width:
                                      double.infinity,
                                  fit: BoxFit.cover,
                                ),

                                Container(
                                  height: 250,
                                  decoration:
                                      BoxDecoration(
                                    gradient:
                                        LinearGradient(
                                      begin:
                                          Alignment
                                              .topCenter,
                                      end:
                                          Alignment
                                              .bottomCenter,
                                      colors: [
                                        Colors
                                            .transparent,
                                        Colors.black
                                            .withOpacity(
                                          0.8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                Positioned(
                                  left: 16,
                                  bottom: 16,
                                  right: 16,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(
                                        data['title'],
                                        style:
                                            const TextStyle(
                                          color: Colors
                                              .white,
                                          fontSize:
                                              22,
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 5,
                                      ),

                                      Row(
                                        children: [
                                          const Icon(
                                            Icons
                                                .location_on,
                                            color: Colors
                                                .white,
                                            size: 18,
                                          ),
                                          Text(
                                            data[
                                                'locationName'],
                                            style:
                                                const TextStyle(
                                              color: Colors
                                                  .white,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 8,
                                      ),

                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors
                                                .amber,
                                          ),
                                          const SizedBox(
                                            width: 5,
                                          ),
                                          Text(
                                            data[
                                                    'rating']
                                                .toString(),
                                            style:
                                                const TextStyle(
                                              color: Colors
                                                  .white,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 8,
                                      ),

                                      Text(
                                        "oleh ${data['fullName']}",
                                        style:
                                            const TextStyle(
                                          color: Colors
                                              .white70,
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
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}