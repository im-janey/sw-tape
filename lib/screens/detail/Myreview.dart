import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Myreview extends StatefulWidget {
  const Myreview({super.key});

  @override
  State<Myreview> createState() => _MyreviewState();
}

class _MyreviewState extends State<Myreview> {
  final List<String> collections = [
    'cafe',
    'restaurant',
    'park',
    'display',
    'play'
  ];
  int selectedIndex = 0;
  Future<List<QueryDocumentSnapshot>>? _futureReviews;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  void _fetchReviews() {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      setState(() {
        _futureReviews = Future.value([]);
      });
      return;
    }

    final String selectedCollection = collections[selectedIndex];

    setState(() {
      _futureReviews = FirebaseFirestore.instance
          .collectionGroup('ratings')
          .where('userId', isEqualTo: currentUserId)
          .where('parentCollection', isEqualTo: selectedCollection)
          .get()
          .then((snapshot) => snapshot.docs)
          .catchError((error) {
        return [];
      });
    });
  }

  void _onChipSelected(int index) {
    setState(() {
      selectedIndex = index;
      _fetchReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(collections.length, (index) {
              return ChoiceChip(
                label: Text(_getChipLabel(index)),
                selected: selectedIndex == index,
                onSelected: (bool selected) {
                  if (selected) {
                    _onChipSelected(index);
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                selectedColor: Colors.teal[200],
                backgroundColor: Colors.teal[200],
              );
            }),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildSelectedContent(),
          ),
        ],
      ),
    );
  }

  Future<String> _getDownloadUrlIfNeeded(String url) async {
    if (url.startsWith('gs://')) {
      try {
        final ref = FirebaseStorage.instance.refFromURL(url);
        return await ref.getDownloadURL();
      } catch (e) {
        print('Failed to get download URL: $e');
        return '';
      }
    }
    return url;
  }

  Widget _buildSelectedContent() {
    if (_futureReviews == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _futureReviews,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('오류가 발생했습니다. 다시 시도해주세요.'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              '${_getChipLabel(selectedIndex)} 관련 리뷰가 없습니다.',
            ),
          );
        }

        final docs = snapshot.data!;

        return ListView(
          children: docs.map((doc) {
            final review = doc.data() as Map<String, dynamic>;
            final userId = review['userId'] ?? '';

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (userSnapshot.hasError || !userSnapshot.hasData) {
                  return Container();
                }

                final user = userSnapshot.data!.data() as Map<String, dynamic>?;
                final String profileImage = user?['image'] ?? '';
                final String nickname = user?['nickname'] ?? '이름없음';

                return FutureBuilder<String>(
                  future: _getDownloadUrlIfNeeded(profileImage),
                  builder: (context, imageSnapshot) {
                    if (imageSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final String profileImageUrl = imageSnapshot.data ?? '';
                    final Timestamp? timestamp = review['timestamp'];
                    final String formattedDate = timestamp != null
                        ? DateFormat('yy.MM.dd').format(timestamp.toDate())
                        : '날짜 없음';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      child: Card(
                        color: Colors.grey[100],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundImage: profileImageUrl.isNotEmpty
                                        ? NetworkImage(profileImageUrl)
                                        : null,
                                    child: profileImageUrl.isEmpty
                                        ? Icon(Icons.person, size: 30)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nickname,
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                  Spacer(),
                                  Row(
                                    children: List.generate(
                                      review['총별점'] ?? 0,
                                      (index) => Icon(Icons.star,
                                          color: Colors.teal[200], size: 20),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '휠체어 출입: ${review['출입'] ?? '없음'} | 휠체어 좌석: ${review['좌석'] ?? '없음'} | 친절도: ${review['친절'] ?? '없음'}',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                review['review'] ?? '리뷰 내용이 없습니다.',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  String _getChipLabel(int index) {
    switch (index) {
      case 0:
        return '카페';
      case 1:
        return '식당';
      case 2:
        return '공원';
      case 3:
        return '전시';
      case 4:
        return '공연';
      default:
        return '';
    }
  }
}
