import 'dart:convert';
import 'dart:io';
import 'package:ebooks/api/my_api.dart';
import 'package:ebooks/app_util.dart';
import 'package:ebooks/pages/nav_pdf.dart';
import 'package:ebooks/signup_login/sign_in.dart';
import 'package:flutter/material.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/get_books_info_02.dart';
import '../models/pdf_tile.dart';
import '../user/user.dart';
import '../user/user_data.dart';
import 'detail_book.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class AllBooks extends StatefulWidget {
  const AllBooks({Key? key}) : super(key: key);

  @override
  State<AllBooks> createState() => _AllBooksState();
}

class _AllBooksState extends State<AllBooks> {
  late ConnectivityResult _connectivityResult = ConnectivityResult.none;
  String host = CallApi().getHost();
  var books = <Books2>[];
  List<PdfTile> files = [];
  bool reloaded = false;
  bool activeConnection = true;
  var user = UserData.myUser;
  displayScreeMsg() {
    if (!reloaded) {
      if (activeConnection) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Connection restored."),
          backgroundColor: Colors.pink,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Offline Mode."),
          backgroundColor: Colors.pink,
        ));
      }
    }
  }

  getUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final json = preferences.getString('user');
    var token = preferences.getString('token');
    if (token == null || token.isEmpty) {
      redirectToSignIn();
    }

    setState(() {
      // host = savedDomainName;
      user = json == null ? UserData.myUser : User.fromJson(jsonDecode(json));
      // print(user.id);
    });
  }

  void redirectToSignIn() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const SignIn(),
        ),
        (Route<dynamic> route) => false);
  }

  @override
  void initState() {
    getUser();
    checkConnectivity();
    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _connectivityResult = result;
        if (_connectivityResult.toString() == "ConnectivityResult.mobile" ||
            _connectivityResult.toString() == "ConnectivityResult.wifi") {
          setState(() {
            reloaded = true;
            activeConnection = true;
            getBooksOnline();
          });
        } else {
          setState(() {
            reloaded = true;
            activeConnection = false;
            getDownloadedBooks();
          });
        }
        displayScreeMsg();
      });
    });
    // readSpecificBook();
    super.initState();
  }

  Future<void> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = connectivityResult;
      if (_connectivityResult.toString() == "ConnectivityResult.mobile" ||
          _connectivityResult.toString() == "ConnectivityResult.wifi") {
        if (mounted) {
          setState(() {
            reloaded = true;
            activeConnection = true;
            getBooksOnline();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            reloaded = true;
            activeConnection = false;
            getDownloadedBooks();
          });
        }
      }
      displayScreeMsg();
    });
  }

  // readSpecificBook() async {
  //   var dir = await getApplicationSupportDirectory();
  //   final pathFile = Directory(dir.path);
  //   // final pathFile = Directory(
  //   //     '${dir.path}/Visual Graphics Design Okey/1 INTRODUCTION TO COMPUTER IMAGES AND ADOBE PHOTOSHOP/Chapter 2: Getting Started in Photoshop');
  //   pathFile.deleteSync(recursive: true);

  //   // print(entities);
  // }

  Future<void> getDownloadedBooks() async {
    try {
      books.clear();
      files.clear();

      var result = await AppUtil().readBooks();
      late String imgUrl = '';
      final List<PdfTile> listOfChild = [];

      listOfChild.clear();

      for (var item in result) {
        try {
          var foldrName = splitPath(item.path);
          var foldrChild = await AppUtil().readFilesDir(foldrName);

          if (foldrChild.isNotEmpty) {
            for (var element in foldrChild) {
              if (splitPath(element.path).toString() == "cover_image") {
                imgUrl = element.path;
              }
              if (element.path.isNotEmpty &&
                  splitPath(element.path).toString() != "cover_image") {
                listOfChild.add(
                  PdfTile(
                    title: splitPath(element.path),
                    path: element.path,
                    isExpanded: false,
                  ),
                );
              }
            }
          }

          setState(() {
            files.add(
              PdfTile(
                title: foldrName,
                path: imgUrl,
                children:
                    List.from(listOfChild), // Prevent shared reference issues
                isExpanded: false,
              ),
            );
          });

          imgUrl = '';
          listOfChild.clear();
        } catch (e) {
          debugPrint("Error processing item: $e");
        }
      }
    } catch (e) {
      debugPrint("Error in getDownloadedBooks: $e");
    }
  }

  getBooksOnline() async {
    files.clear();
    books.clear();
    try {
      await CallApi().getPublicData("viewbook?id=${user.id}").then((response) {
        setState(() {
          Iterable list = json.decode(response.body);
          // print(list);
          Iterable firstArray = [];
          List<dynamic> bb = [];
          for (var element in list) {
            if (element.isNotEmpty) {
              for (var item in element) {
                bb.add(item);
                // print(item);
              }
            }
          }
          firstArray = bb;

          books = firstArray.map((model) => Books2.fromJson(model)).toList();
        });
      });
    } catch (e) {
      // print('failed to get books');
    }
    // books.clear();
  }

  String splitPath(url) {
    File file = File(url);
    String filename = file.path.split(Platform.pathSeparator).last;
    return filename;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: files.isEmpty && books.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 50,
                    ),
                    SizedBox(height: 10),
                    Text('No Books assigned')
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: checkConnectivity,
                child: (files.isNotEmpty && !activeConnection)
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Adjust for responsiveness
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.7, // Adjust as needed
                        ),
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          var file = files[index];

                          return GestureDetector(
                            onTap: () {
                              saveCurrentBook(file.title);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      NavPdf(books: file, path: ''),
                                ),
                              );
                            },
                            // child: Column(
                            //   crossAxisAlignment: CrossAxisAlignment.center,
                            //   children: [
                            //     ClipRRect(
                            //       borderRadius: BorderRadius.circular(10),
                            //       child: file.path.isNotEmpty
                            //           ? Image.file(
                            //               File(file.path),
                            //               height: 180,
                            //               width: 130,
                            //               fit: BoxFit.fill,
                            //             )
                            //           : Image.asset(
                            //               "img/CK_logo.png",
                            //               height: 180,
                            //               width: 130,
                            //               fit: BoxFit.fill,
                            //             ),
                            //     ),
                            //     const SizedBox(height: 8),
                            //     Text(
                            //       file.title,
                            //       textAlign: TextAlign.center,
                            //       style: GoogleFonts.prompt(
                            //         fontWeight: FontWeight.bold,
                            //         fontSize: 14,
                            //       ),
                            //       maxLines: 2,
                            //       overflow: TextOverflow.ellipsis,
                            //     ),
                            //   ],
                            // ),

                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Expanded(
                                  //   child: ClipRRect(
                                  //     borderRadius: BorderRadius.circular(10),
                                  //     child: file.path.isNotEmpty
                                  //         ? Image.file(
                                  //             File(file.path),
                                  //             fit: BoxFit.cover,
                                  //             width: double.infinity,
                                  //           )
                                  //         : Image.asset(
                                  //             "img/CK_logo.png",
                                  //             fit: BoxFit.cover,
                                  //             width: double.infinity,
                                  //           ),
                                  //   ),
                                  // ),
                                  Expanded(
                                    child: file.path.isNotEmpty
                                        ? Image.file(
                                            File(file.path),
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          )
                                        : Image.asset(
                                            "img/CK_logo.png",
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    file.title,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.prompt(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(10.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 columns
                          crossAxisSpacing: 10.0,
                          mainAxisSpacing: 10.0,
                          childAspectRatio: 0.7, // Adjust for better proportion
                        ),
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DetailBookPage(bookInfo: book, index: 0),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Image.network(
                                      host + books[index].picurl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/logo.png',
                                        ); // Local fallback
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      books[index].title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }

  Future<void> saveCurrentBook(bookName) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    localStorage.setString('currentBook', bookName);
  }
}
