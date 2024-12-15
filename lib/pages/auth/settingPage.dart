import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:groupify/pages/auth/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:groupify/helper/helper_function.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  final String userId;
  const SettingPage({Key? key, required this.userId}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  File? _profileImage;
  bool _isUpdating = false; // Track loading state for updating profile picture
  String _profilePic = ""; // Store the profile picture from Firestore
  String _userEmail = ""; // Store the user's email
  String _userName = ""; // Store the user's name

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Fetch profile picture
    _fetchUserDetails(); // Fetch email and username
  }

  // Method to fetch user profile data (profile picture)
  Future<void> _fetchUserProfile() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      setState(() {
        _profilePic = snapshot['profile_pic'] ?? ""; // Set the profile picture
      });
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

// Method to fetch user email and username using HelperFunction
  Future<void> _fetchUserDetails() async {
    try {
      String? userName = await HelperFunction.getUsername();
      setState(() {
        // If userName is null or empty, set it to "Dear"
        _userName = (userName != null && userName.isNotEmpty) ? userName : "Dear";
      });
    } catch (e) {
      print("Error fetching user details: $e");
      setState(() {
        _userName = "Dear"; // Fallback to "Dear" in case of any error
      });
    }
  }


  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Stack(
          children: [
            // Blur effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.white.withOpacity(0.7), // Semi-transparent dark overlay
              ),
            ),
            // Centered CircularProgressIndicator
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(17, 0, 51, 1)), // Dark blue color
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> logout(BuildContext context) async {
    try {
      // Show loading indicator during the logout process
      showLoadingDialog(context);

      // Introduce a 1-second delay before proceeding with logout actions
      await Future.delayed(Duration(seconds: 1));

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear the user data (username, email, and loggedInStatus)
      await HelperFunction.clearUserData();

      // Remove loading indicator
      Navigator.of(context).pop();

      // Redirect to Login Page and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false, // Remove all previous routes
      );
    } catch (e) {
      // Handle any errors during logout
      print("Error during logout: $e");

      // Remove loading indicator in case of an error
      Navigator.of(context).pop();
    }
  }


  // Method to pick an image
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _isUpdating = true; // Set loading state to true before uploading
        });
        await _updateProfileImage(); // Call update function after selecting image
        setState(() {
          _isUpdating = false; // Set loading state to false after uploading
        });
      }
    } catch (e) {
      print("Error picking image: $e");
      setState(() {
        _isUpdating = false; // Set loading state to false if there's an error
      });
    }
  }
// Method to update profile image in Firestore
  Future<void> _updateProfileImage() async {
    if (_profileImage == null) return; // Exit if no image is selected

    try {
      // Convert File to Base64 string
      String imageBase64 = base64Encode(_profileImage!.readAsBytesSync());

      // Update Firestore with the new image
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'profile_pic': imageBase64});

      // Update the UI with the new image
      setState(() {
        _profilePic = imageBase64;
      });

      print("Profile image updated in Firestore.");
    } catch (e) {
      print("Error updating profile image: $e");
    } finally {
      // Make sure to set _isUpdating to false after the update process is done
      setState(() {
        _isUpdating = false;
      });
    }
  }


  // Bottom sheet to choose between gallery and camera
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(17, 0, 51, 1),
        toolbarHeight: shortestSide * 0.18, // Proportional height based on the shortest side
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          "Profile",
          style: GoogleFonts.fredoka(
            textStyle: TextStyle(
              fontSize: shortestSide * 0.070, // Font size based on the shortest side
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView( // Wrap the entire body in a SingleChildScrollView to make it scrollable
        child: Center(
          child: Column(
            children: [
              SizedBox(height: shortestSide * 0.15),

              // Profile Picture with Edit Option
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: CircleAvatar(
                      radius: shortestSide * 0.20,
                      backgroundImage: _profilePic.isNotEmpty
                          ? MemoryImage(base64Decode(_profilePic))
                          : const NetworkImage(
                        "https://thumbs.dreamstime.com/b/default-avatar-profile-icon-vector-social-media-user-photo-default-avatar-profile-icon-vector-social-media-user-286146139.jpg",
                      ) as ImageProvider,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  if (_isUpdating)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: shortestSide * 0.03,
                    right: shortestSide * 0.009,
                    child: GestureDetector(
                      onTap: _showImagePicker,
                      child: CircleAvatar(
                        radius: shortestSide * 0.05,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.edit,
                          color: const Color.fromRGBO(17, 0, 51, 1),
                          size: shortestSide * 0.055,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: shortestSide * 0.13),

              // Display Username
              Text(
                "Hiii $_userName,",
                style: GoogleFonts.fredoka(
                  textStyle: TextStyle(
                    fontSize: shortestSide * 0.060, // Font size based on the shortest side
                    fontWeight: FontWeight.w600,
                    color: const Color.fromRGBO(87, 6, 80, 1.0),
                  ),
                ),
                textAlign: TextAlign.center, // To center the text
              ),


              SizedBox(height: shortestSide * 0.03),

              Text(
                "Build private groups\nand enjoy secure, private chats.",
                style: GoogleFonts.fredoka(
                  textStyle: TextStyle(
                    fontSize: shortestSide * 0.038, // Font size based on the shortest side
                    fontWeight: FontWeight.w500,
                    color: const Color.fromRGBO(87, 6, 80, 1.0),
                  ),
                ),
                textAlign: TextAlign.center, // To center the text
              ),


              SizedBox(height: shortestSide * 0.2),

              Container(
                child: ElevatedButton(
                  onPressed: () async {
                    await logout(context); // Call the logout function when pressed
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromRGBO(17, 0, 51, 1), // Background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Optional: for rounded corners
                    ),
                  ),
                  child: Text(
                    "Log Out",
                    style: GoogleFonts.fredoka(
                      textStyle: TextStyle(
                        fontSize: 20,
                        color: Colors.white, // Text color
                      ),
                    ),
                  ),
                ),
              ),



            ],
          ),
        ),
      ),
    );
  }
}