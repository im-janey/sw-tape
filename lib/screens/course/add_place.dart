import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/course/made_cos.dart';
import 'package:http/http.dart' as http;

class AddPlacePage extends StatefulWidget {
  final String id;
  final String cosName;
  final DateTime timestamp;
  const AddPlacePage({
    super.key,
    required this.id,
    required this.cosName,
    required this.timestamp,
  });

  @override
  State<AddPlacePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<AddPlacePage> {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final List<Map<String, dynamic>> selectedPlaces = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '장소 추가',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '찜한 장소',
              style: TextStyle(
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<String>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .snapshots()
            .map((snapshot) =>
                (snapshot.data()?['favorites'] as List<dynamic>? ?? [])
                    .cast<String>()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('오류가 발생했습니다.'));
          }
          if (snapshot.data?.isEmpty ?? true) {
            return const Center(child: Text('찜한 가게가 없습니다.'));
          }
          List<String> favoriteContentsIds = snapshot.data!;
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchFavoriteStores(favoriteContentsIds),
            builder: (context, storeSnapshot) {
              if (storeSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (storeSnapshot.hasError) {
                return const Center(child: Text('오류가 발생했습니다.'));
              }
              List<Map<String, dynamic>> stores = storeSnapshot.data ?? [];
              return _buildListView(context, stores);
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchFavoriteStores(
      List<String> contentIds) async {
    List<Map<String, dynamic>> result = [];
    const apiKey =
        'KM3ecfJElcRcl6wIaSFS36i2YxG6DDD53ng%2Bgt0IZGWPCDgSXvWhdyH%2BOh1Wz41b2m4LzW5kCQaOuUfbN8HNOA%3D%3D';
    for (var contentId in contentIds) {
      final apiUrl =
          'https://apis.data.go.kr/B551011/KorWithService1/detailCommon1?MobileOS=ios&MobileApp=sad&contentId=$contentId&defaultYN=Y&firstImageYN=Y&areacodeYN=Y&_type=json&serviceKey=$apiKey';
      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final decodedData = json.decode(utf8.decode(response.bodyBytes));
          var item = decodedData['response']?['body']?['items']?['item'];

          if (item is Map<String, dynamic>) {
            result.add({
              'contentid': contentId,
              'title': item['title'] ?? '제목 없음',
              'firstimage': item['firstimage'] ?? '',
            });
          } else if (item is List && item.isNotEmpty) {
            var firstItem = item[0];
            result.add({
              'contentid': contentId,
              'title': firstItem['title'] ?? '제목 없음',
              'firstimage': firstItem['firstimage'] ?? '',
            });
          }
        }
      } catch (e) {
        print('Error: $e');
      }
    }
    return result;
  }

  Widget _buildListView(
      BuildContext context, List<Map<String, dynamic>> stores) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 90.0, right: 10, left: 10),
          child: ListView.builder(
            itemCount: stores.length,
            itemBuilder: (context, index) {
              var store = stores[index];
              return ListTile(
                leading: store['firstimage'] != ''
                    ? Image.network(
                        store['firstimage'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : const Icon(Icons.store, size: 50),
                title: Text(store['title'] ?? '제목 없음'),
                trailing: SizedBox(
                  height: 35,
                  width: 70,
                  child: ElevatedButton(
                    onPressed: () => _addSelectedPlace(store),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    child: const Text('선택', style: TextStyle(fontSize: 12)),
                  ),
                ),
              );
            },
          ),
        ),
        if (selectedPlaces.isNotEmpty)
          Positioned(
            top: 0,
            left: 20,
            right: 0,
            child: Container(
              height: 80.0,
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              color: Colors.white,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: selectedPlaces.length,
                itemBuilder: (context, index) {
                  var place = selectedPlaces[index];
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Chip(
                      label: Text(
                        place['title'],
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Theme.of(context).primaryColor,
                      deleteIcon: Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onDeleted: () => _removeSelectedPlace(index),
                    ),
                  );
                },
              ),
            ),
          ),
        if (selectedPlaces.isNotEmpty)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _onCompleteSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text(
                '선택 완료',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  void _addSelectedPlace(Map<String, dynamic> store) {
    setState(() {
      if (!selectedPlaces
          .any((place) => place['contentid'] == store['contentid'])) {
        selectedPlaces.add(store);
      }
    });
  }

  void _removeSelectedPlace(int index) {
    setState(() {
      selectedPlaces.removeAt(index);
    });
  }

  void _onCompleteSelection() {
    List<String> selectedContentIds =
        selectedPlaces.map((place) => place['contentid'] as String).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MadeCosPage(
          id: widget.id,
          cosName: widget.cosName,
          timestamp: widget.timestamp,
          selectedplace: selectedContentIds,
        ),
      ),
    );
  }
}
