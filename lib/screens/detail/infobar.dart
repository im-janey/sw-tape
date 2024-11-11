import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // url_launcher import

class InfoPage extends StatefulWidget {
  final String contentId;
  final String contentTypeId;

  const InfoPage({
    super.key,
    required this.contentId,
    required this.contentTypeId,
  });

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  Map<String, dynamic>? _contentDetails;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchContentDetails();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _fetchContentDetails() async {
    try {
      final commonResponse = await http.get(
        Uri.parse(
          'http://apis.data.go.kr/B551011/KorWithService1/detailCommon1?serviceKey=K%2Bwrqt0w3kcqkpq5TzBHI8P37Kfk50Rlz1dYzc62tM2ltmIBDY3VG4eiblr%2FQbjw1JSXZYsFQBw4IieHP9cP9g%3D%3D&MobileOS=ETC&MobileApp=AppTest&contentId=${widget.contentId}&contentTypeId=${widget.contentTypeId}&defaultYN=Y&firstImageYN=Y&areacodeYN=Y&catcodeYN=Y&addrinfoYN=Y&mapinfoYN=Y&overviewYN=Y&_type=json',
        ),
        headers: {
          'Accept': 'application/json',
        },
      );

      final introResponse = await http.get(
        Uri.parse(
          'http://apis.data.go.kr/B551011/KorWithService1/detailIntro1?serviceKey=K%2Bwrqt0w3kcqkpq5TzBHI8P37Kfk50Rlz1dYzc62tM2ltmIBDY3VG4eiblr%2FQbjw1JSXZYsFQBw4IieHP9cP9g%3D%3D&MobileOS=ETC&MobileApp=AppTest&contentId=${widget.contentId}&contentTypeId=${widget.contentTypeId}&_type=json',
        ),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (commonResponse.statusCode == 200 && introResponse.statusCode == 200) {
        final commonData = json.decode(utf8.decode(commonResponse.bodyBytes));
        final introData = json.decode(utf8.decode(introResponse.bodyBytes));

        var commonItems = commonData['response']?['body']?['items']?['item'];
        var introItems = introData['response']?['body']?['items']?['item'];

        if (commonItems == null || commonItems.isEmpty) {
          setState(() {
            _hasError = true;
            _contentDetails = null;
          });
          return;
        }

        if (introItems == null || introItems.isEmpty) {
          setState(() {
            _hasError = true;
            _contentDetails = null;
          });
          return;
        }

        var commonItem = commonItems[0];
        var introItem = introItems[0];

        setState(() {
          _contentDetails = {
            if (introItem.containsKey('opentimefood'))
              'opentimefood': introItem['opentimefood'],
            if (introItem.containsKey('usetimeculture'))
              'usetimeculture': introItem['usetimeculture'],
            if (commonItem.containsKey('seat')) 'seat': commonItem['seat'],
            if (introItem.containsKey('tel')) 'tel': introItem['tel'],
            if (introItem.containsKey('infocenterculture'))
              'infocenterculture': introItem['infocenterculture'],
            if (introItem.containsKey('parkingfood'))
              'parkingfood': introItem['parkingfood'],
            if (introItem.containsKey('parking'))
              'parking': introItem['parking'],
            if (introItem.containsKey('parkingculture'))
              'parkingculture': introItem['parkingculture'],
            if (commonItem.containsKey('overview'))
              'overview': commonItem['overview'],
            if (commonItem.containsKey('addr1')) 'addr1': commonItem['addr1'],
            if (commonItem.containsKey('homepage'))
              'homepage': removeHtmlTags(commonItem['homepage']),
            if (introItem.containsKey('infocenterfood'))
              'infocenterfood': introItem['infocenterfood'],
            if (introItem.containsKey('infocenter'))
              'infocenter': introItem['infocenter'],
            if (introItem.containsKey('infocentershopping'))
              'infocentershopping': introItem['infocentershopping'],
            if (introItem.containsKey('parkingshopping'))
              'parkingshopping': introItem['parkingshopping'],
            if (introItem.containsKey('opentime'))
              'opentime': introItem['opentime'],
          };
        });
      } else {
        setState(() {
          _hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  String removeHtmlTags(String htmlString) {
    final document = parse(htmlString);
    return parse(document.body!.text).documentElement!.text;
  }

  @override
  Widget build(BuildContext context) {
    if (_contentDetails == null) {
      return Center(
        child: _hasError
            ? Text('데이터를 불러오는 중 문제가 발생했습니다.')
            : CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            icon: Icons.access_time,
            title: '영업시간',
            content: _contentDetails?['opentimefood'] ??
                _contentDetails?['usetimeculture'] ??
                _contentDetails?['restdate'] ??
                _contentDetails?['opentime'] ??
                '정보 없음',
          ),
          Divider(thickness: 0.7, color: Colors.grey),
          _buildInfoSection(
            icon: Icons.phone,
            title: '대표전화',
            content: _contentDetails?['infocenterfood'] ??
                _contentDetails?['infocenterculture'] ??
                _contentDetails?['infocenter'] ??
                _contentDetails?['infocentershopping'] ??
                '정보 없음',
          ),
          Divider(thickness: 0.7, color: Colors.grey),
          _buildInfoSection(
            icon: Icons.event_seat,
            title: '기본정보',
            content: _contentDetails?['overview'] ?? '정보 없음',
          ),
          Divider(thickness: 0.7, color: Colors.grey),
          _buildHomepageSection(),
          Divider(thickness: 0.7, color: Colors.grey),
          _buildInfoSection(
            icon: Icons.local_parking,
            title: '주차 정보',
            content: _contentDetails?['parkingfood'] ??
                _contentDetails?['parking'] ??
                _contentDetails?['parkingculture'] ??
                _contentDetails?['parkingshopping'] ??
                '정보없음',
          ),
        ],
      ),
    );
  }

  Widget _buildHomepageSection() {
    final homepage = _contentDetails?['homepage'];
    if (homepage == null || homepage.isEmpty) {
      return _buildInfoSection(
        icon: Icons.home,
        title: '홈페이지',
        content: '정보 없음',
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(23.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home),
                SizedBox(width: 8),
                Text('홈페이지', style: TextStyle(fontSize: 15)),
              ],
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                await _launchUrl(homepage);
              },
              child: Text(
                homepage,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.all(23.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 15)),
            ],
          ),
          SizedBox(height: 12),
          Text(content),
        ],
      ),
    );
  }
}
