import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();


  final ImagePicker _picker = ImagePicker();

  XFile? _pickedFile;
  Uint8List? _imageBytes;
  String? _base64Image;

  double _rating = 3.0;

  bool _isUploading = false;

  String _selectedCategory = "Beaches";

  final List<String> categories = [
    "Beaches",
    "Mountains",
    "Culinary",
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Sumber Gambar'),
        content: const Text(
          'Silakan pilih gambar dari kamera atau galeri.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Kamera'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Galeri'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 20,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _pickedFile = pickedFile;
        _imageBytes = bytes;
      });

      await _compressAndEncodeImage();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
        ),
      );
    }
  }

  Future<void> _compressAndEncodeImage() async {
    if (_pickedFile == null || _imageBytes == null) return;

    try {
      if (kIsWeb) {
        _base64Image = base64Encode(_imageBytes!);
      } else {
        final compressedImage =
            await FlutterImageCompress.compressWithFile(
          _pickedFile!.path,
          quality: 50,
        );

        if (compressedImage == null) return;

        _base64Image = base64Encode(compressedImage);
      }

      setState(() {});
    } catch (e) {
      debugPrint('Compress Error: $e');
    }
  }

  Future<void> _submitPost() async {
    if (_base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih foto wisata'),
        ),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field wajib diisi'),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final fullName =
          userDoc.data()?['fullName'] ?? 'Anonymous';

      await FirebaseFirestore.instance
          .collection('posts')
          .add({
        'userId': uid,
        'fullName': fullName,
        'title': _titleController.text.trim(),
        'locationName': _locationController.text.trim(),
        'description':
            _descriptionController.text.trim(),
        'rating': _rating,
        'category': _selectedCategory,
        'image': _base64Image,
        'createdAt': Timestamp.now(),
      });


      if (!mounted) return;

        _titleController.clear();
        _locationController.clear();
        _descriptionController.clear();


        setState(() {
          _pickedFile = null;
          _imageBytes = null;
          _base64Image = null;
          _rating = _rating;
          _selectedCategory = "Beaches";
        });


        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Postingan berhasil ditambahkan',
            ),
          ),
        );


    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal upload: $e'),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: _imageBytes != null
            ? ClipRRect(
                borderRadius:
                    BorderRadius.circular(20),
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : const Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tambah Foto Wisata',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Wisata'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImagePicker(),

            const SizedBox(height: 20),

            _buildTextField(
              controller: _titleController,
              label: 'Nama Tempat Wisata',
            ),

            const SizedBox(height: 16),

            _buildTextField(
              controller: _locationController,
              label: 'Lokasi Wisata',
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Kategori',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Rating',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium,
              ),
            ),

            const SizedBox(height: 10),

            RatingBar.builder(
              initialRating: 3,
              minRating: 1,
              allowHalfRating: true,
              itemCount: 5,
              itemBuilder: (context, _) =>
                  const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                _rating = rating;
              },
            ),

            const SizedBox(height: 20),

            _buildTextField(
              controller: _descriptionController,
              label: 'Deskripsi Pengalaman',
              maxLines: 5,
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed:
                    _isUploading ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.blue.shade700,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'POSTING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}