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

class ViewFoundItemsPage extends StatefulWidget {
  @override
  _ViewFoundItemsPageState createState() => _ViewFoundItemsPageState();
}

class _ViewFoundItemsPageState extends State<ViewFoundItemsPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactInfoController = TextEditingController();
  String _itemType = 'All';
  String _location = 'All';
  String _postOwner = 'All';
  File? _image;
  final picker = ImagePicker();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  List<String> itemTypes = ['All', 'Gadgets', 'Personal Items', 'Travel Items', 'Others', 'Documents', 'Clothing',
    'Accessories', 'Bags', 'Electronics', 'Sports Equipment', 'Books', 'Keys', 'Stationery', 'Toys'];

  List<String> locations = ['All', 'DEWAN SULTAN IBRAHIM', 'MASJID SULTAN IBRAHIM', 'PERPUSTAKAAN TUN AMINAH',
    'FSKTM', 'FPTP', 'FPTV', 'FKAAB', 'FKEE', 'TASIK AREA', 'DEWAN F2',
    'PUSAT KESIHATAN UNIVERSITI', 'G3', 'B1', 'B7', 'B6', 'B8', 'C12', 'C11',
    'STADIUM', 'PADANG KAWAD', 'ATM UTHM', 'DEWAN PENYU', 'BADMINTON COURT',
    'KOLEJ TUN SYED NASIR', 'KOLEJ TUN FATIMAH', 'KOLEJ TUN DR ISMAIL'];

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
            Reference storageRef = FirebaseStorage.instance.ref().child('found_items/$fileName');
            UploadTask uploadTask = storageRef.putFile(_image!);
            TaskSnapshot storageTaskSnapshot = await uploadTask;
            downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
          }

          await FirebaseFirestore.instance.collection('found_items').doc(itemId).update({
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
    await FirebaseFirestore.instance.collection('found_items').doc(itemId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item deleted successfully!')));
  }

  Future<void> _confirmDeleteItem(String itemId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Item"),
          content: Text("Are you sure you want to delete this item?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteItem(itemId);
                Navigator.of(context).pop();
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAsClaimed(String itemId) async {
    await FirebaseFirestore.instance.collection('found_items').doc(itemId).update({'claimed': true});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item marked as claimed')));
  }

  Future<void> _confirmMarkAsClaimed(String itemId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Mark as Claimed"),
          content: Text("Are you sure you want to mark this item as claimed?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _markAsClaimed(itemId);
                Navigator.of(context).pop();
              },
              child: Text("Mark as Claimed"),
            ),
          ],
        );
      },
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
                        items: itemTypes.map<DropdownMenuItem<String>>((String value) {
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
      appBar: commonAppBar(context, 'Found Items'), // Use the common app bar
      body: CommonBackground(
        child: Column(
          children: [
            _buildSearchAndFilters(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('found_items').where('claimed', isEqualTo: false).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No found items reported.'));
                  } else {
                    final foundItems = _applyFilters(snapshot.data!.docs);
                    return ListView.builder(
                      itemCount: foundItems.length,
                      itemBuilder: (context, index) {
                        final item = foundItems[index];
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
                                      Text('Location: ${data['foundLocation']}'),
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
                                              onPressed: () => _confirmDeleteItem(item.id),
                                            ),
                                          if (isOwner)
                                            IconButton(
                                              icon: Icon(Icons.check),
                                              onPressed: () => _confirmMarkAsClaimed(item.id),
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
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
            value: _location,
            items: locations.map((location) => DropdownMenuItem(
              value: location,
              child: Text(location),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _location = value!;
              });
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Item Type',
              border: OutlineInputBorder(),
            ),
            value: _itemType,
            items: itemTypes.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _itemType = value!;
              });
            },
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Post Owner',
              border: OutlineInputBorder(),
            ),
            value: _postOwner,
            items: ['All', 'Own Post', 'Not Own'].map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _postOwner = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  List<DocumentSnapshot> _applyFilters(List<DocumentSnapshot> items) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return items.where((item) {
      final itemData = item.data() as Map<String, dynamic>?;
      if (itemData == null) return false;

      final location = itemData['foundLocation'] ?? '';
      final itemType = itemData['itemType'] ?? '';
      final postOwner = itemData['userId'] ?? '';
      final itemName = itemData['itemName'] ?? '';
      final description = itemData['description'] ?? '';

      final matchesSearch = itemName.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          description.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesLocation = _location == 'All' || location == _location;
      final matchesItemType = _itemType == 'All' || itemType == _itemType;
      final matchesPostOwner = _postOwner == 'All' ||
          (_postOwner == 'Own Post' && postOwner == currentUser?.uid) ||
          (_postOwner == 'Not Own' && postOwner != currentUser?.uid);

      return matchesSearch && matchesLocation && matchesItemType && matchesPostOwner;
    }).toList();
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