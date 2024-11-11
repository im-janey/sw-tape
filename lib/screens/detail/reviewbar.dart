import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/detail/Rating.dart';
import 'package:flutter_application_1/screens/detail/reviewList.dart';

class ReviewPage extends StatefulWidget {
  final String collectionName;
  final String id;
  final Map<String, String> ratingFields;

  const ReviewPage({
    super.key,
    required this.collectionName,
    required this.id,
    required this.ratingFields,
  });

  @override
  _ReviewPageState createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<String> _getDownloadUrl(String imageUrl) async {
    if (imageUrl.startsWith('gs://')) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        return await ref.getDownloadURL();
      } catch (e) {
        print('Failed to get download URL: $e');
        return '';
      }
    } else {
      return imageUrl;
    }
  }

  Future<void> _loadUserProfile() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      String imageUrl = userData['image'] ?? '';
      imageUrl = await _getDownloadUrl(imageUrl);

      if (mounted) {
        setState(() => _profileImageUrl = imageUrl);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 23, left: 15, right: 10),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: _profileImageUrl.isNotEmpty
                    ? NetworkImage(_profileImageUrl)
                    : null,
                child: _profileImageUrl.isEmpty ? Icon(Icons.person) : null,
              ),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Rating(
                      collectionName: widget.collectionName,
                      id: widget.id,
                      ratingFields: widget.ratingFields,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, elevation: 0),
                child: SizedBox(
                  width: 160,
                  child: Image.asset('assets/rating1.png'),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Expanded(
            child: ReviewList(
              collectionName: widget.collectionName,
              id: widget.id,
            ),
          ),
        ],
      ),
    );
  }
}
