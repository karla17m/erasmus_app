import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class EventDetailsScreen extends StatefulWidget {
  final String eventId;

  const EventDetailsScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  File? _selectedImage;

  // Validare Base64
  bool isValidBase64(String base64) {
    try {
      base64Decode(base64);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Redimensionare imagine
  Future<File> resizeImage(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    final resizedImage = img.copyResize(image!, width: 800);

    final tempDir = await Directory.systemTemp.createTemp();
    final resizedFile = File('${tempDir.path}/resized_image.jpg');
    await resizedFile.writeAsBytes(img.encodeJpg(resizedImage, quality: 85));

    return resizedFile;
  }

  // Selectare imagine din galerie
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        imageFile = await resizeImage(imageFile);

        setState(() {
          _selectedImage = imageFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  // Adăugare comentariu
  Future<void> _addComment(String content) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You need to log in to comment.")),
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userName = userDoc.data()?['name'] ?? 'Anonymous';
    final profilePicture = userDoc.data()?['profilePicture'] ?? '';

    String? imageBase64;
    if (_selectedImage != null) {
      try {
        final bytes = await _selectedImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error encoding image: $e')),
        );
        return;
      }
    }

    if (content.trim().isEmpty && (imageBase64 == null || imageBase64.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comment cannot be empty.")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('comments')
          .add({
        'text': content.trim(),
        'photo': imageBase64 ?? '',
        'userId': user.uid,
        'userName': userName,
        'profilePicture': profilePicture,
        'timestamp': DateTime.now().toIso8601String(),
      });

      setState(() {
        _commentController.clear();
        _selectedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comment added successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Details'),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Event not found"));
          }

          final event = snapshot.data!;
          final String title = event['Title'] ?? 'No title';
          final String description = event['Description'] ?? 'No description';
          final String date = event['Date'] ?? 'No date';
          final String hour = event['Hour'] ?? 'No hour';
          final String location = event['Location'] ?? 'No location';
          final String organizer = event['Organizer'] ?? 'Unknown';
          final String? photoBase64 = event['Photo'];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photoBase64 != null &&
                    photoBase64.isNotEmpty &&
                    isValidBase64(photoBase64))
                  Image.memory(
                    base64Decode(photoBase64),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.image,
                      size: 100,
                      color: Colors.grey,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text('$date at $hour'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 8),
                          Text(location),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Divider(height: 32),
                      const Text(
                        "Comments",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('events')
                            .doc(widget.eventId)
                            .collection('comments')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Text("No comments yet.");
                          }

                          final comments = snapshot.data!.docs;

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment =
                              comments[index].data() as Map<String, dynamic>;
                              final userName =
                                  comment['userName'] ?? 'Anonymous';
                              final text = comment['text'] ?? '';
                              final profilePicture =
                                  comment['profilePicture'] ?? '';
                              final photo = comment['photo'] ?? '';

                              if (text.trim().isEmpty && photo.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return ListTile(
                                leading: profilePicture.isNotEmpty
                                    ? CircleAvatar(
                                  backgroundImage: MemoryImage(
                                    base64Decode(profilePicture),
                                  ),
                                )
                                    : const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(userName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (text.isNotEmpty) Text(text),
                                    if (photo.isNotEmpty &&
                                        isValidBase64(photo))
                                      Image.memory(
                                        base64Decode(photo),
                                        height: 150,
                                        fit: BoxFit.cover,
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: const InputDecoration(
                                hintText: "Add a comment...",
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.photo_library),
                            onPressed: _pickImage,
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () =>
                                _addComment(_commentController.text),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
