import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:groupify/pages/auth/forgot_pass.dart';
import 'package:groupify/pages/auth/signup_page.dart';
import 'package:groupify/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../../helper/helper_function.dart';

void main() {
  runApp(MaterialApp(
    home: LoginPage(),
  ));
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool _obscureText = true;

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final CollectionReference users = FirebaseFirestore.instance.collection('users');

  void ForgotPassword(){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ForgotPass()),
    );
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

  Future<void> SignIn() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in both fields')),
      );
      return;
    }

    // Show the loading dialog
    showLoadingDialog(context);

    try {
      // Step 1: Authenticate the user with Google
      final GoogleSignIn _googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled Google Sign-In
        Navigator.pop(context); // Dismiss the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in canceled.')),
        );
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Authenticate with Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final String email = userCredential.user?.email ?? "";
      print("Google sign-in success: $email");

      // Step 2: Verify the username and password in Firestore
      QuerySnapshot querySnapshot = await users
          .where('username', isEqualTo: username)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Username not found
        Navigator.pop(context); // Dismiss the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username not found.')),
        );
        return;
      }

      String storedPassword = querySnapshot.docs.first['password'];

      if (storedPassword != password) {
        // Wrong password
        Navigator.pop(context); // Dismiss the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wrong password.')),
        );
        return;
      }

      // Step 3: Login successful
      await HelperFunction.saveUserLoggedInStatus(true);
      await HelperFunction.saveUserName(username);

      // Dismiss the loading dialog
      Navigator.pop(context);

      // Notify success and navigate to HomePage
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (e) {
      // Handle errors and dismiss loading dialog
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during login: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Image.asset(
                    "assets/img1.jpg",
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  "Login",
                  style: GoogleFonts.fredoka(
                    textStyle: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(17, 0, 51, 1),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Please Sign in to continue",
                  style: GoogleFonts.fredoka(
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(17, 0, 51, 1),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(230, 234, 255, 1),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextField(
                      controller: _usernameController,
                      style: GoogleFonts.fredoka(
                        textStyle: TextStyle(
                          fontSize: 19,
                          color: Color.fromRGBO(17, 0, 51, 1),
                        ),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Username',
                        hintStyle: TextStyle(
                          color: Color.fromRGBO(17, 0, 51, 1),
                          fontSize: 19,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.person,
                          color: Color.fromRGBO(17, 0, 51, 1),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(230, 234, 255, 1),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      style: GoogleFonts.fredoka(
                        textStyle: TextStyle(
                          fontSize: 19,
                          color: Color.fromRGBO(17, 0, 51, 1),
                        ),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: Color.fromRGBO(17, 0, 51, 1),
                          fontSize: 19,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Color.fromRGBO(17, 0, 51, 1),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility : Icons.visibility_off,
                            color: Color.fromRGBO(17, 0, 51, 1),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    ForgotPassword();
                    HapticFeedback.heavyImpact();

                  },
                  child: Text(
                    "Forgot Password",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[700],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {SignIn();
                    HapticFeedback.heavyImpact();


                    },
                    child: Text(
                      "Sign In",
                      style: GoogleFonts.fredoka(
                        textStyle: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),

                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(17, 0, 51, 1),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
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
                        // Navigate to Signup Page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SignupPage()),
                        );
                      },
                      child: Text(
                        "Sign Up",
                        style: GoogleFonts.fredoka(
                          textStyle: TextStyle(
                              fontSize: 15,
                              color: Color.fromRGBO(17, 0, 51, 1),
                              fontWeight: FontWeight.bold
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
}
