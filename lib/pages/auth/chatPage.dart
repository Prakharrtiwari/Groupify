import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groupify/pages/auth/groupSetting.dart';

class ChatPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String userName;
  final String admin;

  const ChatPage({
    Key? key,
    required this.groupId,
    required this.groupName,
    required this.userName,
    required this.admin,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  Future<List<String>> fetchAllGroupIdsFromFirestore() async {
    try {
      // Fetch all documents from 'groups' collection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        List<String> groupIds = querySnapshot.docs.map((doc) => doc.id).toList();
        print("Fetched Group IDs: $groupIds");
        return groupIds; // Return a list of group IDs
      } else {
        print("No groups found.");
        return []; // Return empty list if no groups found
      }
    } catch (e) {
      print("Error fetching group IDs: $e");
      return []; // Return empty list if there's an error
    }
  }




  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
        'sender': widget.userName,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      // Delete the message from the group
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .doc(messageId)
          .delete();

      // Get the remaining messages after deletion
      final recentMessageSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (recentMessageSnapshot.docs.isNotEmpty) {
        // If there are still messages, update the recent message and timestamp
        final recentMessageData = recentMessageSnapshot.docs.first.data() as Map<String, dynamic>;
        final recentMessage = recentMessageData['message'];
        final recentSender = recentMessageData['sender'];
        final recentTimestamp = recentMessageData['timestamp'];

        // Update the group document with the most recent message and its timestamp
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
          'recentMessage': recentMessage,
          'recentSender': recentSender,
          'recentTimestamp': recentTimestamp,  // Restore the timestamp
        });
      } else {
        // If there are no messages left, reset the recent message and timestamp
        await FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .update({
          'recentMessage': '',
          'recentSender': '',
          'recentTimestamp': Timestamp(0, 0),  // Reset the timestamp
        });
      }
    } catch (e) {
      print("Error deleting message: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
    backgroundColor: const Color.fromRGBO(17, 0, 51, 1),
    toolbarHeight: shortestSide * 0.15,
    automaticallyImplyLeading: false,
    elevation: 0,
    title: Row(
    children: [
      StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircleAvatar(
              backgroundColor: Colors.white,
              radius: shortestSide * 0.05,
              child: const CircularProgressIndicator(
                color: Color.fromRGBO(17, 0, 51, 1),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return CircleAvatar(
              backgroundColor: Colors.white,
              radius: shortestSide * 0.05,
              child: const Icon(Icons.error, color: Colors.red),
            );
          }

          final groupData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final groupIconBase64 = groupData['groupIcon'] ?? "";

          return CircleAvatar(
            radius: shortestSide * 0.05,
            backgroundImage: groupIconBase64.isNotEmpty
                ? MemoryImage(base64Decode(groupIconBase64)) // Decode Base64 to display the image
                : NetworkImage(
              'https://www.calpers.ca.gov/img/infographics/annual-performance-report/icon-talent-management.jpg',
            ) as ImageProvider,
          );
        },
      ),

      SizedBox(width: shortestSide * 0.035),
    Expanded(
    child: Text(
    widget.groupName,
    style: GoogleFonts.fredoka(
    textStyle: TextStyle(
    fontSize: shortestSide * 0.057,
    fontWeight: FontWeight.w400,
    color: Colors.white,
    ),
    ),
    overflow: TextOverflow.ellipsis,
    ),
    ),
    ],
    ),
    actions: [
    SizedBox(width: shortestSide * 0.03),
    IconButton(
    icon: Icon(Icons.settings, color: Colors.white, size: shortestSide * 0.06),
    onPressed: () async {
    // Directly navigate to the GroupSettingPage with the groupId
    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => GroupSettingPage(groupId: widget.groupId), // Pass groupId directly
    ),
    );
    },
    ),
    ],
    ),

    body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/chat.jpg', // Ensure the image is added to your project in the `assets/images` folder.
              fit: BoxFit.cover,
            ),
          ),
          // Chat Interface
          Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('groups')
                      .doc(widget.groupId)
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final messages = snapshot.data!.docs;

                    String? lastSender;

                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final messageData = messages[index].data() as Map<String, dynamic>;
                        final sender = messageData['sender'] ?? 'Unknown';
                        final message = messageData['message'] ?? '';
                        final timestamp = messageData['timestamp'] != null
                            ? (messageData['timestamp'] as Timestamp).toDate()
                            : DateTime.now();
                        final messageId = messages[index].id;



                        // Check if this is the first message in a series by this sender
                        bool isOldestMessageInSeries = true;
                        if (index < messages.length - 1) {
                          final nextMessageData =
                          messages[index + 1].data() as Map<String, dynamic>;
                          final nextSender = nextMessageData['sender'] ?? '';
                          isOldestMessageInSeries = sender != nextSender;
                        }

                        bool isCurrentUser = sender == widget.userName;

                        return Dismissible(
                          key: Key(messageId),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            _deleteMessage(messageId);
                          },
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: Column(
                            crossAxisAlignment: isCurrentUser
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              if (isOldestMessageInSeries)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: isCurrentUser
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    children: [

                                      const SizedBox(width: 8),
                                      Text(
                                        sender,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color.fromRGBO(17, 0, 51, 1), // Custom color
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                child: Align(
                                  alignment: isCurrentUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Material(
                                    color: isCurrentUser
                                        ? const Color.fromRGBO(17, 0, 51, 1)
                                        : const Color.fromRGBO(230, 234, 255, 1),
                                    borderRadius: BorderRadius.circular(10),
                                    elevation: 15,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0, vertical: 8.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              message,
                                              style: TextStyle(
                                                color: isCurrentUser
                                                    ? Colors.white
                                                    : Colors.black,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              color: isCurrentUser
                                                  ? Colors.grey[300]
                                                  : Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: shortestSide * 0.03,
                    vertical: shortestSide * 0.02),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Enter message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color.fromRGBO(230, 234, 255, 1),
                        ),
                      ),
                    ),
                    Material(
                      color: const Color.fromRGBO(17, 0, 51, 1), // Background color of the button
                      shape: const CircleBorder(),
                      elevation: 5,
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Colors.white, // Icon color
                        ),
                        onPressed: _sendMessage,
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
