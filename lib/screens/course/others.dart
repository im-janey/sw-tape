import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/course/showcos.dart';

class OtherCos extends StatefulWidget {
  const OtherCos({super.key});

  @override
  _CosState createState() => _CosState();
}

class _CosState extends State<OtherCos> {
  final TextEditingController _textController = TextEditingController();
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> myCourses = [];
  List<String> image = [];

  @override
  void initState() {
    super.initState();
    _frtchOtherCos();
    _fetchImageUrls();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fetchImageUrls() async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('cos')
          .doc('nkyzZSsn3eM9in57kiXr')
          .get();

      setState(() {
        image = List<String>.from(docSnapshot.data()?['random'] ?? []);
      });

      print('Fetched image URLs: $image');
    } catch (e) {
      print('Error fetching image URLs: $e');
    }
  }

  String _getImageUrl(int index) {
    if (image.isNotEmpty && index < image.length) {
      return image[index];
    }
    return 'https://via.placeholder.com/150.png';
  }

  Future<void> _frtchOtherCos() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('my cos')
          .where('uid', isNotEqualTo: userId)
          .get();

      final courses = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'cosname': doc.data()['cosname'] ?? '제목 없음',
          'timestamp': doc.data()['timestamp']?.toDate() ?? DateTime.now(),
          'selectedplace': doc.data()['selectedplace'] ?? [],
        };
      }).toList();

      setState(() {
        myCourses = courses;
      });
    } catch (e) {
      print('Error fetching courses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: myCourses.isEmpty
          ? const Center(child: Text('저장된 코스가 없습니다.'))
          : ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: myCourses.length,
              itemBuilder: (context, index) {
                final course = myCourses[index];
                return _buildCourseTile(
                  imageUrl: _getImageUrl(index),
                  title: course['cosname'],
                  subtitle:
                      '${course['timestamp'].year}.${course['timestamp'].month}.${course['timestamp'].day}',
                  id: course['id'],
                );
              },
            ),
    );
  }

  Widget _buildCourseTile({
    required String imageUrl,
    required String title,
    required String subtitle,
    required String id,
  }) {
    return InkWell(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Showcos(
                    docId: id,
                  )),
        );
      },
    );
  }
}
