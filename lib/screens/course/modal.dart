import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/course/make_cos.dart';

class Modal extends StatefulWidget {
  const Modal({super.key});

  @override
  State<Modal> createState() => _ModalState();
}

class _ModalState extends State<Modal> {
  final TextEditingController _cosNameController = TextEditingController();

  Future<void> _saveCosName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final cosName = _cosNameController.text.trim();
      if (cosName.isNotEmpty) {
        try {
          final docRef = FirebaseFirestore.instance.collection('my cos').doc();

          await docRef.set({
            'id': docRef.id,
            'cosname': cosName,
            'uid': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });

          final docSnapshot = await docRef.get();
          final timestamp =
              docSnapshot.data()?['timestamp']?.toDate() ?? DateTime.now();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MakeCosPage(
                id: docRef.id,
                cosName: cosName,
                timestamp: timestamp,
              ),
            ),
          );
        } catch (e) {
          print('Error saving cos name: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xff5CCDD0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.flag,
            color: Colors.white,
            size: 30,
          ),
        ],
      ),
      content: TextField(
        controller: _cosNameController,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: '코스 이름을 입력하세요',
          hintStyle: const TextStyle(color: Colors.white54),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(
              color: Colors.white,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(
              color: Colors.white,
              width: 2,
            ),
          ),
        ),
        cursorColor: Colors.white,
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            '취소',
            style: TextStyle(color: Colors.black87, fontSize: 12.5),
          ),
        ),
        SizedBox(
          width: 70,
          child: ElevatedButton(
            onPressed: () {
              _saveCosName();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
            ),
            child: Text(
              '설정',
              style: TextStyle(color: Colors.black87, fontSize: 12.5),
            ),
          ),
        ),
      ],
    );
  }
}
