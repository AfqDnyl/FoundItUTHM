import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:testnew/assets/common_ab.dart';
import 'package:testnew/assets/common_bg.dart';

class AuctionChatPage extends StatefulWidget {
  final String itemId;
  final String contactInfo;
  final String userId; // This should be the owner's userId

  AuctionChatPage({required this.itemId, required this.contactInfo, required this.userId});

  @override
  _AuctionChatPageState createState() => _AuctionChatPageState();
}

class _AuctionChatPageState extends State<AuctionChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  late StreamSubscription<DocumentSnapshot> _subscription;

  @override
  void initState() {
    super.initState();
    // Listen for changes to the paymentDone field to close the AuctionChatPage page when payment is marked as done
    _subscription = FirebaseFirestore.instance
        .collection('found_items')
        .doc(widget.itemId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        if (data['paymentDone'] == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              print('Payment done detected, navigating back');
              Navigator.pop(context);
            }
          });
        }
      }
    });

    // Send congratulatory message if the current user is the owner
    if (currentUser?.uid == widget.userId) {
      _sendCongratulatoryMessage();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _sendCongratulatoryMessage() async {
    final chatDocs = await FirebaseFirestore.instance
        .collection('chats')
        .where('itemId', isEqualTo: widget.itemId)
        .get();

    bool hasSentMessage = chatDocs.docs.any((doc) => doc['messageContent'].contains('Congrats for winning the auction for'));

    if (!hasSentMessage) {
      DocumentSnapshot itemDoc = await FirebaseFirestore.instance.collection('found_items').doc(widget.itemId).get();
      String itemName = itemDoc.exists ? itemDoc['itemName'] : 'the item';

      _sendMessage('text', 'Congrats for winning the auction for $itemName! Please wait for the owner to respond to you.');
    }
  }

  Future<String> _getUserName(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc['name'];
    }
    return 'Unknown';
  }

  void _sendMessage(String messageType, String messageContent) async {
    if (messageContent.isEmpty) return;

    String senderName = currentUser?.displayName ?? 'Unknown';

    // Get the sender's name from Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    if (userDoc.exists) {
      senderName = userDoc['name'];
    }

    await FirebaseFirestore.instance.collection('chats').add({
      'itemId': widget.itemId,
      'senderId': currentUser!.uid,
      'senderName': senderName,
      'receiverId': widget.userId,
      'messageType': messageType,
      'messageContent': messageContent,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      await _uploadImage(file);
    }
  }

  Future<void> _uploadImage(File file) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageRef = FirebaseStorage.instance.ref().child('chat_images/$fileName');
    UploadTask uploadTask = storageRef.putFile(file);
    TaskSnapshot storageTaskSnapshot = await uploadTask;
    String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();

    _sendMessage('image', downloadUrl);
  }

  void _markPaymentDone(String itemId) async {
    await FirebaseFirestore.instance
        .collection('found_items')
        .doc(itemId)
        .update({'paymentDone': true});
    print('Payment marked as done in Firestore'); // Debugging line

    // Remove related auction bot announcement
    await FirebaseFirestore.instance
        .collection('announcements')
        .where('title', isEqualTo: 'Upcoming Auction for ${widget.itemId} at ${widget.itemId}')
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.delete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: commonAppBar(context, "Auction Chat"), // Use the common app bar
      body: CommonBackground(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .where('itemId', isEqualTo: widget.itemId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('Error fetching messages: ${snapshot.error}');
                    return Center(child: Text('Error fetching messages.'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No messages yet.'));
                  }

                  final messages = snapshot.data!.docs;
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message['senderId'] == currentUser!.uid;

                      return FutureBuilder<String>(
                        future: _getUserName(message['senderId']),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (userSnapshot.hasError) {
                            return Text('Error fetching user name');
                          }

                          String senderName = userSnapshot.data ?? 'Unknown';
                          String messageContent = message['messageContent'];
                          Widget messageWidget;

                          if (message['messageType'] == 'text') {
                            messageWidget = Text(messageContent);
                          } else if (message['messageType'] == 'image') {
                            messageWidget = Image.network(messageContent);
                          } else {
                            messageWidget = Text('Unsupported message type');
                          }

                          return ListTile(
                            title: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isMe ? Colors.blue : Colors.black,
                                    ),
                                  ),
                                  messageWidget,
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            if (currentUser!.uid == widget.userId) // Show the button only to the poster
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () => _markPaymentDone(widget.itemId),
                  child: Text('Payment Done'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.image),
                    onPressed: _pickImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message here...',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => _sendMessage('text', _messageController.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}