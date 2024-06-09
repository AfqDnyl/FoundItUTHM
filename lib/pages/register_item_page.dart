import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:testnew/assets/common_ab.dart';
import 'package:testnew/assets/common_bg.dart';

class RegisterItemPage extends StatefulWidget {
  @override
  _RegisterItemPageState createState() => _RegisterItemPageState();
}

class _RegisterItemPageState extends State<RegisterItemPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  String _itemType = 'Gadgets';
  File? _image;
  final picker = ImagePicker();
  bool isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _uploadItem() async {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must upload the item image to register it')),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String fileName = DateTime.now().millisecondsSinceEpoch.toString();
          Reference storageRef = FirebaseStorage.instance.ref().child('user_items/$fileName');
          UploadTask uploadTask = storageRef.putFile(_image!);
          TaskSnapshot storageTaskSnapshot = await uploadTask;
          String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();

          await FirebaseFirestore.instance.collection('user_items').add({
            'userId': user.uid,
            'itemName': _itemNameController.text,
            'description': _descriptionController.text,
            'contactInfo': _contactInfoController.text,
            'itemType': _itemType,
            'imageUrl': downloadUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item registered successfully!')));
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to register item: $e')));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter contact information';
    }
    final RegExp phoneExp = RegExp(r'^\d{9,12}$');
    if (!phoneExp.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(context, 'Register Item'),
      body: CommonBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _itemNameController,
                    validator: (value) => value!.isEmpty ? 'Please enter item name' : null,
                    decoration: InputDecoration(labelText: 'Item Name'),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    validator: (value) => value!.isEmpty ? 'Please enter description' : null,
                    decoration: InputDecoration(labelText: 'Description'),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _contactInfoController,
                    decoration: InputDecoration(labelText: 'Contact Information'),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validatePhoneNumber,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _itemType,
                    onChanged: (String? newValue) {
                      setState(() {
                        _itemType = newValue!;
                      });
                    },
                    items: <String>[
                      'Gadgets', 'Personal Items', 'Travel Items', 'Others', 'Documents', 'Clothing',
                      'Accessories', 'Bags', 'Electronics', 'Sports Equipment', 'Books', 'Keys', 'Stationery', 'Toys'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(labelText: 'Item Type'),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      _image == null
                          ? Text('No image selected.')
                          : Image.file(_image!, height: 100, width: 100),
                      Spacer(),
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: Text('Select Image'),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _uploadItem,
                      child: isLoading ? CircularProgressIndicator() : Text('Register Item'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}