import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:testnew/assets/common_ab.dart';
import 'package:testnew/assets/common_bg.dart';
import 'package:testnew/pages/chat_page.dart';

class ViewLostItemsPage extends StatefulWidget {
  @override
  _ViewLostItemsPageState createState() => _ViewLostItemsPageState();
}

class _ViewLostItemsPageState extends State<ViewLostItemsPage> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  String _itemType = 'Gadgets';
  File? _image;
  final picker = ImagePicker();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> _editItem(String itemId) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String? downloadUrl;
          if (_image != null) {
            String fileName = DateTime.now().millisecondsSinceEpoch.toString();
            Reference storageRef = FirebaseStorage.instance.ref().child('lost_items/$fileName');
            UploadTask uploadTask = storageRef.putFile(_image!);
            TaskSnapshot storageTaskSnapshot = await uploadTask;
            downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
          }

          await FirebaseFirestore.instance.collection('lost_items').doc(itemId).update({
            'itemName': _itemNameController.text,
            'description': _descriptionController.text,
            'contactInfo': _contactInfoController.text,
            'itemType': _itemType,
            if (downloadUrl != null) 'imageUrl': downloadUrl,
          });

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item updated successfully!')));
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update item: $e')));
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteItem(String itemId) async {
    await FirebaseFirestore.instance.collection('lost_items').doc(itemId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item deleted successfully!')));
  }

  void _showEditItemDialog(DocumentSnapshot item) {
    final data = item.data() as Map<String, dynamic>;

    setState(() {
      _itemNameController.text = data['itemName'];
      _descriptionController.text = data['description'];
      _contactInfoController.text = data['contactInfo'];
      _itemType = data['itemType'];
      _image = null; // Reset image selection
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Item'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _itemNameController,
                        decoration: InputDecoration(labelText: 'Item Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter item name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(labelText: 'Description'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _contactInfoController,
                        decoration: InputDecoration(labelText: 'Contact Information'),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                            onPressed: () async {
                              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                              setState(() {
                                if (pickedFile != null) {
                                  _image = File(pickedFile.path);
                                }
                              });
                            },
                            child: Text('Select Image'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _editItem(item.id),
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: commonAppBar(context, 'Lost Items'), // Use the common app bar
      body: CommonBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('lost_items').where('hasFound', isEqualTo: false).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No lost items reported.'));
            } else {
              final lostItems = snapshot.data!.docs;
              return ListView.builder(
                itemCount: lostItems.length,
                itemBuilder: (context, index) {
                  final item = lostItems[index];
                  final data = item.data() as Map<String, dynamic>?;
                  final contactInfo = data?.containsKey('contactInfo') == true ? data!['contactInfo'] : 'No contact info';
                  final isOwner = currentUser?.uid == data!['userId'];
                  final timestamp = data['timestamp'] as Timestamp?;

                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImageZoomPage(imageUrl: data['imageUrl']),
                                ),
                              );
                            },
                            child: Image.network(
                              data['imageUrl'],
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['itemName'], style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 4),
                                Text('Description: ${data['description']}'),
                                SizedBox(height: 4),
                                Text('Contact Info: $contactInfo'),
                                SizedBox(height: 4),
                                Text('Location: ${data['lastLocation']}'),
                                SizedBox(height: 4),
                                Text('Item Type: ${data['itemType']}'),
                                SizedBox(height: 4),
                                Text('Reported on: ${timestamp?.toDate().toString() ?? 'Unknown'}'),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.chat),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatPage(
                                              itemId: item.id,
                                              contactInfo: contactInfo,
                                              userId: data['userId'],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (isOwner)
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () => _showEditItemDialog(item),
                                      ),
                                    if (isOwner)
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () => _deleteItem(item.id),
                                      ),
                                    if (isOwner)
                                      IconButton(
                                        icon: Icon(Icons.check),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance.collection('lost_items').doc(item.id).update({'hasFound': true});
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item marked as found')));
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class ImageZoomPage extends StatelessWidget {
  final String imageUrl;

  ImageZoomPage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(context, 'Image Zoom'), // Use the common app bar
      body: CommonBackground(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
        ),
      ),
    );
  }
}