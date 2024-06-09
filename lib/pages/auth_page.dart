import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testnew/pages/login_page.dart';
import 'package:testnew/pages/dashboard_user.dart';
import 'package:testnew/pages/dashboard_admin.dart';

class AuthPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (user.email == 'afiq@admin.com') {
            return DashboardAdmin();
          } else {
            return DashboardUser();
          }
        }
        return LoginPage(onPressed: () {  },);
      },
    );
  }
}