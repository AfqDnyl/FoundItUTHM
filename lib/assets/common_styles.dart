import 'package:flutter/material.dart';

const kPrimaryColor = Color(0xFF6F35A5);
const kPrimaryLightColor = Color(0xFFF1E6FF);

final kInputDecoration = InputDecoration(
  labelText: '',
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
  ),
);

final kElevatedButtonStyle = ElevatedButton.styleFrom(
  padding: EdgeInsets.symmetric(vertical: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
);

final kAppBarTheme = AppBarTheme(
  color: kPrimaryColor,
  elevation: 0,
);
