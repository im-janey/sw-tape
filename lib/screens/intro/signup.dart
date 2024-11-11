import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _signUp() async {
    final nickname = _nicknameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    if (nickname.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임, 이메일 및 비밀번호를 입력하세요.')),
      );
      return;
    }

    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 랜덤 이미지 선택
      QuerySnapshot randomSnapshot =
          await _firestore.collection('random').limit(1).get();
      if (randomSnapshot.docs.isNotEmpty) {
        DocumentSnapshot randomDoc = randomSnapshot.docs.first;
        List<String> imageLinks = List<String>.from(randomDoc['profile']);
        String randomImage = imageLinks[Random().nextInt(imageLinks.length)];

        // Firestore에 사용자 정보 저장 (랜덤 이미지 포함)
        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'nickname': nickname,
          'email': email,
          'image': randomImage,
          'createdAt': FieldValue.serverTimestamp(),
        });

        print("회원가입 성공: ${userCredential.user?.email}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입 성공!')),
        );

        Navigator.pop(context);
      } else {
        throw Exception('랜덤 이미지를 찾을 수 없습니다.');
      }
    } catch (e) {
      print("회원가입 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원가입 실패: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(' '),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 129),
            _buildTextField('닉네임을 입력해주세요', Icons.person, _nicknameController),
            const SizedBox(height: 16),
            _buildTextField('이메일을 입력해주세요', Icons.email, _emailController),
            const SizedBox(height: 16),
            _buildTextField('비밀번호를 입력해주세요', Icons.lock, _passwordController,
                obscureText: true),
            const SizedBox(height: 16),
            _buildTextField(
                '비밀번호를 한 번 더 입력해주세요', Icons.lock, _confirmPasswordController,
                obscureText: true),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text(
                  '회원가입',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16,
                  ),
                  children: const [
                    TextSpan(text: '이미 계정이 있으신가요? '),
                    TextSpan(
                      text: '로그인',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String labelText, IconData icon, TextEditingController controller,
      {bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[300],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        floatingLabelStyle: TextStyle(color: Theme.of(context).primaryColor),
      ),
      cursorColor: Theme.of(context).primaryColor,
    );
  }
}
