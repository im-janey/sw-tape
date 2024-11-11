import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/detail/infobar.dart';
import 'package:flutter_application_1/screens/detail/menubar.dart';
import 'package:http/http.dart' as http;

import 'reviewbar.dart';

class DetailPage extends StatefulWidget {
  final String name;
  final String address;
  final String subname;
  final String id;
  final String collectionName;

  DetailPage({
    super.key,
    required this.name,
    required this.subname,
    required this.address,
    required this.id,
    required this.collectionName,
  });

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage>
    with SingleTickerProviderStateMixin {
  late final String userId;
  final FavoriteService _favoriteService = FavoriteService();
  bool _isFavorited = false;
  late TabController _tabController;
  List<String> _images = [];
  String? _contentId;
  String? _contentTypeId;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid;
      _tabController = TabController(length: 3, vsync: this);
      _initData();
    } else {
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _initData() async {
    try {
      await Future.wait([
        _checkFavoriteStatus(),
        _fetchContentDetails(),
      ]);
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      print('Error initializing data: $e');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    List<String> favorites = await _favoriteService.getFavorite(userId);
    setState(() {
      _isFavorited = favorites.contains(widget.id);
    });
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavorited = !_isFavorited;
    });
    try {
      if (_isFavorited) {
        await _favoriteService.addFavorite(userId, widget.id);
      } else {
        await _favoriteService.removeFavorite(userId, widget.id);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      setState(() {
        _isFavorited = !_isFavorited;
      });
    }
  }

  Future<void> _fetchContentDetails() async {
    const apiKey =
        'K%2Bwrqt0w3kcqkpq5TzBHI8P37Kfk50Rlz1dYzc62tM2ltmIBDY3VG4eiblr%2FQbjw1JSXZYsFQBw4IieHP9cP9g%3D%3D';
    final apiUrl =
        'http://apis.data.go.kr/B551011/KorWithService1/searchKeyword1?serviceKey=$apiKey&MobileOS=ETC&MobileApp=AppTest&keyword=${widget.name}&numOfRows=10&pageNo=1&_type=json';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        print('Response Body: ${utf8.decode(response.bodyBytes)}');

        var items = decodedData['response']?['body']?['items']?['item'];

        if (items == null || items.isEmpty) {
          print('No items found');
          setState(() {
            _contentId = null;
            _contentTypeId = null;
            _images = [];
          });
        } else if (items is List && items.isNotEmpty) {
          var item = items[0];
          setState(() {
            _contentId = item['contentid'].toString();
            _contentTypeId = item['contenttypeid'].toString();
            _images = items
                .where((item) => item['firstimage'] != null)
                .map((item) => item['firstimage'].toString())
                .toList();
          });
        } else if (items is Map) {
          var item = items;
          setState(() {
            _contentId = item['contentid'].toString();
            _contentTypeId = item['contenttypeid'].toString();
            _images = [
              if (item['firstimage'] != null) item['firstimage'].toString()
            ];
          });
        } else {
          print('Unexpected data format');
        }
      } else {
        print('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching content details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        appBar: AppBar(
          title: Text('상세 정보'),
        ),
        body: Center(
          child: Text('데이터를 불러오는 중 문제가 발생했습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 90,
        flexibleSpace: Padding(
          padding: const EdgeInsets.all(1),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 60, top: 84),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.name,
                          style: TextStyle(
                              fontSize: 23, fontWeight: FontWeight.bold)),
                      Text(widget.address, style: TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 30.0, top: 82),
                child: GestureDetector(
                  onTap: _toggleFavorite,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite,
                          color: _isFavorited
                              ? Theme.of(context).primaryColor
                              : Colors.black12,
                          size: 26),
                      SizedBox(height: 4.0),
                      Text('찜하기',
                          style: TextStyle(
                              fontSize: 12,
                              color: _isFavorited
                                  ? Theme.of(context).primaryColor
                                  : Colors.black26)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.only(left: 25.0, top: 18.0, right: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_images.isNotEmpty)
              SizedBox(
                height: 190,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 5, left: 30),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Image.network(
                          _images[index],
                          width: 250,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 250,
                              color: Colors.grey,
                              child: Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            SizedBox(height: 28.0),
            TabBar(
              controller: _tabController,
              indicatorColor: Theme.of(context).primaryColor,
              labelColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(child: Text('리뷰', style: TextStyle(fontSize: 16))),
                Tab(child: Text('정보', style: TextStyle(fontSize: 16))),
                Tab(child: Text('메뉴', style: TextStyle(fontSize: 16))),
              ],
            ),
            Expanded(
              child: (_contentId != null && _contentTypeId != null)
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        ReviewPage(
                          collectionName: widget.collectionName,
                          id: widget.id,
                          ratingFields: LinkedHashMap<String, String>.from({
                            '총별점': '총점',
                            '출입': '휠체어 출입',
                            '좌석': '휠체어 좌석',
                            '친절': '친절도',
                          }),
                        ),
                        InfoPage(
                          contentId: _contentId!,
                          contentTypeId: _contentTypeId!,
                        ),
                        menubar(
                          collectionName: widget.collectionName,
                          id: widget.id,
                        ),
                      ],
                    )
                  : Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFavorite(String userId, String storeId) async {
    DocumentReference userRef = _firestore.collection('users').doc(userId);
    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      if (!snapshot.exists) {
        transaction.set(userRef, {
          'favorites': [storeId]
        });
      } else {
        List<dynamic> favorites =
            (snapshot.data() as Map<String, dynamic>)['favorites'] ?? [];
        if (!favorites.contains(storeId)) {
          favorites.add(storeId);
          transaction.update(userRef, {'favorites': favorites});
        }
      }
    });
  }

  Future<List<String>> getFavorite(String userId) async {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['favorites'] ?? []);
    } else {
      return [];
    }
  }

  Future<void> removeFavorite(String userId, String storeId) async {
    DocumentReference userRef = _firestore.collection('users').doc(userId);
    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userRef);
      List<dynamic> favorites =
          (snapshot.data() as Map<String, dynamic>)['favorites'] ?? [];
      favorites.remove(storeId);
      transaction.update(userRef, {'favorites': favorites});
    });
  }
}
