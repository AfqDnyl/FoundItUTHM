import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:testnew/pages/chat_page.dart';
import 'package:testnew/pages/login_or_signup.dart';
import 'package:testnew/pages/profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login and Sign Up',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: LoginAndSignUp(),
      routes: {
        '/profile': (context) => ProfilePage(),
        '/chat': (context) => ChatPage(itemId: '', contactInfo: '', userId: ''),
      },
    );
  }
}