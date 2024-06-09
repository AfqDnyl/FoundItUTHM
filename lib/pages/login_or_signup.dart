import 'package:flutter/material.dart';
import 'login_page.dart';
import 'register_page.dart';

class LoginAndSignUp extends StatefulWidget {
  @override
  _LoginAndSignUpState createState() => _LoginAndSignUpState();
}

class _LoginAndSignUpState extends State<LoginAndSignUp> {
  bool isLogin = true;

  void togglePage() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLogin
        ? LoginPage(onPressed: togglePage)
        : RegisterPage(onPressed: togglePage);
  }
}