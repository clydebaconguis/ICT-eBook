import 'dart:convert';
import 'dart:io';
import 'package:ebooks/api/my_api.dart';
import 'package:ebooks/app_util.dart';
import 'package:ebooks/pages/nav_pdf.dart';
import 'package:ebooks/signup_login/sign_in.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

  getDownloadedBooks() async {
    books.clear();
    files.clear();
    var result = await AppUtil().readBooks();
    late String imgUrl = '';
    final List<PdfTile> listOfChild = [];
    listOfChild.clear();
    result.forEach(
      (item) async {
        // print(item);
        var foldrName = splitPath(item.path);
        var foldrChild = await AppUtil().readFilesDir(foldrName);
        if (foldrChild.isNotEmpty) {
          foldrChild.forEach((element) {
            // print(element);
            if (splitPath(element.path).toString() == "cover_image") {
              imgUrl = element.path;
            }
            if (element.path.isNotEmpty &&
                splitPath(element.path).toString() != "cover_image") {
              listOfChild.add(
                PdfTile(
                    title: splitPath(element.path),
                    path: element.path,
                    isExpanded: false),
              );
            }
          });
        }
        setState(
          () {
            files.add(
              PdfTile(
                  title: foldrName,
                  path: imgUrl,
                  children: listOfChild,
                  isExpanded: false),
            );
          },
        );
        imgUrl = '';
        listOfChild.clear();
      },
    );
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
  }

  String splitPath(url) {
    File file = File(url);
    String filename = file.path.split(Platform.pathSeparator).last;
    return filename;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      // bool isWide = constraints.maxWidth > 500;
      return Scaffold(
        body: Container(
          color: Colors.white,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: RefreshIndicator(
                      onRefresh: () => checkConnectivity(),
                      child: (files.isNotEmpty && !activeConnection)
                          ? SingleChildScrollView(
                              child: Column(
                                children: files.asMap().keys.toList().map(
                                  (
                                    index,
                                  ) {
                                    var file = files[index];
                                    // debugPrint(file.path.toString());
                                    return GestureDetector(
                                      onTap: () {
                                        saveCurrentBook(file.title);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => NavPdf(
                                              books: file,
                                              path: '',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                            left: 20, right: 20),
                                        height: 250,
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 5,
                                              right: 5,
                                              top: 35,
                                              child: Material(
                                                elevation: 0,
                                                child: Container(
                                                  height: 180.0,
                                                  width: width * 0.9,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5.0),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey
                                                            .withOpacity(0.2),
                                                        offset: const Offset(
                                                            0.0, 0.0),
                                                        blurRadius: 18.0,
                                                        spreadRadius: 4.0,
                                                      )
                                                    ],
                                                  ),
                                                  // child: Text("This is where your content goes")
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 0,
                                              left: 12,
                                              child: Card(
                                                color: Colors.transparent,
                                                elevation: 10.0,
                                                shadowColor: Colors.grey
                                                    .withOpacity(0.5),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15.0),
                                                ),
                                                child: file.path.isNotEmpty
                                                    ? Container(
                                                        height: 200,
                                                        width: 150,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                          image:
                                                              DecorationImage(
                                                            image: FileImage(
                                                                File(
                                                                    file.path)),
                                                            fit: BoxFit.fill,
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        height: 200,
                                                        width: 150,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                          image:
                                                              const DecorationImage(
                                                            image: AssetImage(
                                                                "img/CK_logo.png"),
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 47,
                                              left: width * 0.5 - 5,
                                              child: SizedBox(
                                                height: 180,
                                                width: 150,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      file.title,
                                                      style: GoogleFonts.prompt(
                                                        textStyle:
                                                            const TextStyle(
                                                                color: Colors
                                                                    .black87,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                fontSize: 18),
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 3,
                                                      softWrap: true,
                                                    ),
                                                    const Divider(),
                                                    ListTile(
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              0),
                                                      horizontalTitleGap: 0,
                                                      minVerticalPadding: 0,
                                                      minLeadingWidth: 0,
                                                      leading: const Icon(
                                                        Icons
                                                            .download_done_rounded,
                                                        color: Colors.green,
                                                        textDirection:
                                                            TextDirection.ltr,
                                                      ),
                                                      // title: Text(
                                                      //   "Downloaded",
                                                      //   style: TextStyle(
                                                      //     fontWeight:
                                                      //         FontWeight.bold,
                                                      //     color: Colors.black54,
                                                      //     fontSize: 15,
                                                      //   ),
                                                      // ),
                                                      title: Text(
                                                        "Downloaded",
                                                        style:
                                                            GoogleFonts.prompt(
                                                          textStyle:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .green,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                  fontSize: 15),
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                        softWrap: true,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: books.map(
                                  (book) {
                                    return GestureDetector(
                                      onTap: () {
                                        // print(book.bookid);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DetailBookPage(
                                                    bookInfo: book, index: 0),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.only(
                                            left: 20, right: 20),
                                        height: 250,
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              left: 5,
                                              right: 5,
                                              top: 35,
                                              child: Material(
                                                elevation: 0.0,
                                                child: Container(
                                                  height: 180.0,
                                                  width: width * 0.9,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5.0),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey
                                                            .withOpacity(0.2),
                                                        offset: const Offset(
                                                            0.0, 0.0),
                                                        blurRadius: 18.0,
                                                        spreadRadius: 4.0,
                                                      )
                                                    ],
                                                  ),
                                                  // child: Text("This is where your content goes")
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 0,
                                              left: 12,
                                              child: Card(
                                                color: Colors.transparent,
                                                elevation: 10.0,
                                                shadowColor: Colors.grey
                                                    .withOpacity(0.5),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15.0),
                                                ),
                                                child: book.picurl.isNotEmpty
                                                    ? CachedNetworkImage(
                                                        imageUrl:
                                                            "$host${book.picurl}",
                                                        imageBuilder: (context,
                                                                imageProvider) =>
                                                            Container(
                                                          height: 200,
                                                          width: 150,
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10.0),
                                                            image:
                                                                DecorationImage(
                                                              image:
                                                                  imageProvider,
                                                              fit: BoxFit.fill,
                                                            ),
                                                          ),
                                                        ),
                                                        placeholder:
                                                            (context, url) =>
                                                                const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Container(
                                                          height: 200,
                                                          width: 150,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .grey
                                                                    .withOpacity(
                                                                        0.2),
                                                                spreadRadius:
                                                                    4.0,
                                                                blurRadius:
                                                                    20.0,
                                                                offset:
                                                                    const Offset(
                                                                        0, 3),
                                                              )
                                                            ],
                                                            image:
                                                                const DecorationImage(
                                                              image: AssetImage(
                                                                  "img/CK_logo.png"),
                                                              fit: BoxFit
                                                                  .contain,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        height: 200,
                                                        width: 150,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      10.0),
                                                          image:
                                                              const DecorationImage(
                                                            image: AssetImage(
                                                                "img/CK_logo.png"),
                                                          ),
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 47,
                                              left: width * 0.5 - 5,
                                              child: SizedBox(
                                                height: 180,
                                                width: 150,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Text(
                                                    //   book.title,
                                                    //   style: const TextStyle(
                                                    //     fontSize: 17,
                                                    //     fontWeight: FontWeight.bold,
                                                    //   ),
                                                    //   overflow: TextOverflow.ellipsis,
                                                    //   maxLines: 3,
                                                    //   softWrap: true,
                                                    // ),
                                                    Text(
                                                      book.title,
                                                      style: GoogleFonts.prompt(
                                                        textStyle:
                                                            const TextStyle(
                                                                color: Colors
                                                                    .black87,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w800,
                                                                fontSize: 18),
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 3,
                                                      softWrap: true,
                                                    ),
                                                    const Divider(),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: 2),
                                                      child: Row(
                                                        children: [
                                                          Text(
                                                            "Author:",
                                                            style: GoogleFonts
                                                                .poppins(
                                                              color: const Color(
                                                                  0xcd292735),
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 2,
                                                            softWrap: true,
                                                          ),
                                                          CircleAvatar(
                                                            radius: 15,
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            child: Image.asset(
                                                              "img/cklogo.png",
                                                              height: 25,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ).toList(),
                              ),
                            )
                      // : Center(
                      //     child: ConstrainedBox(
                      //       constraints:
                      //           const BoxConstraints(maxWidth: 900),
                      //       child: GridView.builder(
                      //         gridDelegate:
                      //             const SliverGridDelegateWithFixedCrossAxisCount(
                      //           crossAxisCount:
                      //               3, // Number of images per row
                      //           mainAxisSpacing: 15.0,
                      //           crossAxisSpacing: 0,
                      //         ),
                      //         itemCount: books.length,
                      //         itemBuilder: (context, index) {
                      //           final book = books[index];
                      //           return Card(
                      //             color: Colors.transparent,
                      //             elevation: 10.0,
                      //             shadowColor:
                      //                 Colors.grey.withOpacity(0.5),
                      //             shape: RoundedRectangleBorder(
                      //               borderRadius:
                      //                   BorderRadius.circular(5.0),
                      //             ),
                      //             child: book.picurl.isNotEmpty
                      //                 ? CachedNetworkImage(
                      //                     errorWidget:
                      //                         (context, url, error) =>
                      //                             Container(
                      //                       height: 200,
                      //                       width: 150,
                      //                       decoration: BoxDecoration(
                      //                         color: Colors.white,
                      //                         borderRadius:
                      //                             BorderRadius.circular(
                      //                                 10.0),
                      //                         image:
                      //                             const DecorationImage(
                      //                           image: AssetImage(
                      //                               "img/CK_logo.png"),
                      //                         ),
                      //                       ),
                      //                     ),
                      //                     imageUrl: '$host${book.picurl}',
                      //                     imageBuilder:
                      //                         (context, imageProvider) =>
                      //                             Container(
                      //                       height: 200,
                      //                       width: 150,
                      //                       decoration: BoxDecoration(
                      //                         borderRadius:
                      //                             BorderRadius.circular(
                      //                                 5.0),
                      //                         image: DecorationImage(
                      //                           image: imageProvider,
                      //                           fit: BoxFit.contain,
                      //                         ),
                      //                       ),
                      //                     ),
                      //                     // ... Rest of your CachedNetworkImage properties
                      //                   )
                      //                 : Container(
                      //                     height: 200,
                      //                     width: 150,
                      //                     decoration: BoxDecoration(
                      //                       color: Colors.white,
                      //                       borderRadius:
                      //                           BorderRadius.circular(
                      //                               10.0),
                      //                       image: const DecorationImage(
                      //                         image: AssetImage(
                      //                             "img/CK_logo.png"),
                      //                       ),
                      //                     ),
                      //                   ),
                      //           );
                      //         },
                      //       ),
                      //     ),
                      //   ),
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> saveCurrentBook(bookName) async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    localStorage.setString('currentBook', bookName);
  }
}
