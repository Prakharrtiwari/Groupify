  import 'package:flutter/material.dart';
  import 'package:firebase_core/firebase_core.dart';
import 'package:groupify/pages/auth/login_page.dart';
import 'package:groupify/pages/home_page.dart';
  import 'package:groupify/helper/helper_function.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());

}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  bool isUserLoggedIn = false;

  void initState(){
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    bool? loggedInStatus = await HelperFunction.getUserLoggedInStatus();
    if (loggedInStatus != null && loggedInStatus) {
      setState(() {
        isUserLoggedIn = true;
      });
    } else {
      setState(() {
        isUserLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:isUserLoggedIn? const HomePage():  LoginPage(),
    );

  }
}

