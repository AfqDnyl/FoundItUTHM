import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

AppBar commonAppBar(BuildContext context, String title, {List<Widget>? actions}) {
  return AppBar(
    title: Row(
      children: [
        Image.asset(
          'lib/assets/lost_found_new_logo.png',
          height: 40,
        ),
        SizedBox(width: 10),
        Text(title),
      ],
    ),
    actions: actions,
  );
}

AppBar commonAppBarWithAddButton(BuildContext context, String title, User? user, {VoidCallback? onAddPressed}) {
  return AppBar(
    title: Row(
      children: [
        Image.asset(
          'lib/assets/lost_found_new_logo.png',
          height: 40,
        ),
        SizedBox(width: 10),
        Text(title),
      ],
    ),
    actions: user != null && user.email == 'afiq@admin.com' && onAddPressed != null
        ? [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: onAddPressed,
            ),
          ]
        : null,
  );
}