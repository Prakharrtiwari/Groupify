import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class ForgotPass extends StatefulWidget {
  const ForgotPass({super.key});

  @override
  State<ForgotPass> createState() => _ForgotPassState();
}

class _ForgotPassState extends State<ForgotPass> {
  final TextEditingController _emailController = TextEditingController(); // Email controller
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase auth instance

  Future sendMail() async {
    String username = _emailController.text.trim(); // Get the username from the controller

    // Step 1: Check for blank username input
    if (username.isEmpty) {
      _showValidationMessage("Please enter a username.");
      return; // Exit if the username is blank
    }

    try {
      // Step 2: Retrieve the email associated with the username from Firestore
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users') // Your Firestore collection name
          .where('username', isEqualTo: username) // Use username for searching
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Step 3: Extract the email from the first document
        String email = querySnapshot.docs.first.get('email');

        // Step 4: Send the password reset email using the fetched email
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        _showValidationMessage("A password reset email has been sent to $email. Please check your inbox.");
      } else {
        // Handle case where no user exists with the provided username
        _showValidationMessage("No account found with this username.");
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors
      print(e);
      if (e.code == 'invalid-email') {
        _showValidationMessage("The email format is incorrect.");
      } else if (e.code == 'user-not-found') {
        _showValidationMessage("The account does not exist.");
      } else {
        _showValidationMessage(e.message.toString());
      }
    } catch (e) {
      // General error handling
      print("Error: $e");
      _showValidationMessage("An unexpected error occurred. Please try again.");
    }
  }

  // Function to show validation messages
  void _showValidationMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color.fromRGBO(230, 234, 255, 1),
          content: Text(
            message,
            style: GoogleFonts.fredoka(
              textStyle: TextStyle(
                fontSize: 18,
                color: Color.fromRGBO(17, 0, 51, 1),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "OK",
                style: GoogleFonts.fredoka(
                  textStyle: TextStyle(
                    fontSize: 18,
                    color: Color.fromRGBO(17, 0, 51, 1),
                  ),
                ),
              ),
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
          "Recover Password",
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 60),
              SizedBox(height: 40),
              Container(
                height: 55,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(230, 234, 255, 1),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    controller: _emailController,
                    style: GoogleFonts.fredoka(
                      textStyle: TextStyle(
                        fontSize: 19,
                        color: Color.fromRGBO(17, 0, 51, 1),
                      ),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Username', // Change hint to Username
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
                height: 53,
                width: 150,
                child: ElevatedButton(
                  onPressed: () {
                    sendMail();
                    HapticFeedback.heavyImpact();
                  },
                  child: Text(
                    "Send Mail",
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
            ],
          ),
        ),
      ),
    );
  }
}
