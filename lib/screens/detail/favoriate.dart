import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/detail/detailpage.dart';
import 'package:http/http.dart' as http;

class FavoritePage extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('찜한 가게')),
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
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다.'));
          }
          if (snapshot.data?.isEmpty ?? true) {
            return Center(child: Text('찜한 가게가 없습니다.'));
          }
          List<String> favoriteContentsIds = snapshot.data!;
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchFavoriteStores(favoriteContentsIds),
            builder: (context, storeSnapshot) {
              if (storeSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (storeSnapshot.hasError) {
                return Center(child: Text('오류가 발생했습니다.'));
              }
              List<Map<String, dynamic>> stores = storeSnapshot.data ?? [];
              return Padding(
                padding: EdgeInsets.all(10.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20.0,
                    crossAxisSpacing: 10.0,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: stores.length,
                  itemBuilder: (context, index) {
                    var store = stores[index];
                    return _buildStoreCard(context, store);
                  },
                ),
              );
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
      print('Fetching data for contentId: $contentId');

      final apiUrl =
          'https://apis.data.go.kr/B551011/KorWithService1/detailCommon1?MobileOS=ios&MobileApp=sad&contentId=$contentId&defaultYN=Y&firstImageYN=Y&areacodeYN=Y&_type=json&serviceKey=$apiKey';
      try {
        final response = await http.get(Uri.parse(apiUrl));

        if (response.statusCode == 200) {
          final decodedData = json.decode(utf8.decode(response.bodyBytes));
          print('Decoded Data: $decodedData');
          var item = decodedData['response']?['body']?['items']?['item'];

          if (item is Map<String, dynamic>) {
            print(
                'Item found for contentId: $contentId, title: ${item['title']}');

            result.add({
              'contentid': contentId,
              'title': item['title'] ?? '제목 없음',
              'firstimage': item['firstimage'] ?? '',
            });
          } else if (item is List && item.isNotEmpty) {
            var firstItem = item[0];
            print(
                'First item found for contentId: $contentId, title: ${firstItem['title']}'); // 디버깅용 로그
            result.add({
              'contentid': contentId,
              'title': firstItem['title'] ?? '제목 없음',
              'firstimage': firstItem['firstimage'] ?? '',
            });
          } else {
            print('No items found for contentId: $contentId');
          }
        } else {
          print('Failed to load data. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching content details for contentId $contentId: $e');
      }
    }
    return result;
  }

  Widget _buildStoreCard(BuildContext context, Map<String, dynamic> store) {
    return Column(
      children: [
        GestureDetector(
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8.0),
                        topRight: Radius.circular(8.0),
                        bottomLeft: Radius.circular(8.0),
                        bottomRight: Radius.circular(8.0),
                      ),
                      image: store['firstimage'] != ''
                          ? DecorationImage(
                              image: NetworkImage(store['firstimage']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: store['firstimage'] == ''
                        ? Center(
                            child: Icon(Icons.store,
                                size: 100, color: Colors.grey))
                        : null,
                  ),
                ),
              ],
            ),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPage(
                  collectionName: 'restaurant',
                  name: store['title'] ?? '',
                  address: store['addr1'] ?? '',
                  subname: '',
                  id: store['contentid'].toString(),
                ),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            store['title'] ?? '제목 없음',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
