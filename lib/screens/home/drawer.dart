import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/course/new.dart';
import 'package:flutter_application_1/screens/detail/Myreview.dart';
import 'package:flutter_application_1/screens/detail/favoriate.dart';
import 'package:flutter_application_1/screens/home/profile.dart';
import 'package:flutter_application_1/screens/intro/login.dart';
import 'package:flutter_application_1/screens/map/My_map.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  _CustomDrawerState createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _profileImageUrl = '';
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userData =
          await _firestore.collection('users').doc(user.uid).get();

      String imageUrl = userData['image'] ?? '';

      if (imageUrl.startsWith('gs://')) {
        final ref = FirebaseStorage.instance.refFromURL(imageUrl);
        imageUrl = await ref.getDownloadURL();
      }

      setState(() {
        _profileImageUrl = imageUrl;
        _nicknameController.text = userData['nickname'] ?? '';
      });
    }
  }

  String _convertGsUrlToHttps(String gsUrl) {
    if (!gsUrl.startsWith('gs://')) return gsUrl;

    final bucketName = gsUrl.split('/')[2];
    final filePath = gsUrl.split('/').sublist(3).join('%2F');

    return 'https://firebasestorage.googleapis.com/v0/b/$bucketName/o/$filePath?alt=media';
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 270,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 15, right: 12, top: 35),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nicknameController.text,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) => Profile()),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      '프로필 편집',
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: _profileImageUrl.isNotEmpty
                                  ? NetworkImage(
                                      _profileImageUrl.startsWith('gs://')
                                          ? _convertGsUrlToHttps(
                                              _profileImageUrl)
                                          : _profileImageUrl,
                                    )
                                  : AssetImage('assets/logo.png')
                                      as ImageProvider,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Cos(),
                            settings: RouteSettings(name: 'Cos'),
                          ),
                        ),
                        icon: const Icon(Icons.work_outline),
                      ),
                      const Text('내 코스'),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FavoritePage()),
                        ),
                        icon: const Icon(Icons.favorite_outline),
                      ),
                      const Text('찜한 장소'),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MyMap()),
                        ),
                        icon: const Icon(Icons.map_outlined),
                      ),
                      const Text('지도'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: const Text('   나의 리뷰'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Myreview()),
                );
              },
            ),
            ListTile(
              title: const Text('   최근 본 장소'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('   환경설정'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 10),
            Container(
              color: Colors.white,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LogIn()),
                    );
                  },
                  child: Text(
                    '    로그아웃',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              color: Colors.white,
              child: Image.asset('assets/Group 317.png'),
            ),
          ],
        ),
      ),
    );
  }
}
