import 'dart:io';

import 'package:ebooks/api/my_api.dart';
import 'package:ebooks/models/pdf_tile.dart';
import 'package:ebooks/provider/navigation_provider2.dart';
import 'package:ebooks/signup_login/sign_in.dart';
import 'package:ebooks/widget/navigation_drawer_widget_02.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class NavPdf extends StatefulWidget {
  final String path;
  final PdfTile books;
  const NavPdf({super.key, required this.path, required this.books});

  @override
  State<NavPdf> createState() => _NavPdfState();
}

class _NavPdfState extends State<NavPdf> {
  final GlobalKey<ScaffoldState> _scaffoldKey2 = GlobalKey<ScaffoldState>();
  String host = CallApi().getHost();
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;

  @override
  void initState() {
    getUser();
    // restrictScreenshot();
    _openDrawerAutomatically();
    _videoPlayerController = VideoPlayerController.file(File(''));
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
    );
    super.initState();
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

  void playVidOnline(String vidPath) {
    setState(() {
      _videoPlayerController = VideoPlayerController.file(File(vidPath));
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: true,
        // Other customization options can be added here
      );
    });
  }

  @override
  Future<void> dispose() async {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
    // await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
  }

  void _openDrawerAutomatically() {
    Future.delayed(const Duration(milliseconds: 0), () {
      _scaffoldKey2.currentState?.openDrawer();
    });
  }

  // Future<void> restrictScreenshot() async {
  //   await FlutterWindowManager.addFlags(
  //     FlutterWindowManager.FLAG_SECURE,
  //   );
  // }

  String title = '';
  String pdfPath = '';

  void updateData(String path, String barTitle) {
    setState(() {
      pdfPath = path;
      title = barTitle;
      if (getFileExtension(pdfPath) == ".mp4") {
        playVidOnline(path);
      }
    });
    Navigator.pop(context);
  }

  String getFileExtension(String url) {
    // Find the last occurrence of the dot (.)
    int dotIndex = url.lastIndexOf('.');

    // If a dot is found and it's not the last character of the URL, return the extension
    if (dotIndex != -1 && dotIndex < url.length - 1) {
      String extension = url.substring(dotIndex);
      return extension;
    }

    // If no dot is found or it's the last character, return an empty string as the extension
    return '';
  }

  String removeFileExtension(String fileName) {
    int dotIndex = fileName.lastIndexOf('_');
    if (dotIndex != -1) {
      return fileName.substring(0, dotIndex);
    } else {
      return fileName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavigationProvider2(),
      child: Scaffold(
        key: _scaffoldKey2, // Assign the GlobalKey to the Scaffold
        drawer: NavigationDrawerWidget2(updateData: updateData),
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF221484), Color(0xFF221484)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: title.isEmpty
              ? Text(
                  removeFileExtension(widget.books.title),
                  style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                )
              : Text(
                  removeFileExtension(title),
                  style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                ),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () {
                // Navigator.pushReplacement(
                //   context,
                //   MaterialPageRoute(builder: (context) => const NavMain()),
                // );
                Navigator.pop(context);
                // Navigator.of(context).pushAndRemoveUntil(
                //     MaterialPageRoute(
                //       builder: (context) => const MyNav(),
                //     ),
                //     (Route<dynamic> route) => false);
              },
              icon: const Icon(Icons.keyboard_return),
            ),
          ],
        ),
        body: (pdfPath.isNotEmpty && getFileExtension(pdfPath) == ".pdf")
            ? SfPdfViewer.file(
                File(pdfPath),
                canShowPaginationDialog: false,
                canShowScrollHead: false,
              )
            : (pdfPath.isNotEmpty && getFileExtension(pdfPath) == ".mp4")
                ? Center(
                    child: Chewie(
                      controller: _chewieController,
                    ),
                  )
                : Image.file(
                    File(widget.books.path),
                  ),
      ),
    );
  }
}
