import 'package:ebooks/pages/all_books.dart';
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
    changeStatusBarColor(const Color.fromRGBO(141, 31, 31, 1));
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
        bool isWide = constraints.maxWidth > 500;

        return Scaffold(
          drawer: const NavigationDrawerWidget(),
          appBar: AppBar(
            toolbarHeight: constraints.maxWidth > 1000 ? 80 : null,
            elevation: 0,
            leadingWidth: constraints.maxWidth > 1000 ? 10 : null,
            leading:
                constraints.maxWidth > 1000 ? const SizedBox.shrink() : null,
            titleSpacing: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(141, 31, 31, 1),
                    Color.fromRGBO(141, 31, 31, 1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // backgroundColor: const Color(0xff500a34),
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.transparent,
                  child: Image.asset("img/liceo-logo.png", fit: BoxFit.contain),
                ),
                const SizedBox(
                  width: 4,
                ),
                !isWide
                    ? Expanded(
                        child: Text(
                          "Liceo De Cagayan",
                          style: GoogleFonts.prompt(
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: true,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          "Liceo De Cagayan",
                          style: GoogleFonts.prompt(
                            textStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: constraints.maxWidth >= 1000 ? 30 : 18,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: true,
                        ),
                      ),
              ],
            ),
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
