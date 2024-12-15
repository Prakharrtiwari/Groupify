import 'package:shared_preferences/shared_preferences.dart';

class HelperFunction {

  // Keys for shared preferences
  static String userLoggedInKey = "LOGGEDINKEY";
  static String userNameKey = "USERNAMEKEY";
  static String userMailKey = "USERMAILKEY";

  // Saving data in SharedPreferences
  static Future<bool> saveUserLoggedInStatus(bool isUserLoggedIn) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setBool(userLoggedInKey, isUserLoggedIn);
  }

  static Future<bool> saveUserName(String userName) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return await sf.setString(userNameKey, userName);
  }

  static Future<bool> saveEmail(String email) async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return  sf.setString(userMailKey, email);

  }

  // Getting data from SharedPreferences
  static Future<bool?> getUserLoggedInStatus() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getBool(userLoggedInKey);
  }

  static Future<String?> getUsername() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userNameKey);
  }

  static Future<String?> getUserEmail() async {
    SharedPreferences sf = await SharedPreferences.getInstance();
    return sf.getString(userMailKey);
  }

  static Future<bool> clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }


}
