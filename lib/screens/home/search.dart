import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/detail/detailpage.dart';
import 'package:http/http.dart' as http;

class Search extends StatelessWidget {
  final String? initialQuery;

  Search({super.key, this.initialQuery});

  Future<List<dynamic>> _searchWord(String query) async {
    final keyword = Uri.encodeQueryComponent(query);
    final url = Uri.parse(
        'http://apis.data.go.kr/B551011/KorWithService1/searchKeyword1'
        '?serviceKey=K%2Bwrqt0w3kcqkpq5TzBHI8P37Kfk50Rlz1dYzc62tM2ltmIBDY3VG4eiblr%2FQbjw1JSXZYsFQBw4IieHP9cP9g%3D%3D'
        '&MobileOS=ETC'
        '&MobileApp=AppTest'
        '&keyword=$keyword'
        '&numOfRows=20'
        '&pageNo=1'
        '&_type=json');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decodedResponse = utf8.decode(response.bodyBytes);
      final data = json.decode(decodedResponse);

      final items = data['response']?['body']?['items']?['item'];
      if (items != null && items is List) {
        return items
            .where((item) =>
                item['firstimage'] != null && item['firstimage'].isNotEmpty)
            .toList();
      } else {
        return [];
      }
    } else {
      throw Exception('검색에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("검색")),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: FutureBuilder<List<dynamic>>(
          future: _searchWord(initialQuery ?? ""),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('에러가 발생했습니다: ${snapshot.error}'));
            } else if (snapshot.hasData && snapshot.data!.isEmpty) {
              return Center(child: Text('검색 결과가 없습니다.'));
            } else if (snapshot.hasData) {
              final results = snapshot.data!;
              return ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final facility = results[index];
                  final imageUrl = facility['firstimage'] ?? '';
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            collectionName: 'restaurant',
                            name: facility['title'] ?? '이름 없음',
                            address: facility['addr1'] ?? '주소 없음',
                            subname: '',
                            id: facility['contentid'].toString(),
                          ),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: imageUrl.isNotEmpty
                          ? Image.network(imageUrl,
                              width: 50, height: 50, fit: BoxFit.cover)
                          : Icon(Icons.image_not_supported, size: 50),
                      title: Text(facility['title'] ?? '이름 없음'),
                      subtitle: Text(facility['addr1'] ?? '주소 없음'),
                    ),
                  );
                },
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}
