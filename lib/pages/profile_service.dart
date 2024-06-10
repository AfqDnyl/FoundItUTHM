import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> uploadProfileImage(File image) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final ref = FirebaseStorage.instance.ref().child('profile_pictures').child(user.uid + '.jpg');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<void> updateProfile(String name, String phone, String? imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'name': name,
      'phone': phone,
      if (imageUrl != null) 'profilePicture': imageUrl,
    });

    if (imageUrl != null) {
      await user.updateProfile(photoURL: imageUrl);
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }
}