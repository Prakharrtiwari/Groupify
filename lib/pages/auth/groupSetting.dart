import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groupify/pages/home_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class GroupSettingPage extends StatefulWidget {
  final String groupId;

  const GroupSettingPage({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupSettingPage> createState() => _GroupSettingPageState();
}

class _GroupSettingPageState extends State<GroupSettingPage> {
  String _groupName = "Unnamed Group";
  String _groupIconUrl = "";
  String _adminName = "Admin";
  String _adminProfilePic = "";
  String _groupLink = "";
  List<String> _memberNames = [];
  List<String> _memberProfilePicsBase64 = []; // Storing the base64 encoded profile pictures
  bool _isLoading = true;
  File? _groupIcon;

  @override
  void initState() {
    super.initState();
    _fetchAllGroupData();
  }

  Future<void> _fetchAllGroupData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();

      if (snapshot.exists) {
        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;

        String adminUid = data['admin'] ?? "";
        List<String> memberUids = List<String>.from(data['members'] ?? []);

        // Fetch admin and member usernames and profile pictures
        String adminUsername = await _fetchUsername(adminUid);
        String adminProfilePic = await _fetchProfilePic(adminUid);

        List<Map<String, String>> memberUsernames = await Future.wait(
          memberUids.map((uid) async {
            String username = await _fetchUsername(uid);
            String profilePic = await _fetchProfilePic(uid); // Base64 string for profile picture
            return {"username": username, "profilePic": profilePic};
          }),
        );

        setState(() {
          _groupName = data['groupName'] ?? "Unnamed Group";
          _memberNames = memberUsernames.map((e) => e["username"] as String).toList();
          _memberProfilePicsBase64 = memberUsernames.map((e) => e["profilePic"] as String).toList();
          _groupIconUrl = data['groupIcon'] ?? "";
          _adminName = adminUsername;
          _adminProfilePic = adminProfilePic;
          _groupLink = "";
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage("Group does not exist.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorMessage("Failed to fetch group data.");
    }
  }

  Future<String> _fetchUsername(String uid) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
        return userData['username'] ?? "Unknown User";
      } else {
        return "Unknown User";
      }
    } catch (e) {
      return "Unknown User";
    }
  }

  Future<String> _fetchProfilePic(String uid) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userSnapshot.exists) {
        Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
        return userData['profile_pic'] ?? ""; // Return base64 string for the profile picture
      } else {
        return "";
      }
    } catch (e) {
      return "";
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickGroupIcon() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _groupIcon = File(pickedFile.path);
      });
      _updateGroupIcon();
    }
  }

  Future<void> _updateGroupIcon() async {
    if (_groupIcon == null) return;
    try {
      String base64Image = base64Encode(_groupIcon!.readAsBytesSync());
      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({'groupIcon': base64Image});
      setState(() {
        _groupIconUrl = base64Image;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group icon updated successfully.")),
      );
    } catch (e) {
      _showErrorMessage("Failed to update group icon.");
    }
  }

  Future<void> _deleteGroup() async {
    try {
      final groupDoc = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);
      final groupSnapshot = await groupDoc.get();

      if (groupSnapshot.exists) {
        final groupData = groupSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> userIds = groupData['members'] ?? [];

        // Remove group reference from each user's 'groups' field
        for (var userId in userIds) {
          final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
          await userDoc.update({
            'groups': FieldValue.arrayRemove([widget.groupId]),
          });
        }
      } else {
        _showErrorMessage("Group does not exist.");
        return;
      }

      // Delete group document from Firestore
      await groupDoc.delete();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Group deleted successfully.")),
      );

      // Navigate to HomePage and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePage()),
            (route) => false,
      );
    } catch (e) {
      _showErrorMessage("Failed to delete group.");
    }
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
        title: Text(
          "Group Settings",
          style: GoogleFonts.fredoka(
            textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: shortestSide * 0.070,
              fontWeight: FontWeight.w500,
            ),
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            color: Colors.white,
            onPressed: () async {
              bool confirm = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Group"),
                  content: const Text("Are you sure you want to delete this group?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );
              if (confirm) {
                _deleteGroup();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _groupIconUrl.isNotEmpty
                          ? _decodeBase64Image(_groupIconUrl)
                          : const NetworkImage(
                        'https://www.calpers.ca.gov/img/infographics/annual-performance-report/icon-talent-management.jpg',
                      ) as ImageProvider,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _groupName,
                        style: GoogleFonts.fredoka(
                          textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: shortestSide * 0.056,
                            fontWeight: FontWeight.w600,
                          ),
                          color: Color.fromRGBO(17, 0, 51, 1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Admin: $_adminName",
                        style: GoogleFonts.fredoka(
                          textStyle: Theme.of(context).textTheme.bodyMedium,
                          color: const Color.fromRGBO(17, 0, 51, 1),
                          fontSize: shortestSide * 0.045,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              "Members:",
              style: GoogleFonts.fredoka(
                textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: shortestSide * 0.056,
                  fontWeight: FontWeight.w600,
                ),
                color: Color.fromRGBO(17, 0, 51, 1),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _memberNames.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: _memberProfilePicsBase64.length > index && _memberProfilePicsBase64[index].isNotEmpty
                        ? CircleAvatar(
                      backgroundImage: _decodeBase64Image(_memberProfilePicsBase64[index]),
                    )
                        : const CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://thumbs.dreamstime.com/b/default-avatar-profile-icon-vector-social-media-user-photo-default-avatar-profile-icon-vector-social-media-user-286146139.jpg',
                      ),
                    ),
                    title: Text(_memberNames[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider _decodeBase64Image(String base64String) {
    try {
      return MemoryImage(base64Decode(base64String));
    } catch (e) {
      // Return a default image if decoding fails
      return const AssetImage('assets/default_profile_picture.png');
    }
  }
}
