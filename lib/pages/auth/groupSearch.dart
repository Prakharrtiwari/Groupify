import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class GroupSearchPage extends StatefulWidget {
  @override
  _GroupSearchPageState createState() => _GroupSearchPageState();
}

class _GroupSearchPageState extends State<GroupSearchPage> {
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<DocumentSnapshot> _groups = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  // Fetch groups from Firestore based on the search query
  Widget groupList() {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    String? uid = auth.currentUser?.uid;

    if (uid == null) {
      return noGroupWidget(); // Handle case where the user is not logged in
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: firestore.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching data'));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return noGroupWidget(); // Show no groups widget if there's no data
        }

        final userDoc = snapshot.data!.data() as Map<String, dynamic>?;

        // Fetch the list of groupIds the user is a part of
        final List<dynamic>? groupIds = userDoc?['groups'];

        if (groupIds == null || groupIds.isEmpty) {
          return noGroupWidget(); // Show no groups widget if user has no groups
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: fetchGroupDetailsStream(groupIds, firestore),
          builder: (context, groupSnapshot) {
            if (groupSnapshot.hasError) {
              return noGroupWidget();
            }

            if (!groupSnapshot.hasData || groupSnapshot.data!.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // If search query is empty, return noGroupWidget
            if (_searchQuery.isEmpty) {
              return noGroupWidget(); // Show no groups widget when nothing is searched
            }

            // Filter groups based on the search query
            final filteredGroups = groupSnapshot.data!
                .where((group) =>
                group['groupData']['groupName']
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()))
                .toList();

            if (filteredGroups.isEmpty) {
              return noGroupWidget(); // Show no groups if no match
            }

            // Sort by creation time
            filteredGroups.sort((a, b) {
              final createdTimeA = a['createdTime'] as Timestamp;
              final createdTimeB = b['createdTime'] as Timestamp;
              return createdTimeB.compareTo(createdTimeA);
            });

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredGroups.length,
              itemBuilder: (context, index) {
                final group = filteredGroups[index];
                final groupData = group['groupData'];
                final groupId = group['groupId'];
                final uid = FirebaseAuth.instance.currentUser?.uid;

                // Check if the user is already a member of the group
                bool isUserInGroup = groupData['members']?.contains(uid) ?? false;

                return GestureDetector(
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5.0),
                    height: shortestSide * 0.20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(230, 234, 255, 1),
                          blurRadius: 9,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(left: 20, right: 15, bottom: 10, top: 4.5),
                      title: Text(
                        groupData['groupName'] ?? 'Group Name',
                        style: GoogleFonts.fredoka(
                          textStyle: TextStyle(
                            fontSize: shortestSide * 0.042,
                            fontWeight: FontWeight.w500,
                            color: const Color.fromRGBO(17, 0, 51, 1),
                          ),
                        ),
                      ),
                      trailing: isUserInGroup
                          ? null
                          : ElevatedButton(
                        onPressed: () {
                          // Add haptic feedback
                          HapticFeedback.lightImpact();
                          // Your existing function call
                          _joinGroup(groupId, uid);
                        },
                        child: Text(
                          'Join',
                          style: GoogleFonts.fredoka(
                            textStyle: TextStyle(
                              fontSize: 16,  // Adjust font size if needed
                              fontWeight: FontWeight.w500, // Adjust weight if needed
                              color: Colors.white, // Text color for visibility
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(17, 0, 51, 1), // Button color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Rounded corners
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _joinGroup(String groupId, String? uid) {
    if (uid == null) return;

    FirebaseFirestore.instance.collection('groups').doc(groupId).update({
      'members': FieldValue.arrayUnion([uid]),
    });

    FirebaseFirestore.instance.collection('users').doc(uid).update({
      'groups': FieldValue.arrayUnion([groupId]),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You have joined the group!')),
    );
  }

  Stream<List<Map<String, dynamic>>> fetchGroupDetailsStream(
      List<dynamic> groupIds, FirebaseFirestore firestore) {
    return FirebaseFirestore.instance.collection('groups').snapshots().asyncMap((groupSnapshot) async {
      List<Map<String, dynamic>> groups = [];

      for (var groupDoc in groupSnapshot.docs) {
        final groupId = groupDoc.id;
        final groupData = groupDoc.data() as Map<String, dynamic>?;

        if (groupData != null) {
          final lastMessageQuery = await firestore
              .collection('groups')
              .doc(groupId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          String recentMessage = "Enjoy secure and private chats";
          String recentMessageSender = "Admin";
          Timestamp recentMessageTimestamp = Timestamp(0, 0);

          if (lastMessageQuery.docs.isNotEmpty) {
            final lastMessageData = lastMessageQuery.docs.first.data() as Map<String, dynamic>;
            recentMessage = lastMessageData['message'] ?? "Enjoy secure and private chats";
            recentMessageSender = lastMessageData['sender'] ?? "Admin";
            recentMessageTimestamp = lastMessageData['timestamp'] ?? Timestamp(0, 0);
          }

          groups.add({
            'groupId': groupId,
            'groupData': groupData,
            'recentMessage': recentMessage,
            'recentMessageSender': recentMessageSender,
            'createdTime': groupData['createdTime'] ?? Timestamp(0, 0),
            'recentMessageTimestamp': recentMessageTimestamp,
          });
        }
      }

      groups.sort((a, b) {
        final createdTimeA = a['createdTime'] as Timestamp;
        final createdTimeB = b['createdTime'] as Timestamp;

        if (createdTimeA == createdTimeB) {
          final recentMessageTimestampA = a['recentMessageTimestamp'] as Timestamp;
          final recentMessageTimestampB = b['recentMessageTimestamp'] as Timestamp;
          return recentMessageTimestampB.compareTo(recentMessageTimestampA);
        }

        return createdTimeB.compareTo(createdTimeA);
      });

      return groups;
    });
  }

  Widget noGroupWidget() {
    return Container(
      child: Center(
        child: Text(
          "No Groups available",
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            textStyle: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: const Color.fromRGBO(165, 150, 191, 1.0),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(17, 0, 51, 1),
        toolbarHeight: shortestSide * 0.18,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          "Search Groups",
          style: GoogleFonts.fredoka(
            textStyle: TextStyle(
              fontSize: shortestSide * 0.070,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SizedBox(height: 16), // Adds space between app bar and text field
            TextField(
              controller: _searchController,
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(
                  color: Color.fromRGBO(17, 0, 51, 1),
                ),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Color.fromRGBO(230, 234, 255, 1),
                hintText: 'Search group name',
                hintStyle: GoogleFonts.fredoka(
                  textStyle: TextStyle(
                    color: Color.fromRGBO(17, 0, 51, 1).withOpacity(0.5),
                  ),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Color.fromRGBO(17, 0, 51, 1),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(50),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            Expanded(child: groupList()),  // Display the group list
          ],
        ),
      ),
    );
  }
}
