import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Rating extends StatefulWidget {
  final String collectionName;
  final String id;
  final Map<String, String> ratingFields;

  const Rating({
    super.key,
    required this.collectionName,
    required this.id,
    required this.ratingFields,
  });

  @override
  State<Rating> createState() => _RatingState();
}

class _RatingState extends State<Rating> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _textController = TextEditingController();
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final Map<String, int> _ratings = {};
  String _profileImageUrl = '';
  String _nickname = '';

  @override
  void initState() {
    super.initState();
    _initializeRatings();
    _loadUserProfile();
    _loadUserNickname();
  }

  void _initializeRatings() {
    widget.ratingFields.forEach((key, _) => _ratings[key] = 0);
  }

  String _convertGsUrlToHttps(String gsUrl) {
    if (!gsUrl.startsWith('gs://')) return gsUrl;

    final bucketName = gsUrl.split('/')[2];
    final filePath = gsUrl.split('/').sublist(3).join('%2F');

    return 'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/$filePath?alt=media';
  }

  Future<void> _loadUserProfile() async {
    var userData =
        await _firestore.collection('users').doc(_auth.currentUser?.uid).get();
    String imageUrl = userData['image'] ?? '';

    if (imageUrl.startsWith('gs://')) {
      imageUrl = _convertGsUrlToHttps(imageUrl);
    }

    setState(() => _profileImageUrl = imageUrl);
  }

  Future<void> _loadUserNickname() async {
    var userData =
        await _firestore.collection('users').doc(_auth.currentUser?.uid).get();
    setState(() => _nickname = userData['nickname'] ?? '');
  }

  void _submitReview() async {
    if (_ratings.values.every((rating) => rating > 0)) {
      if (await _hasAlreadyReviewed()) {
        _showSnackBar('이미 리뷰를 작성했습니다!');
        return;
      }

      Map<String, dynamic> reviewData = {
        'userId': userId,
        'review': _textController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'parentCollection': widget.collectionName,
        ..._ratings,
      };

      await _firestore
          .collection(widget.collectionName)
          .doc(widget.id)
          .collection('ratings')
          .add(reviewData);

      _showSnackBar('리뷰가 저장되었습니다!');
      _resetForm();
    } else {
      _showSnackBar('모든 항목의 별점을 선택하세요!');
    }
  }

  Future<bool> _hasAlreadyReviewed() async {
    var review = await _firestore
        .collection(widget.collectionName)
        .doc(widget.id)
        .collection('ratings')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return review.docs.isNotEmpty;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _resetForm() {
    setState(() {
      _ratings.updateAll((key, value) => 0);
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('리뷰 작성', style: TextStyle(fontSize: 18.5))),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Row(
              children: [
                _buildProfileImage(),
                SizedBox(width: 15),
                Text(_nickname,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
            SizedBox(height: 25),
            ..._buildRatingFields(),
            _buildReviewTextField(),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitReview();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
              child: Ink(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/finish.png'),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: SizedBox(
                  width: 300,
                  height: 50,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final imageUrl = _profileImageUrl.startsWith('gs://')
        ? _convertGsUrlToHttps(_profileImageUrl)
        : _profileImageUrl;

    return CircleAvatar(
      radius: 30,
      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
      child: imageUrl.isEmpty ? Icon(Icons.person) : null,
    );
  }

  List<Widget> _buildRatingFields() {
    return widget.ratingFields.entries.map((entry) {
      return Padding(
        padding: EdgeInsets.only(left: 25, right: 25),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(entry.value, style: TextStyle(fontSize: 16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) {
                      return SizedBox(
                        width: 35,
                        child: IconButton(
                          icon: Icon(
                            index < _ratings[entry.key]!
                                ? Icons.star
                                : Icons.star_border,
                            color: Theme.of(context).primaryColor,
                          ),
                          iconSize: 25,
                          onPressed: () =>
                              setState(() => _ratings[entry.key] = index + 1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildReviewTextField() {
    return Column(
      children: [
        SizedBox(height: 20),
        SizedBox(
          width: 300,
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: '이곳에 다녀온 경험을 자세히 공유해주세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide(
                    color: Theme.of(context).primaryColor, width: 1.5),
              ),
              labelStyle: TextStyle(color: Colors.grey),
            ),
            maxLines: null,
            minLines: 5,
            cursorColor: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 33),
      ],
    );
  }
}
