import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BookmarkProvider with ChangeNotifier {
  Set<String> _bookmarkedIds = {};

  Set<String> get bookmarkedIds => _bookmarkedIds;

  BookmarkProvider() {
    _initListener();
  }

  void _initListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .snapshots()
            .listen((snapshot) {
          _bookmarkedIds = snapshot.docs.map((doc) => doc.id).toSet();
          notifyListeners();
        });
      } else {
        _bookmarkedIds.clear();
        notifyListeners();
      }
    });
  }

  bool isBookmarked(String postId) {
    return _bookmarkedIds.contains(postId);
  }

  // Fungsi untuk menambah/menghapus dari Firestore
  Future<void> toggleBookmark(String postId, Map<String, dynamic> postData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // Harus login

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(postId);

    try {
      if (_bookmarkedIds.contains(postId)) {
        await docRef.delete(); // Hapus jika sudah ada
      } else {
        // Tambahkan beserta data untuk ditampilkan di SavedScreen
        await docRef.set({
          'postId': postId,
          'title': postData['title'] ?? '',
          'image': postData['image'] ?? '',
          'locationName': postData['locationName'] ?? '',
          'rating': postData['rating'] ?? 0,
          'savedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      debugPrint("Error toggle bookmark: $e");
    }
  }
}