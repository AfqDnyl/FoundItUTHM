import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:testnew/assets/common_ab.dart';
import 'package:testnew/assets/common_bg.dart';
import 'package:photo_view/photo_view.dart';

class AnnouncementPage extends StatefulWidget {
  @override
  _AnnouncementPageState createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool isLoading = false;
  late Timer _auctionTimer;

  @override
  void initState() {
    super.initState();
    _startAuctionTimer();
  }

  @override
  void dispose() {
    _auctionTimer.cancel();
    super.dispose();
  }

  Future<void> _startAuctionTimer() async {
    _auctionTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      await _fetchUpcomingAuctions();
    });
  }

  Future<void> _fetchUpcomingAuctions() async {
    final now = Timestamp.now();
    final twoMinutesLater = Timestamp.fromDate(DateTime.now().add(Duration(minutes: 2)));

    final querySnapshot = await FirebaseFirestore.instance
        .collection('found_items')
        .where('auctionStartTime', isGreaterThanOrEqualTo: now)
        .where('auctionStartTime', isLessThanOrEqualTo: twoMinutesLater)
        .where('claimed', isEqualTo: false)
        .where('announcementMade', isEqualTo: false)
        .get();

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final title = "Upcoming Auction for ${data['itemName']} at ${data['auctionStartTime'].toDate()}";
      final notes = "${data['description']}";
      final imageUrl = data.containsKey('imageUrl') ? data['imageUrl'] : null;

      await FirebaseFirestore.instance.collection('announcements').add({
        'name': 'Auction Bot',
        'title': title,
        'notes': notes,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'id': 'system',
      });

      // Mark the auction as announced
      await FirebaseFirestore.instance.collection('found_items').doc(doc.id).update({
        'announcementMade': true,
      });
    }
  }

  Future<void> _postAnnouncement(BuildContext context) async {
    if (user == null) return;

    if (_titleController.text.isEmpty || _notesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Title and notes cannot be empty!')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    String? imageUrl;
    if (_imageFile != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child('announcement_images/$fileName');
      UploadTask uploadTask = storageRef.putFile(File(_imageFile!.path));
      TaskSnapshot storageTaskSnapshot = await uploadTask;
      imageUrl = await storageTaskSnapshot.ref.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('announcements').add({
      'name': user!.displayName ?? 'Admin',
      'title': _titleController.text,
      'notes': _notesController.text,
      'imageUrl': imageUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'id': user!.uid,
    });

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Announcement posted!')));
    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  Future<void> _editAnnouncement(String id, Map<String, dynamic> currentData) async {
    _titleController.text = currentData['title'];
    _notesController.text = currentData['notes'];
    _imageFile = null; // Reset image selection

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Announcement'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                    ),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(labelText: 'Notes'),
                      maxLines: 4,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        setState(() {
                          _imageFile = pickedFile;
                        });
                      },
                      child: Text('Select Image'),
                    ),
                    _imageFile == null
                        ? currentData['imageUrl'] != null
                            ? Image.network(currentData['imageUrl'], height: 100, width: 100)
                            : Container()
                        : Image.file(File(_imageFile!.path), height: 100, width: 100),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  isLoading = true;
                });

                String? imageUrl;
                if (_imageFile != null) {
                  String fileName = DateTime.now().millisecondsSinceEpoch.toString();
                  Reference storageRef = FirebaseStorage.instance.ref().child('announcement_images/$fileName');
                  UploadTask uploadTask = storageRef.putFile(File(_imageFile!.path));
                  TaskSnapshot storageTaskSnapshot = await uploadTask;
                  imageUrl = await storageTaskSnapshot.ref.getDownloadURL();
                }

                await FirebaseFirestore.instance.collection('announcements').doc(id).update({
                  'title': _titleController.text,
                  'notes': _notesController.text,
                  if (imageUrl != null) 'imageUrl': imageUrl,
                });

                setState(() {
                  isLoading = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Announcement updated!')));
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAnnouncement(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Announcement'),
          content: Text('Are you sure you want to delete this announcement?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await FirebaseFirestore.instance.collection('announcements').doc(id).delete();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Announcement deleted!')));
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showPostAnnouncementDialog(BuildContext context) {
    _titleController.text = '';
    _notesController.text = '';
    _imageFile = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Post Announcement'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(labelText: 'Title'),
                      onChanged: (_) => setState(() {}),
                    ),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(labelText: 'Notes'),
                      maxLines: 4,
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        setState(() {
                          _imageFile = pickedFile;
                        });
                      },
                      child: Text('Select Image'),
                    ),
                    _imageFile == null
                        ? Container()
                        : Image.file(File(_imageFile!.path), height: 100, width: 100),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _titleController.text.isNotEmpty && _notesController.text.isNotEmpty
                      ? () => _postAnnouncement(context)
                      : null,
                  child: Text('Post'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _viewImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewScreen(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBarWithAddButton(
        context,
        "Announcements",
        user,
        onAddPressed: () => _showPostAnnouncementDialog(context),
      ),
      body: CommonBackground(
        child: _buildAnnouncementList(),
      ),
    );
  }

  Widget _buildAnnouncementList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return Center(child: Text('No announcements found.'));
        }

        final announcements = snapshot.data!.docs;
        return ListView.builder(
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            final data = announcement.data() as Map<String, dynamic>;
            final createdAt = data.containsKey('createdAt') ? (data['createdAt'] as Timestamp).toDate() : DateTime.now();
            final daysSincePosted = DateTime.now().difference(createdAt).inDays;
            final imageUrl = data['imageUrl'] ?? '';

            return Card(
              elevation: 4,
              margin: EdgeInsets.all(8),
              child: ListTile(
                leading: imageUrl.isNotEmpty
                    ? GestureDetector(
                        onTap: () => _viewImage(imageUrl),
                        child: Image.network(
                          imageUrl,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported, color: Colors.grey[600]),
                      ),
                title: Text(announcement['title']),
                subtitle: Text(
                  '${announcement['notes']} \nPosted by ${announcement['name']} $daysSincePosted days ago',
                ),
                trailing: user != null && user!.uid == announcement['id']
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editAnnouncement(announcement.id, data),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteAnnouncement(announcement.id),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class ImageViewScreen extends StatelessWidget {
  final String imageUrl;

  ImageViewScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
        ),
      ),
    );
  }
}