import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/course/others.dart';
import 'package:flutter_application_1/screens/course/showcos.dart';

import 'modal.dart';

class Cos extends StatefulWidget {
  const Cos({super.key});

  @override
  _CosState createState() => _CosState();
}

class _CosState extends State<Cos> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  List<Map<String, dynamic>> myCourses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMyCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyCourses() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('my cos')
          .where('uid', isEqualTo: userId)
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

  Future<void> _deleteCourse(String docId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('my cos')
          .doc(docId)
          .get();

      final String courseUid = docSnapshot.data()?['uid'] ?? '';

      if (courseUid == userId) {
        await FirebaseFirestore.instance
            .collection('my cos')
            .doc(docId)
            .delete();

        setState(() {
          myCourses.removeWhere((course) => course['id'] == docId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('코스가 삭제되었습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제 권한이 없습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코스 삭제에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '내 코스'),
            Tab(text: '다른 사람의 코스'),
          ],
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.black26,
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyCoursesTab(),
          _buildOtherCoursesTab(),
        ],
      ),
    );
  }

  Widget _buildMyCoursesTab() {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const SizedBox(height: 15),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: const CircleBorder(
                    side: BorderSide(
                      color: Colors.white,
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(7),
                ),
                onPressed: () {
                  _showCourseCreationModal(context);
                },
                child: const Icon(Icons.add, size: 30),
              ),
              const SizedBox(width: 20),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '내 코스 만들기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '새로운 코스를 만들고 떠나보세요',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          ' 이전 코스',
          textAlign: TextAlign.left,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 10),
        if (myCourses.isEmpty)
          const Center(child: Text('저장된 코스가 없습니다.'))
        else
          ...myCourses.map((course) {
            return CustomListTile(
              imageUrl: 'https://via.placeholder.com/150.png',
              title: course['cosname'],
              subtitle:
                  '${course['timestamp'].year}.${course['timestamp'].month}.${course['timestamp'].day}',
              onDelete: () => _deleteCourse(course['id']),
              id: course['id'],
            );
          }).toList(),
      ],
    );
  }

  Widget _buildOtherCoursesTab() {
    return const OtherCos();
  }

  void _showCourseCreationModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Modal();
      },
    );
  }
}

class CustomListTile extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String id;
  final VoidCallback onDelete;

  const CustomListTile({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.id,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(imageUrl),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: Colors.black54,
          ),
          onPressed: onDelete,
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Showcos(docId: id)),
        );
      },
    );
  }
}
