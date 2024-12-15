import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:groupify/pages/auth/login_page.dart';
import 'package:groupify/pages/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _cnfpassController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _obscureText = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final CollectionReference users = FirebaseFirestore.instance.collection('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _usernameError = '';
  String _passwordError = '';
  String _confirmPasswordError = '';

  @override
  void initState() {
    super.initState();
    _checkUserRegistered();
  }

  // Check if the user is already registered
  Future<void> _checkUserRegistered() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google Sign-In was canceled or failed.");
        showValidationDialog('Google Sign-In failed or was canceled. Please try again.');
        return;
      }

      print("Google sign-in success: ${googleUser.email}");

      // Get Google authentication
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        print("Failed to retrieve Google Authentication Tokens.");
        showValidationDialog('Failed to retrieve Google authentication tokens.');
        return;
      }

      // Create a new credential using the accessToken and idToken
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Use the credential to sign in with Firebase
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      print("Firebase sign-in success: ${userCredential.user?.email}");

      // Check if the user is already registered in Firestore
      final email = googleUser.email;
      QuerySnapshot querySnapshot = await users.where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isNotEmpty) {
        showValidationDialog('This Google account is already registered.');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
        showValidationDialog('This Google account is already registered.');
      }
    } catch (e) {
      print("Google sign-in error: $e");
      showValidationDialog('Google Sign-In failed: $e');
    }
  }

  // Function to show a customized loading dialog
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

  Future<void> SignUp() async {
    // Show the loading dialog
    showLoadingDialog(context);

    setState(() {
      _usernameError = '';
      _passwordError = '';
      _confirmPasswordError = '';
    });

    // Validate the username field
    if (_userController.text.isEmpty) {
      setState(() {
        _usernameError = 'Please enter a username';
      });
      // Close the loading dialog and return
      Navigator.pop(context);
      return;
    }

    // Validate the password field
    if (_passController.text.isEmpty) {
      setState(() {
        _passwordError = 'Please enter a password';
      });
      // Close the loading dialog and return
      Navigator.pop(context);
      return;
    }

    // Validate the confirm password field
    if (_passController.text != _cnfpassController.text) {
      setState(() {
        _confirmPasswordError = 'Passwords do not match';
      });
      // Close the loading dialog and return
      Navigator.pop(context);
      return;
    }

    String user = _userController.text;
    String pass = _passController.text;

    try {
      // Check if the username already exists
      QuerySnapshot querySnapshot = await users.where('username', isEqualTo: user).get();

      if (querySnapshot.docs.isNotEmpty) {
        showValidationDialog('Username already exists. Please choose a different one.');
        // Close the loading dialog
        Navigator.pop(context);
        return;
      }

      // Step 1: Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        print("Google sign-in success: ${googleUser.email}");

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Step 2: Authenticate with Firebase
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final String uid = userCredential.user?.uid ?? "";
        print("Firebase sign-in success: ${userCredential.user?.email}");

        // Step 3: Add user details to Firestore with `group` as an empty list
        await users.doc(uid).set({
          'username': user,
          'password': pass, // Store securely in production
          'email': userCredential.user?.email ?? "",
          'profile_pic': '', // Placeholder or URL to profile picture
          'group': [], // Empty list for group associations
          'uid': uid,
        });

        // Close the loading dialog after the registration is done
        Navigator.pop(context);

        // Show success dialog
        showValidationDialog('Registered Successfully');

        // Navigate to HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        // Close the loading dialog in case of failure
        Navigator.pop(context);
        showValidationDialog('Google sign-in failed. Please try again.');
      }
    } catch (error) {
      // Close the loading dialog in case of error
      Navigator.pop(context);
      print("Error during sign-up: $error");
      showValidationDialog('Failed to Register User: $error');
    }
  }





  // Function to show validation errors in a popup
  void showValidationDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color.fromRGBO(230, 234, 255, 1),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 60,
        elevation: 0,
        title: Text(
          "Register",
          style: GoogleFonts.fredoka(
            textStyle: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: Color.fromRGBO(17, 0, 51, 1),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 60),
                SizedBox(height: 40),
                // Username Field
                _buildTextField(
                    controller: _userController,
                    hint: 'Username',
                    icon: Icons.person,
                    error: _usernameError),
                SizedBox(height: 20),
                // Password Field
                _buildTextField(
                    controller: _passController,
                    hint: 'Password',
                    icon: Icons.lock,
                    isPassword: true,
                    error: _passwordError),
                SizedBox(height: 20),
                // Confirm Password Field
                _buildTextField(
                    controller: _cnfpassController,
                    hint: 'Confirm Password',
                    icon: Icons.lock,
                    isPassword: true,
                    error: _confirmPasswordError),
                SizedBox(height: 20),
                // Sign Up Button
                SizedBox(
                  height: 50,
                  width: 200,
                  child: ElevatedButton(
                    onPressed: (){
                      SignUp();
                      HapticFeedback.heavyImpact();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(17, 0, 51, 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.fredoka(
                        textStyle: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: GoogleFonts.fredoka(
                        textStyle: TextStyle(
                          fontSize: 15,
                          color: Color.fromRGBO(17, 0, 51, 1),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                      child: Text(
                        "Login",
                        style: GoogleFonts.fredoka(
                          textStyle: TextStyle(
                            fontSize: 15,
                            color: Color.fromRGBO(17, 0, 51, 1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to build text fields with error message display
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    required String error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 55,
          decoration: BoxDecoration(
            color: Color.fromRGBO(230, 234, 255, 1),
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: TextFormField(
              controller: controller,
              obscureText: isPassword ? _obscureText : false,
              style: GoogleFonts.fredoka(
                textStyle: TextStyle(
                  fontSize: 19,
                  color: Color.fromRGBO(17, 0, 51, 1),
                ),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Color.fromRGBO(17, 0, 51, 1),
                  fontSize: 19,
                ),
                border: InputBorder.none,
                prefixIcon: Icon(icon, color: Color.fromRGBO(17, 0, 51, 1)),
                suffixIcon: isPassword
                    ? GestureDetector(
                  onTap: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                  child: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Color.fromRGBO(17, 0, 51, 1),
                  ),
                )
                    : null,
              ),
            ),
          ),
        ),
        // Error message
        if (error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 5),
            child: Text(
              error,
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        SizedBox(height: 10), // Add space after error message
      ],
    );
  }
}
