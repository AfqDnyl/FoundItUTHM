import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:flutter/services.dart';
import 'package:testnew/assets/common_ab.dart';
import 'package:testnew/assets/common_bg.dart';

class ReportFoundPage extends StatefulWidget {
  @override
  _ReportFoundPageState createState() => _ReportFoundPageState();
}

class _ReportFoundPageState extends State<ReportFoundPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  String _itemType = 'Gadgets';
  String _location = 'DEWAN SULTAN IBRAHIM';
  File? _image;
  final picker = ImagePicker();
  bool isLoading = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text('Gallery'),
                  onTap: () async {
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    setState(() {
                      if (pickedFile != null) {
                        _image = File(pickedFile.path);
                      }
                    });
                    Navigator.of(context).pop();
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: Text('Camera'),
                  onTap: () async {
                    final pickedFile = await picker.pickImage(source: ImageSource.camera);
                    setState(() {
                      if (pickedFile != null) {
                        _image = File(pickedFile.path);
                      }
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reportFoundItem() async {
    if (_formKey.currentState!.validate()) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must upload an image to report the item')),
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
          Reference storageRef = FirebaseStorage.instance.ref().child('found_items/$fileName');
          UploadTask uploadTask = storageRef.putFile(_image!);
          TaskSnapshot storageTaskSnapshot = await uploadTask;
          String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();

          DateTime now = DateTime.now();
          DateTime auctionStartTime = now.add(Duration(minutes: 5));
          DateTime auctionEndTime = now.add(Duration(minutes: 6));

          Map<String, dynamic> foundItemData = {
            'userId': user.uid,
            'itemName': _itemNameController.text,
            'description': _descriptionController.text,
            'contactInfo': _contactInfoController.text,
            'itemType': _itemType,
            'imageUrl': downloadUrl,
            'foundLocation': _location,
            'timestamp': FieldValue.serverTimestamp(),
            'auctionStartTime': auctionStartTime,
            'auctionEndTime': auctionEndTime,
            'claimed': false,
            'paymentDone': false,
            'announcementMade': false
          };

          await FirebaseFirestore.instance.collection('found_items').add(foundItemData);

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found item reported successfully!')));
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to report found item: $e')));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _scanQRCode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });

      // Assuming the QR code contains the item ID, fetch item details from Firestore
      FirebaseFirestore.instance.collection('user_items').doc(result!.code).get().then((doc) {
        if (doc.exists) {
          setState(() {
            _itemNameController.text = doc['itemName'];
            _descriptionController.text = doc['description'];
            _contactInfoController.text = doc['contactInfo'];
            _itemType = doc['itemType'];
          });
        }
      });

      controller.dispose();
      Navigator.pop(context); // Close the QR view once the data is retrieved
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(context, 'Report Found Item'), // Use the common app bar
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
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter contact information';
                      }
                      if (value.length < 9 || value.length > 12) {
                        return 'Phone number must be between 9-12 digits';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: 'Contact Information'),
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
                  DropdownButtonFormField<String>(
                    value: _location,
                    onChanged: (String? newValue) {
                      setState(() {
                        _location = newValue!;
                      });
                    },
                    items: <String>[
                      'DEWAN SULTAN IBRAHIM', 'MASJID SULTAN IBRAHIM', 'PERPUSTAKAAN TUN AMINAH',
                      'FSKTM', 'FPTP', 'FPTV', 'FKAAB', 'FKEE', 'TASIK AREA', 'DEWAN F2',
                      'PUSAT KESIHATAN UNIVERSITI', 'G3', 'B1', 'B7', 'B6', 'B8', 'C12', 'C11',
                      'STADIUM', 'PADANG KAWAD', 'ATM UTHM', 'DEWAN PENYU', 'BADMINTON COURT',
                      'KOLEJ TUN SYED NASIR', 'KOLEJ TUN FATIMAH', 'KOLEJ TUN DR ISMAIL'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(labelText: 'Location'),
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
                  ElevatedButton(
                    onPressed: _scanQRCode,
                    child: Text('Scan QR Code'),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _reportFoundItem,
                      child: isLoading ? CircularProgressIndicator() : Text('Report Found Item'),
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