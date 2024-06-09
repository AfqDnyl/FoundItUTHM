import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testnew/pages/auction_chat_page.dart';
import 'dart:async';

class AuctionPage extends StatefulWidget {
  @override
  _AuctionPageState createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection('found_items')
        .where('auctionEnded', isEqualTo: true)
        .where('paymentDone', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        if (currentUser != null &&
            (currentUser!.uid == doc['winnerId'] ||
                currentUser!.uid == doc['reporterId'])) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AuctionChatPage(
                itemId: doc.id,
                contactInfo: doc['contactInfo'],
                userId: doc['userId'],
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auction'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('found_items')
            .where('claimed', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No items available for auction.'));
          } else {
            final currentTime = DateTime.now();
            final availableItems = snapshot.data!.docs.where((foundItem) {
              final timestamp = (foundItem['timestamp'] as Timestamp).toDate();
              return currentTime.isAfter(timestamp.add(Duration(minutes: 1)));
            }).toList();

            if (availableItems.isEmpty) {
              return Center(child: Text('No items available for auction.'));
            }

            return ListView.builder(
              itemCount: availableItems.length,
              itemBuilder: (context, index) {
                final foundItem = availableItems[index];
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      foundItem['itemName'],
                      style: TextStyle(color: Colors.black),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          foundItem['description'],
                          style: TextStyle(color: Colors.black),
                        ),
                        AuctionCountdownTimer(foundItem: foundItem),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('auctions')
                              .doc(foundItem.id)
                              .snapshots(),
                          builder: (context, auctionSnapshot) {
                            if (!auctionSnapshot.hasData) {
                              return Text('Highest Bid: Loading...');
                            }
                            final auctionData = auctionSnapshot.data!.data() as Map<String, dynamic>?;
                            final highestBid = auctionData != null
                                ? 'RM${auctionData['highestBid'].toInt()}'
                                : 'No bids yet';
                            return Text('Highest Bid: $highestBid');
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      final auctionStartTime = (foundItem['auctionStartTime'] as Timestamp).toDate();
                      if (DateTime.now().isAfter(auctionStartTime)) {
                        _showBidDialog(foundItem);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('The auction has not started yet. Please wait until ${auctionStartTime.toLocal()}')),
                        );
                      }
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showBidDialog(DocumentSnapshot foundItem) {
    final TextEditingController _bidController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Place Your Bid'),
          content: TextField(
            controller: _bidController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: 'Enter your bid amount (whole numbers only)'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final bidAmount = int.tryParse(_bidController.text);
                if (bidAmount == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid amount')),
                  );
                  return;
                }

                if (user != null && user.uid == foundItem['userId']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('You cannot bid on your own item')),
                  );
                  return;
                }

                final auctionDoc = FirebaseFirestore.instance
                    .collection('auctions')
                    .doc(foundItem.id);
                final auctionSnapshot = await auctionDoc.get();
                if (!auctionSnapshot.exists) {
                  await auctionDoc.set({
                    'highestBid': bidAmount,
                    'highestBidder': user!.uid,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                } else {
                  final auctionData = auctionSnapshot.data() as Map<String, dynamic>;
                  final highestBid = auctionData['highestBid'];
                  if (bidAmount > highestBid) {
                    await auctionDoc.update({
                      'highestBid': bidAmount,
                      'highestBidder': user!.uid,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Your bid must be higher than the current highest bid')),
                    );
                    return;
                  }
                }

                Navigator.of(context).pop();
              },
              child: Text('Place Bid'),
            ),
          ],
        );
      },
    );
  }
}

class AuctionCountdownTimer extends StatefulWidget {
  final DocumentSnapshot foundItem;

  AuctionCountdownTimer({required this.foundItem});

  @override
  _AuctionCountdownTimerState createState() => _AuctionCountdownTimerState();
}

class _AuctionCountdownTimerState extends State<AuctionCountdownTimer> {
  late DateTime auctionEndTime;
  late Duration remainingTime;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    final auctionStartTime = (widget.foundItem['auctionStartTime'] as Timestamp).toDate();
    auctionEndTime = auctionStartTime.add(Duration(minutes: 1));
    remainingTime = auctionEndTime.difference(DateTime.now());

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        remainingTime = auctionEndTime.difference(DateTime.now());
        if (remainingTime.isNegative) {
          _timer.cancel();
          _declareWinner(widget.foundItem);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (remainingTime.isNegative) {
      return Text('Auction Ended. If you put any amount of bid you will be the winner automatically!');
    }
    return Text('Time left: ${remainingTime.inMinutes}:${(remainingTime.inSeconds % 60).toString().padLeft(2, '0')}');
  }

  void _declareWinner(DocumentSnapshot foundItem) async {
    final auctionDoc = FirebaseFirestore.instance.collection('auctions').doc(foundItem.id);
    final auctionSnapshot = await auctionDoc.get();
    if (auctionSnapshot.exists) {
      final auctionData = auctionSnapshot.data() as Map<String, dynamic>;
      final highestBidder = auctionData['highestBidder'];
      final reporterId = foundItem['userId'];

      // Update the claimed status for the found item and notify the winner and the reporter
      await FirebaseFirestore.instance.collection('found_items').doc(foundItem.id).update({
        'claimed': true,
        'auctionEnded': true,
        'winnerId': highestBidder,
        'reporterId': reporterId,
        'paymentDone': false,
      });
    }
  }
}