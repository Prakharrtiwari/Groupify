import 'dart:convert';
import 'dart:ui';
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groupify/pages/auth/chatPage.dart';
import 'package:groupify/pages/auth/groupSearch.dart';
import 'package:groupify/pages/auth/settingPage.dart';
import 'package:flutter/services.dart';

import '../helper/helper_function.dart'; // For SystemNavigator.pop()


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> _groupData = [];


  Future<void> _fetchUserDetails() async {
    try {
      // Fetch group data from Firestore
      final QuerySnapshot groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .snapshots()
          .first; // Fetch the first snapshot

      setState(() {
        // Process group data into a list
        _groupData = groupSnapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print("Error fetching group data: $e");
      setState(() {
        _groupData = []; // Fallback to an empty list on error
      });
    }
  }

  bool _isLoading = false; // Track the loading state for profile picture update
  Stream? groups;

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide; // Shortest side of the screen
    final TextEditingController _searchGroup = TextEditingController();

    // Retrieve the current user's ID from Firebase Authentication
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid;

    return WillPopScope(
      onWillPop: () async {
        // Exit the app on back button press
        SystemNavigator.pop();  // This closes the app
        return false;  // Prevent the default back navigation behavior
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: shortestSide * 0.18, // Proportional height based on the shortest side
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Text(
            "Groupify",
            style: GoogleFonts.fredoka(
              textStyle: TextStyle(
                fontSize: shortestSide * 0.085, // Font size based on the shortest side
                fontWeight: FontWeight.w600,
                color: const Color.fromRGBO(17, 0, 51, 1),
              ),
            ),
          ),
          actions: [
            Row(
              children: [
                // Search icon to the left of the profile picture
                GestureDetector(
                  onTap: () {
                    // Navigate to GroupSearchPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GroupSearchPage()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Icon(
                      Icons.search,
                      color: const Color.fromRGBO(17, 0, 51, 1), // Icon color
                      size: shortestSide * 0.075, // Adjust the size as needed
                    ),
                  ),
                ),
                // Profile picture with StreamBuilder for real-time updates
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () async {
                      if (userId != null) {
                        setState(() {
                          _isLoading = true; // Start loading before navigating
                        });

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingPage(userId: userId), // Pass userId to SettingPage
                          ),
                        );

                        setState(() {
                          _isLoading = false; // Stop loading after returning
                        });
                      } else {
                        // Show a message if userId is null
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("User not logged in. Please log in."),
                          ),
                        );
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Show loading indicator if profile update is in progress
                        if (_isLoading)
                          const SizedBox(
                            height: 40,
                            width: 40,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          ),

                        // Profile picture with StreamBuilder for real-time updates
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              // While loading, show a circular loading indicator inside CircleAvatar
                              return CircleAvatar(
                                radius: shortestSide * 0.057,
                                backgroundColor: Colors.grey[200],
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.blue,
                                ),
                              );
                            }

                            if (snapshot.hasData && snapshot.data!.exists) {
                              String profilePic = snapshot.data?['profile_pic'] ?? "";

                              if (profilePic.isNotEmpty) {
                                // If profilePic exists, decode and show it in a circular frame
                                return CircleAvatar(
                                  radius: shortestSide * 0.057,
                                  backgroundImage: MemoryImage(base64Decode(profilePic)),
                                  backgroundColor: Colors.grey[200],
                                );
                              }
                            }

                            // Default fallback icon inside CircleAvatar
                            return CircleAvatar(
                              radius: shortestSide * 0.057,
                              backgroundColor: Colors.grey[200],
                              child: const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                // Adding space below AppBar
                SizedBox(height: shortestSide * 0.03), // Space between AppBar and TextField

                // TextField Container
                Container(
                  width: MediaQuery.of(context).size.width, // 100% of screen width
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(230, 234, 255, 1), // Background color
                    borderRadius: BorderRadius.circular(30.0), // Rounded corners
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(0), // Inner padding for TextField
                    child: TextField(
                      controller: _searchGroup,
                      style: GoogleFonts.fredoka(
                        textStyle: const TextStyle(
                          fontSize: 17,
                          color: Color.fromRGBO(17, 0, 51, 1),
                        ),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          color: Color.fromRGBO(17, 0, 51, 1),
                          fontSize: 17,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search, // Magnifying glass icon
                          color: Color.fromRGBO(17, 0, 51, 1),
                          size: 23,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: shortestSide * 0.03),

                Container(child: groupList(),

                  ),



              ],
            ),
          ),
        ),
          floatingActionButton:  FloatingActionButton(onPressed: (){
            popUpDialog(context);
          },
            elevation: 0,
            backgroundColor:Color.fromRGBO(17, 0, 51, 1) ,
            child: Icon(Icons.add,
                color: Colors.white,
                size:30),),
    ),);
  }


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

            final groups = groupSnapshot.data!
                .where((group) => group['groupData'] != null && group['groupData']['groupName'] != null)
                .toList();

            if (groups.isEmpty) {
              return noGroupWidget(); // If all groups are invalid, show no groups widget
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final groupData = group['groupData'];
                final recentMessage = group['recentMessage'];
                final recentMessageSender = group['recentMessageSender'];
                final recentMessageTimestamp = group['recentMessageTimestamp'];

                // Listen for new messages for each group
                return StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('groups')
                      .doc(group['groupId'])
                      .collection('messages')
                      .orderBy('timestamp', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, messageSnapshot) {
                    // Error handling for messages
                    if (messageSnapshot.hasError) {
                      return const Center(child: Text('Error fetching messages'));
                    }

                    // If no messages are found, set default values for message-related properties
                    String latestMessage = "Enjoy Secure and Private chats"; // Updated message
                    String latestSender = "Admin"; // Admin as the sender
                    bool hasNewMessage = false;

                    // Check for new messages
                    if (messageSnapshot.hasData && messageSnapshot.data!.docs.isNotEmpty) {
                      final lastMessageData = messageSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                      final latestMessageTimestamp = lastMessageData['timestamp'] as Timestamp;

                      // Check if the message timestamp is newer than the lastSeenTimestamp
                      final lastSeenTimestamp = userDoc?['lastSeenTimestamp_${group['groupId']}'] ?? Timestamp(0, 0);
                      hasNewMessage = latestMessageTimestamp.compareTo(lastSeenTimestamp) > 0;

                      // Update the group message info with actual data
                      latestMessage = lastMessageData['message'] ?? "Enjoy Secure and Private chats"; // Updated message
                      latestSender = lastMessageData['sender'] ?? "Admin"; // Admin as the sender
                    }

                    // Apply bold text style for unseen messages
                    TextStyle textStyle = TextStyle(fontSize: 14, color: Colors.black54);
                    TextStyle senderTextStyle = TextStyle(fontSize: 14, color: Colors.black54);

                    if (hasNewMessage) {
                      textStyle = textStyle.copyWith(fontWeight: FontWeight.w900); // More bold
                      senderTextStyle = senderTextStyle.copyWith(fontWeight: FontWeight.w900); // More bold
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              groupId: group['groupId'],
                              groupName: groupData['groupName'] ?? 'Group Name',
                              userName: auth.currentUser?.displayName ?? 'User',
                              admin: auth.currentUser?.displayName ?? 'group',
                            ),
                          ),
                        ).then((_) {
                          // After returning from chat, update lastSeenTimestamp for the group
                          firestore.collection('users').doc(uid).update({
                            'lastSeenTimestamp_${group['groupId']}': Timestamp.now(),
                          });
                        });
                      },
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
                          leading: CircleAvatar(
                            backgroundColor: Colors.white,
                            backgroundImage: groupData['groupIcon'] != null && groupData['groupIcon'] != ""
                                ? (groupData['groupIcon'].contains(',')
                                ? MemoryImage(base64Decode(groupData['groupIcon'].split(',').last))
                                : NetworkImage(groupData['groupIcon']))
                                : const NetworkImage(
                              'https://www.calpers.ca.gov/img/infographics/annual-performance-report/icon-talent-management.jpg',
                            ),
                            radius: 24,
                          ),
                          title: Row(
                            children: [
                              Text(
                                groupData['groupName'] ?? 'Group Name',
                                style: GoogleFonts.fredoka(
                                  textStyle: TextStyle(
                                    fontSize: shortestSide * 0.042,
                                    fontWeight: FontWeight.w500,
                                    color: const Color.fromRGBO(17, 0, 51, 1),
                                  ),
                                ),
                              ),
                              if (hasNewMessage)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: CircleAvatar(
                                    radius: 6,
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            "$latestSender: $latestMessage",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textStyle, // Apply the bolder text style for new messages
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
      },
    );
  }

  Stream<List<Map<String, dynamic>>> fetchGroupDetailsStream(List<dynamic> groupIds, FirebaseFirestore firestore) {
    return firestore.collection('groups').snapshots().asyncMap((groupSnapshot) async {
      List<Map<String, dynamic>> groups = [];

      for (var groupDoc in groupSnapshot.docs) {
        final groupId = groupDoc.id;
        final groupData = groupDoc.data() as Map<String, dynamic>?;

        if (groupData == null || !(groupData['members'] ?? []).contains(FirebaseAuth.instance.currentUser?.uid)) {
          continue; // Skip if the current user is not a member of this group
        }

        // Fetch recent message data for each group
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
          recentMessage = lastMessageData['message'] ?? recentMessage;
          recentMessageSender = lastMessageData['sender'] ?? recentMessageSender;
          recentMessageTimestamp = lastMessageData['timestamp'] ?? recentMessageTimestamp;
        }

        groups.add({
          'groupId': groupId,
          'groupData': groupData,
          'recentMessage': recentMessage,
          'recentMessageSender': recentMessageSender,
          'recentMessageTimestamp': recentMessageTimestamp,
          'createdTime': groupData['createdTime'] ?? Timestamp(0, 0),
        });
      }

      groups.sort((a, b) {
        final createdTimeA = a['createdTime'] as Timestamp;
        final createdTimeB = b['createdTime'] as Timestamp;

        if (createdTimeA == createdTimeB) {
          final recentMsgTimeA = a['recentMessageTimestamp'] as Timestamp;
          final recentMsgTimeB = b['recentMessageTimestamp'] as Timestamp;
          return recentMsgTimeB.compareTo(recentMsgTimeA); // Sort by recent message
        }

        return createdTimeB.compareTo(createdTimeA); // Sort by creation time
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
              fontSize: 22, // Font size based on the shortest side
              fontWeight: FontWeight.w500,
              color: const Color.fromRGBO(165, 150, 191, 1.0),
            ),
          ),

        ),
      ),
    );
  }

  String _groupName="";

  void initState() {
    super.initState();

    _fetchUserDetails(); // Fetch email and username
  }
  Future<String?> fetchUserName(String uid) async {
    try {
      final DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        return userDoc['username'] as String?;
      } else {
        print("User document does not exist");
        return null;
      }
    } catch (e) {
      print("Error fetching userName: $e");
      return null;
    }
  }



  Future createGroup(String userName, String id, String groupName)async{

   final CollectionReference groupCollection =
   FirebaseFirestore.instance.collection('groups');
   final CollectionReference userCollection =
   FirebaseFirestore.instance.collection('users');
   final FirebaseAuth auth = FirebaseAuth.instance;
   String? uid = auth.currentUser?.uid;


    DocumentReference groupdocumentReference= await groupCollection.add({
      "groupName":groupName,
      "groupIcon":"",
      "admin":"${uid}",
      "members":[],
      "groupId":"",
      "recentMessage":"",
      "recentMessageSender":"",
      "timestamp": FieldValue.serverTimestamp()

    });

    await groupdocumentReference.update({
      "members":FieldValue.arrayUnion(["${uid}"]),
      "groupId":groupdocumentReference.id,
    });

    DocumentReference userDocumentReference = userCollection.doc(uid);
    return await userDocumentReference.update({
      "groups":FieldValue.arrayUnion(["${groupdocumentReference.id}_$_groupName"])
    });


 }



 bool _isloading=false;

  popUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Create a Group",
                style: GoogleFonts.fredoka(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromRGBO(17, 0, 51, 1),
                  ),
                ),
                textAlign: TextAlign.left,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                      color: Color.fromRGBO(17, 0, 51, 1),
                    ),
                  )
                      : TextField(
                    onChanged: (val) {
                      setState(() {
                        _groupName = val;
                      });
                    },
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromRGBO(17, 0, 51, 1),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.red,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromRGBO(17, 0, 51, 1),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    // Start loading
                    setState(() {
                      _isLoading = true;
                    });

                    final FirebaseAuth auth = FirebaseAuth.instance;
                    String? uid = auth.currentUser?.uid;

                    if (uid == null) {
                      print("Error: User is not logged in");
                      setState(() {
                        _isLoading = false;
                      });
                      return;
                    }

                    String? userName = await fetchUserName(uid);

                    if (userName == null) {
                      print("Error: Could not fetch username");
                      setState(() {
                        _isLoading = false;
                      });
                      return;
                    }

                    try {
                      await createGroup(userName, uid, _groupName);

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Group Created')),
                      );
                      print("Group created successfully!");

                      // Close the dialog
                      Navigator.of(context).pop();
                    } catch (e) {
                      print("Error creating group: $e");
                    } finally {
                      // Stop loading
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(17, 0, 51, 1),
                  ),
                  child: Text(
                    "Create",
                    style: GoogleFonts.fredoka(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(17, 0, 51, 1),
                  ),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.fredoka(
                      textStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
