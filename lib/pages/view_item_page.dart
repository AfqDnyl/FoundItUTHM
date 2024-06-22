import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:testnew/assets/common_ab.dart';
import 'package:testnew/assets/common_bg.dart';
import 'item_details_page.dart';

class ViewItemsPage extends StatefulWidget {
  @override
  _ViewItemsPageState createState() => _ViewItemsPageState();
}

class _ViewItemsPageState extends State<ViewItemsPage> {
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
            Reference storageRef = FirebaseStorage.instance.ref().child('user_items/$fileName');
            UploadTask uploadTask = storageRef.putFile(_image!);
            TaskSnapshot storageTaskSnapshot = await uploadTask;
            downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
          }

          await FirebaseFirestore.instance.collection('user_items').doc(itemId).update({
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
    await FirebaseFirestore.instance.collection('user_items').doc(itemId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item deleted successfully!')));
  }

  void _confirmDeleteItem(String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Item'),
        content: Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteItem(itemId);
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11)
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter contact information';
                          }
                          if (value.length != 10 && value.length != 11) {
                            return 'Please enter a valid phone number';
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
    return Scaffold(
      appBar: commonAppBar(context, 'My Items'), // Use the common app bar
      body: CommonBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user_items')
              .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final items = snapshot.data!.docs;
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final data = item.data() as Map<String, dynamic>?;
                  final contactInfo = data?.containsKey('contactInfo') == true ? data!['contactInfo'] : 'No contact info';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailsPage(
                            itemName: data['itemName'],
                            description: data['description'],
                            imageUrl: data['imageUrl'],
                            itemId: item.id,
                            contactInfo: contactInfo,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Image.network(data!['imageUrl']),
                        title: Text(data['itemName']),
                        subtitle: Text(data['description']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () => _showEditItemDialog(item),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _confirmDeleteItem(item.id),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
      ),
    );
  }
}