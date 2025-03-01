import 'package:ebooks/pages/all_books.dart';
import 'package:ebooks/pages/profile_page.dart';
import 'package:ebooks/provider/navigation_provider.dart';
import 'package:ebooks/signup_login/sign_in.dart';
import 'package:ebooks/widget/navigation_drawer_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyNav extends StatelessWidget {
  const MyNav({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => NavigationProvider(),
        child: const NavMain(),
      );
}

class NavMain extends StatefulWidget {
  const NavMain({super.key});

  @override
  State<NavMain> createState() => _NavMainState();
}

class _NavMainState extends State<NavMain> {
  @override
  void initState() {
    getUser();
    changeStatusBarColor(const Color(0xFF221484));
    super.initState();
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

  getUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final json = preferences.getString('token');
    if (json == null || json.isEmpty) {
      redirectToSignIn();
    }
  }

  void redirectToSignIn() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const SignIn(),
        ),
        (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        // bool isWide = constraints.maxWidth > 500;

        return Scaffold(
          drawer: const NavigationDrawerWidget(),
          appBar: AppBar(
            backgroundColor: Colors.white, // Set AppBar background to white
            toolbarHeight: constraints.maxWidth >= 1000 ? 80 : kToolbarHeight,
            elevation: 0,
            iconTheme:
                const IconThemeData(color: Colors.black), // Set icons to dark
            leading:
                constraints.maxWidth >= 1000 ? const SizedBox.shrink() : null,
            titleSpacing: 0,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.transparent,
                  child: Image.asset("img/jmc-logo.png", fit: BoxFit.contain),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    "JMC E-Book",
                    style: GoogleFonts.prompt(
                      textStyle: TextStyle(
                        fontSize: constraints.maxWidth >= 1000 ? 30 : 18,
                        color: Colors.black87, // Set text color to black
                      ),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  ),
                  icon: const Icon(Icons.person),
                  tooltip: 'Profile',
                ),
              ),
            ],
          ),
          body: Row(
            children: [
              if (constraints.maxWidth > 1500) const NavigationDrawerWidget(),
              const Expanded(child: AllBooks()),
            ],
          ),
        );
      });
}
