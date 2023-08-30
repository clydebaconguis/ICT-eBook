import 'package:concentric_transition/concentric_transition.dart';
import 'package:ebooks/auth/auth_page.dart';
import 'package:ebooks/pages/nav_main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pages = [
  const PageData(
    icon: Icons.local_library_rounded,
    title: "Search for your ICT eBook",
    bgColor: Color(0xff3b1791),
    textColor: Colors.white,
  ),
  const PageData(
    icon: Icons.download_for_offline_rounded,
    title: "Download Offline",
    bgColor: Color(0xfffab800),
    textColor: Color(0xff3b1790),
  ),
  const PageData(
    icon: Icons.phone_android_rounded,
    title: "Access on all platform ",
    bgColor: Color(0xffffffff),
    textColor: Color(0xff3b1790),
  ),
];

class Welcome extends StatefulWidget {
  const Welcome({Key? key}) : super(key: key);

  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  late bool isLoggedIn;
  @override
  void initState() {
    _checkLoginStatus();
    changeStatusBarColor(const Color(0xff3b1791));
    super.initState();
  }

  _checkLoginStatus() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    var token = localStorage.getString('token') ?? '';
    if (mounted) {
      setState(() {
        isLoggedIn = token.isNotEmpty;
      });
    }
    isLoggedIn ? navigateToMainNav() : {};
  }

  navigateToMainNav() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MyNav(),
        ),
        (Route<dynamic> route) => false);
  }

  checkAuth() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthPage(),
        ),
        (Route<dynamic> route) => false);
  }

  changeStatusBarColor(Color color) async {
    if (!kIsWeb) {
      await FlutterStatusbarcolor.setStatusBarColor(color);
      if (useWhiteForeground(color)) {
        FlutterStatusbarcolor.setStatusBarWhiteForeground(true);
      } else {
        FlutterStatusbarcolor.setStatusBarWhiteForeground(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return !isLoggedIn
        ? Scaffold(
            body: ConcentricPageView(
              onFinish: () => checkAuth(),
              colors: pages.map((p) => p.bgColor).toList(),
              onChange: (page) => changeStatusBarColor(pages[page].bgColor),
              radius: screenWidth * 0.1,
              nextButtonBuilder: (context) => Padding(
                padding: const EdgeInsets.only(left: 3), // visual center
                child: Icon(
                  Icons.navigate_next,
                  size: screenWidth * 0.08,
                ),
              ),
              // enable itemcount to disable infinite scroll
              // itemCount: pages.length,
              // opacityFactor: 2.0,
              scaleFactor: 2,
              // verticalPosition: 0.7,
              // direction: Axis.vertical,
              itemCount: pages.length,
              // physics: NeverScrollableScrollPhysics(),
              itemBuilder: (index) {
                final page = pages[index % pages.length];
                return SafeArea(
                  child: _Page(
                    page: page,
                  ),
                );
              },
            ),
          )
        : const SizedBox.shrink();
  }
}

class PageData {
  final String? title;
  final IconData? icon;
  final Color bgColor;
  final Color textColor;

  const PageData({
    this.title,
    this.icon,
    this.bgColor = Colors.white,
    this.textColor = Colors.black,
  });
}

class _Page extends StatelessWidget {
  final PageData page;

  const _Page({
    Key? key,
    required this.page,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          margin: const EdgeInsets.all(16.0),
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: page.textColor),
          child: Icon(
            page.icon,
            size: screenHeight * 0.1,
            color: page.bgColor,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            page.title ?? "",
            style: TextStyle(
                color: page.textColor,
                fontSize: screenHeight * 0.035,
                fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
