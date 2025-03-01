import 'dart:convert';
import 'dart:io';

import 'package:ebooks/api/my_api.dart';
import 'package:ebooks/app_util.dart';
import 'package:ebooks/pages/nav_main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_statusbarcolor_ns/flutter_statusbarcolor_ns.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignIn extends StatefulWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
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
  void initState() {
    changeStatusBarColor(Colors.white);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Center(
        child: isSmallScreen
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Logo(),
                  _FormContent(),
                ],
              )
            : Container(
                padding: const EdgeInsets.all(32.0),
                constraints: const BoxConstraints(maxWidth: 800),
                child: const Row(
                  children: [
                    Expanded(
                      child: _Logo(),
                    ),
                    Expanded(
                      child: Center(
                        child: _FormContent(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({Key? key}) : super(key: key);

  Widget _title() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
          text: 'ICT',
          style: GoogleFonts.prompt(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: const Color.fromRGBO(141, 31, 31, 1),
          ),
          children: [
            TextSpan(
              text: ' e',
              style: GoogleFonts.prompt(
                color: const Color.fromRGBO(242, 167, 0, 1),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: 'Book',
              style: GoogleFonts.prompt(
                color: const Color.fromRGBO(242, 167, 0, 1),
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // FlutterLogo(size: isSmallScreen ? 100 : 200),
        CircleAvatar(
          radius: isSmallScreen ? 60 : 90,
          backgroundColor: Colors.transparent,
          child: Image.asset("img/jmc-logo.png"),
        ),
        Padding(
            padding: isSmallScreen
                ? const EdgeInsets.all(10.0)
                : const EdgeInsets.all(0.0),
            child: _title()
            // Text(
            //   "Welcome to Flutter!",
            //   textAlign: TextAlign.center,
            //   style: isSmallScreen
            //       ? Theme.of(context).textTheme.headline5
            //       : Theme.of(context)
            //           .textTheme
            //           .headline4
            //           ?.copyWith(color: Colors.black),
            // ),

            )
      ],
    );
  }
}

class _FormContent extends StatefulWidget {
  const _FormContent({Key? key}) : super(key: key);

  @override
  State<_FormContent> createState() => __FormContentState();
}

class __FormContentState extends State<_FormContent> {
  bool _isPasswordVisible = false;
  bool isButtonEnabled = true;
  var body = {};
  var expiration = '';
  // bool _rememberMe = false;
  // final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  deleteExpiredBooks() async {
    List<FileSystemEntity> result = await AppUtil().readBooks();
    if (result.isNotEmpty) {
      for (var item in result) {
        final directory = Directory(item.path);
        directory.deleteSync(recursive: true);
        // print("Deleted directory: ${directory.path}");
      }
    }
  }

  _navigateToBooks() {
    if (mounted) {
      EasyLoading.showSuccess('Successfully loggedin!');
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MyNav(),
          ),
          (Route<dynamic> route) => false);
    }
  }

  _login() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    EasyLoading.show(status: 'loading...');
    var data = {
      'email': emailController.text.toString(),
      'password': passwordController.text.toString(),
    };

    try {
      var res = await CallApi().login(data, 'studentlogin');
      if (res != null) {
        if (mounted) {
          setState(() {
            body = json.decode(res.body);
            expiration = body['expiry'] ?? '';
            // print(body);
            // print(expiration);
          });
        }
      }
      if (body['success']) {
        if (expiration.isNotEmpty) {
          final now = DateTime.now();
          final expDate = DateTime.parse(expiration);
          if (now.isAfter(expDate) || now.isAtSameMomentAs(expDate)) {
            EasyLoading.showInfo('Subscription Expired!');
            deleteExpiredBooks();
          } else {
            localStorage.setString('token', body['user']['name']);
            localStorage.setString('grade', body['grade']);
            localStorage.setString('user', json.encode(body['user']));
            localStorage.setString('expiry', expiration);
            _navigateToBooks();
          }
        } else {
          localStorage.setString('token', body['user']['name']);
          localStorage.setString('grade', body['grade']);
          localStorage.setString('user', json.encode(body['user']));
          localStorage.setString('expiry', expiration);
          _navigateToBooks();
        }
      } else {
        EasyLoading.showError('Failed to Login');
        if (mounted) {
          setState(() {
            isButtonEnabled = true;
          });
        }
      }
    } catch (e) {
      // print('Error during login: $e');
      EasyLoading.showError('An error occurred during login');
      if (mounted) {
        setState(() {
          isButtonEnabled = true;
        });
      }
    } finally {
      EasyLoading.dismiss();
      if (mounted) {
        setState(() {
          isButtonEnabled = true;
        });
      }
    }
    if (mounted) {
      setState(() {
        isButtonEnabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            controller: emailController,
            validator: (value) {
              // add email validation
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }

              bool emailValid = RegExp(
                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                  .hasMatch(value);
              if (!emailValid) {
                return 'Please enter a valid email';
              }

              return null;
            },
            decoration: InputDecoration(
              labelStyle: GoogleFonts.poppins(),
              labelText: 'Username',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          _gap(),
          TextFormField(
            controller: passwordController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter some text';
              }

              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
                labelStyle: GoogleFonts.poppins(),
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                )),
          ),
          _gap(),
          // CheckboxListTile(
          //   value: _rememberMe,
          //   onChanged: (value) {
          //     if (value == null) return;
          //     setState(() {
          //       _rememberMe = value;
          //     });
          //   },
          //   title: const Text('Remember me'),
          //   controlAffinity: ListTileControlAffinity.leading,
          //   dense: true,
          //   contentPadding: const EdgeInsets.all(0),
          // ),
          _gap(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isButtonEnabled ? const Color(0xFF221484) : Colors.grey,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: isButtonEnabled
                  ? () {
                      if (emailController.text.isEmpty ||
                          passwordController.text.isEmpty) {
                        EasyLoading.showToast(
                          'Fill all fields!',
                          toastPosition: EasyLoadingToastPosition.bottom,
                        );
                      } else {
                        setState(() {
                          isButtonEnabled = false;
                        });
                        _login();
                      }
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  'Sign in',
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 16);
}
