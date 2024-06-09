import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // Import for FilteringTextInputFormatter
import 'package:testnew/assets/common_ab.dart';
import 'package:testnew/assets/common_bg.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  File? _image;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile(User user) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      String? imageUrl;
      if (_image != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_pictures').child(user.uid + '.jpg');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        if (imageUrl != null) 'profilePicture': imageUrl,
      });

      if (_image != null) {
        await user.updateProfile(photoURL: imageUrl);
      }

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: commonAppBar(context, 'My Profile'), // Use the common app bar
      body: CommonBackground(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(child: Text('No profile data found'));
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            _nameController.text = userData['name'];
            _phoneController.text = userData['phone'];

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _image != null
                                ? FileImage(_image!)
                                : (user.photoURL != null ? NetworkImage(user.photoURL!) : AssetImage('lib/assets/default_profile_image.png')) as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.camera_alt),
                              onPressed: _pickImage,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12), // Set maximum length
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter contact information';
                        }
                        if (value.length < 9 || value.length > 12) {
                          return 'Please enter a valid phone number (9-12 digits)';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isLoading ? null : () => _updateProfile(user),
                      child: isLoading ? CircularProgressIndicator() : Text('Update Profile'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}