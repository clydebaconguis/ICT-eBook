import 'dart:convert';

import 'package:ebooks/pages/nav_main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../signup_login/sign_in.dart';
import '../user/user.dart';
import '../user/user_data.dart';

// This class handles the Page to dispaly the user's info on the "Edit Profile" Screen
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  var user = UserData.myUser;
  String grade = '';
  @override
  void initState() {
    getUser();
    super.initState();
  }

  getUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final json = preferences.getString('user');
    grade = preferences.getString('grade')!;
    setState(() {
      user = json == null ? UserData.myUser : User.fromJson(jsonDecode(json));
    });
  }

  logout() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    await localStorage.clear();
    // EasyLoading.dismiss();
  }

  Future<void> showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Close the dialog and do nothing (cancel logout)
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog and perform logout
                Navigator.of(context).pop();
                logout();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const SignIn(),
                    ),
                    (Route<dynamic> route) => false);
              },
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // final double height = MediaQuery.of(context).size.height;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: Colors.white, // Light background
            elevation: 0, // Remove shadow for a cleaner look
            iconTheme: const IconThemeData(color: Colors.black), // Dark icons
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MyNav()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
            title: Text(
              "Profile",
              style: GoogleFonts.prompt(
                textStyle: const TextStyle(
                  color: Colors.black, // Dark text
                  fontSize: 18,
                ),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Card(
                            margin: const EdgeInsets.all(12),
                            elevation: 0.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    offset: const Offset(0.0, 0.0),
                                    blurRadius: 18.0,
                                    spreadRadius: 4.0,
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    const CircleAvatar(
                                      backgroundColor:
                                          Color.fromARGB(255, 140, 228, 243),
                                      radius: 60.0,
                                      backgroundImage: AssetImage(
                                        'img/profile.png', // Replace with the actual profile picture URL
                                      ),
                                    ),
                                    const SizedBox(height: 22),
                                    Text(
                                      user.name,
                                      style: GoogleFonts.prompt(
                                        fontSize: 22.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 25.0),
                                    buildProfileItem(
                                        Icons.phone,
                                        'Phone',
                                        user.mobilenum.isNotEmpty
                                            ? user.mobilenum
                                            : 'Not Specified'),
                                    const Divider(),
                                    buildProfileItem(
                                      Icons.school,
                                      'Grade Level',
                                      grade.isNotEmpty
                                          ? grade
                                          : 'Not Specified',
                                    ),
                                    const Divider(),
                                    buildProfileItem(
                                      Icons.email,
                                      'Email',
                                      user.email.isNotEmpty
                                          ? user.email
                                          : 'Not Specified',
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton(
                                      onPressed: () {
                                        showLogoutConfirmationDialog(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget buildProfileItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.black54),
        const SizedBox(width: 8.0),
        Text(
          '$label:',
          style: GoogleFonts.prompt(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.prompt(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}
