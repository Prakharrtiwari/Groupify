import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
 class Resetpass extends StatefulWidget {
   const Resetpass({super.key});

   @override
   State<Resetpass> createState() => _ResetpassState();
 }

 class _ResetpassState extends State<Resetpass> {
   @override

   final TextEditingController _newpassController = TextEditingController(); //

   void setNewPass(){

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




   Widget build(BuildContext context) {
     return Scaffold(
       backgroundColor: Colors.white,
       appBar: AppBar(
         backgroundColor: Colors.white,
         toolbarHeight: 60,
         elevation: 0,
         title: Text(
           "Reset Password",
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
                     controller: _newpassController,
                     style: GoogleFonts.fredoka(
                       textStyle: TextStyle(
                         fontSize: 19,
                         color: Color.fromRGBO(17, 0, 51, 1),
                       ),
                     ),
                     decoration: InputDecoration(
                       hintText: 'New password', // Change hint to Username
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
                     setNewPass();
                     HapticFeedback.heavyImpact();
                   },
                   child: Text(
                     "Change Password",
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
