import 'dart:io';
import 'package:ebooks/app_util.dart';
import 'package:ebooks/pages/nav_main.dart';
import 'package:ebooks/signup_login/sign_in.dart';
import 'package:ebooks/welcome/welcome_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  bool loggedIn = false;
  bool expired = false;

  Future<void> checkLoginStatus() async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var token = localStorage.getString('token');
      if (token != null) {
        setState(() {
          loggedIn = true;
        });
      }
    } catch (e) {
      debugPrint("Error checking login status: $e");
    }
  }

  Future<void> checkExpiration() async {
    try {
      List<FileSystemEntity> result = await AppUtil().readBooks();
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      var exp = localStorage.getString('expiry');

      if (exp != null) {
        final expDate = DateTime.tryParse(exp);
        final now = DateTime.now();

        if (expDate != null &&
            (now.isAfter(expDate) || now.isAtSameMomentAs(expDate))) {
          EasyLoading.showInfo('Subscription Expired!');
          await deleteDownloadedBooks(result);
          await logout();
          if (mounted) {
            setState(() {
              expired = true;
            });
          }
        }
      } else {
        await checkLoginStatus();
      }
    } catch (e) {
      debugPrint("Error checking expiration: $e");
    }
  }

  Future<void> deleteDownloadedBooks(List<FileSystemEntity> books) async {
    try {
      if (books.isNotEmpty) {
        for (var item in books) {
          final directory = Directory(item.path);
          if (await directory.exists()) {
            await directory.delete(recursive: true);
          }
        }
      }
    } catch (e) {
      debugPrint("Error deleting downloaded books: $e");
    }
  }

  Future<void> logout() async {
    try {
      SharedPreferences localStorage = await SharedPreferences.getInstance();
      await localStorage.clear();
    } catch (e) {
      debugPrint("Error during logout: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    configLoading();
    checkExpiration();
    changeStatusBarColor(Colors.white);
  }

  Future<void> changeStatusBarColor(Color color) async {
    try {
      if (!kIsWeb) {
        await FlutterStatusbarcolor.setStatusBarColor(color);
        FlutterStatusbarcolor.setStatusBarWhiteForeground(
            useWhiteForeground(color));
      }
    } catch (e) {
      debugPrint("Error changing status bar color: $e");
    }
  }

  void configLoading() {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.fadingCube
      ..loadingStyle = kIsWeb ? EasyLoadingStyle.dark : EasyLoadingStyle.light
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..progressColor = Colors.green
      ..backgroundColor = Colors.transparent
      ..indicatorColor = Colors.green
      ..textColor = Colors.green
      ..maskColor = Colors.white
      ..userInteractions = true
      ..dismissOnTap = false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      title: '',
      home: AnimatedSplashScreen(
        splashIconSize: 100,
        duration: 2000,
        centered: true,
        splash: 'img/jmc-logo.png',
        nextScreen: expired
            ? const SignIn()
            : (loggedIn ? const MyNav() : const Welcome()),
        splashTransition: SplashTransition.sizeTransition,
        pageTransitionType: PageTransitionType.fade,
        backgroundColor: Colors.white,
      ),
      builder: EasyLoading.init(),
    );
  }
}
