import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ReviewList extends StatelessWidget {
  final String collectionName;
  final String id;

  const ReviewList({super.key, required this.collectionName, required this.id});

  Future<Map<String, String>> _getUserInfo(String userId) async {
    var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    String imageUrl = userDoc.exists ? userDoc['image'] ?? '' : '';

    imageUrl = await _getDownloadUrl(imageUrl);

    return {
      'name': userDoc.exists ? userDoc['nickname'] ?? '익명' : '익명',
      'imageUrl': imageUrl,
    };
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .doc(id)
          .collection('ratings')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('오류가 발생했습니다'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) =>
              _buildReviewItem(snapshot.data!.docs[index]),
        );
      },
    );
  }

  Widget _buildReviewItem(DocumentSnapshot doc) {
    var reviewData = doc.data() as Map<String, dynamic>?;
    if (reviewData == null) return ListTile(title: Text('리뷰 데이터를 불러올 수 없습니다.'));

    return FutureBuilder<Map<String, String>>(
      future: _getUserInfo(reviewData['userId']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(title: Text('로딩 중...'));
        }
        if (snapshot.hasError) return ListTile(title: Text('오류 발생'));

        String userName = snapshot.data?['name'] ?? '익명';
        String userImageUrl = snapshot.data?['imageUrl'] ?? '';
        String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

        return Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundImage: userImageUrl.isNotEmpty
                        ? NetworkImage(userImageUrl)
                        : null,
                    child: userImageUrl.isEmpty ? Icon(Icons.person) : null,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      userName,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  if (reviewData['userId'] == currentUserId)
                    IconButton(
                      onPressed: () async {
                        await doc.reference.delete();
                      },
                      icon: Icon(Icons.delete_outline),
                    ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  _buildRatingStars(reviewData),
                  _buildRatingDetails(reviewData),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(reviewData['review'] ?? '리뷰 내용 없음'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingStars(Map<String, dynamic> reviewData) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < (reviewData['총별점'] ?? 0) ? Icons.star : Icons.star_border,
          color: Color(0xFF17BABE),
          size: 20,
        );
      }),
    );
  }

  Widget _buildRatingDetails(Map<String, dynamic> reviewData) {
    return Wrap(
      children: reviewData.entries
          .where((e) => ![
                'userId',
                'review',
                'timestamp',
                '총별점',
                'parentCollection'
              ].contains(e.key))
          .map((e) => Container(
                constraints: BoxConstraints(maxWidth: 70),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${e.key}: ${e.value}',
                  style: TextStyle(fontSize: 14),
                ),
              ))
          .toList(),
    );
  }
}
