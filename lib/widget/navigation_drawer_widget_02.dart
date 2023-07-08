import 'dart:io';

import 'package:ebooks/app_util.dart';
import 'package:ebooks/data/drawer_items.dart';
import 'package:ebooks/models/drawer_item.dart';
import 'package:ebooks/pages/classmate_page.dart';
import 'package:ebooks/pages/nav_main.dart';
import 'package:ebooks/pdf_view/pdf_view.dart';
import 'package:ebooks/provider/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pdf_tile.dart';
import '../pages/nav_pdf.dart';
import '../pages/profile_page.dart';

class NavigationDrawerWidget2 extends StatefulWidget {
  const NavigationDrawerWidget2({super.key});

  @override
  State<NavigationDrawerWidget2> createState() =>
      _NavigationDrawerWidget2State();
}

class _NavigationDrawerWidget2State extends State<NavigationDrawerWidget2> {
  final padding = const EdgeInsets.symmetric(horizontal: 20);
  late List<PdfTile> files = [];
  late String currentBook = '';
  String pathFile = '';
  late Directory dir;

  getASD() async {
    dir = await getApplicationSupportDirectory();
    pathFile = '${dir.path}/$currentBook/cover_image';
  }

  @override
  void initState() {
    getASD();
    getDownloadedBooks();
    super.initState();
  }

  bool _checkDirectoryExistsSync(String path) {
    print(Directory(path).existsSync());
    return Directory(path).existsSync();
  }

  getDownloadedBooks() async {
    files.clear();
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    currentBook = localStorage.getString('currentBook')!;
    // final List<PdfTile> listOfChild = [];
    var foldrChild = await AppUtil().readFilesDir(currentBook);
    if (foldrChild != null) {
      foldrChild.forEach((element) async {
        print("starting get chapter...");
        print(element.path);
        List<PdfTile> secondChild = [];
        if (element.path.isNotEmpty &&
            splitPath(element.path).toString() != "cover_image") {
          print(element.path);
          var split = splitPath(element.path);
          var foldrChild2 = await AppUtil().readFilesDir('$currentBook/$split');
          // print(foldrChild2);
          if (foldrChild2 != null) {
            foldrChild2.forEach((child) async {
              print('getting lessons');
              List<PdfTile> thirdChild = [];
              print(child.path);
              // get the inner if has parts
              // false if no parts and child is a file directory
              //check if its directory
              var splitted = splitPath(child.path);
              bool isDirectory = _checkDirectoryExistsSync(
                  '${dir.path}/$currentBook/$split/$splitted');
              if (child != null && isDirectory) {
                print('yes its a directory!');
                var split2 = splitPath(child.path);
                var foldrChild3 =
                    await AppUtil().readFilesDir('$currentBook/$split/$split2');
                print(foldrChild3);
                if (foldrChild3 != null) {
                  foldrChild3.forEach((item) {
                    print('lesson detected');
                    setState(() {
                      thirdChild.add(
                        PdfTile(title: splitPath(item.path), path: item.path),
                      );
                    });
                  });
                }
                if (thirdChild.isNotEmpty) {
                  setState(() {
                    secondChild.add(
                      PdfTile(
                        title: splitPath(child.path),
                        path: child.path,
                        children: thirdChild,
                      ),
                    );
                  });
                } else {
                  setState(() {
                    secondChild.add(
                      PdfTile(
                        title: splitPath(child.path),
                        path: child.path,
                      ),
                    );
                  });
                }
              } else {
                setState(() {
                  secondChild.add(
                    PdfTile(
                      title: splitPath(child.path),
                      path: child.path,
                    ),
                  );
                });
              }
            });
          }
          setState(() {
            files.add(
              PdfTile(
                title: splitPath(element.path),
                path: element.path,
                children: secondChild,
              ),
            );
            // secondChild.clear();
          });
        }
      });
    }
  }

  String split(url) {
    File file = File(url);
    String filename = file.path.split(Platform.pathSeparator).last;
    return filename;
  }

  @override
  Widget build(BuildContext context) {
    final safeArea =
        EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top);

    final provider = Provider.of<NavigationProvider>(context);
    var isCollapsed = provider.isCollapsed;

    return SizedBox(
      width: isCollapsed ? MediaQuery.of(context).size.width * 0.2 : null,
      child: Drawer(
        child: Container(
          color: const Color(0xff292735),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                ).add(safeArea),
                width: double.infinity,
                color: Colors.white12,
                child: buildHeader(isCollapsed),
              ),
              // const SizedBox(height: 5),
              buildList(items: itemsFirst3, isCollapsed: isCollapsed),
              // const Text(
              //   'Book Lessons',
              //   style: TextStyle(color: Colors.white, fontSize: 17),
              //   textAlign: TextAlign.center,
              // ),
              // const SizedBox(height: 5),
              const Divider(
                color: Colors.white24,
              ),

              const SizedBox(
                height: 5,
              ),
              const Text(
                "search here",
                style: TextStyle(color: Colors.white),
              ),

              const Divider(
                color: Colors.white24,
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: files.isNotEmpty
                      ? buildTile(isCollapsed: isCollapsed, items: files)
                      : const Center(
                          child: Center(
                            child: Text(
                              "No Files",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                ),
              ),
              !isCollapsed
                  ? Center(
                      child: Container(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.copyright_outlined,
                              color: Colors.white38,
                              size: 20.0,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            const Text(
                              'Copyright 2023',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              'Powered by',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            ColoredBox(
                              color: Colors.white12,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Image.asset(
                                  'img/cklogo.png',
                                  height: 30,
                                  width: 30,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            buildCollapseIcon(context, isCollapsed),
                          ],
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(
                          left: 1.0, right: 1.0, bottom: 4.0),
                      child: ColoredBox(
                        color: Colors.white12,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'img/cklogo.png',
                            height: 30,
                            width: 30,
                          ),
                        ),
                      ),
                    ),
              isCollapsed
                  ? buildCollapseIcon(context, isCollapsed)
                  : const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  onClick(path) {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MyNav2(
            path: path,
            books: const PdfTile(
              title: '',
              path: '',
            ),
          ),
        ),
        (Route<dynamic> route) => false);
    // print(path);
  }

  // Pdf Tile
  Widget buildTile({
    required bool isCollapsed,
    required List<PdfTile> items,
    int indexOffset = 0,
  }) =>
      ListView.separated(
        padding: isCollapsed ? EdgeInsets.zero : padding,
        shrinkWrap: true,
        primary: false,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          var c1 = item.children;
          List<PdfTile> c2 = [];
          for (var elem in c1) {
            if (elem.children.isNotEmpty) {
              c2.add(PdfTile(title: elem.title, path: elem.path));
            }
          }

          return buildMenuItemTiles(
            isCollapsed: isCollapsed,
            text: item.title,
            path: item.path,
            child: item.children,
            innerChild: c2,
            icon: Icons.folder_rounded,
            // items: item.lessons,
          );
        },
      );

  Widget buildMenuItemTiles({
    required bool isCollapsed,
    required String text,
    required String path,
    required List<PdfTile> child,
    required List<PdfTile> innerChild,
    required IconData icon,
    // required List<PdfTile> items,
    // VoidCallback? onClicked,
  }) {
    final color = Colors.pink.shade50;
    const color2 = Colors.yellow;
    const color3 = Color.fromARGB(255, 229, 100, 100);
    // final color2 = Colors.pink.shade400;
    const leadingPdf = Icon(Icons.picture_as_pdf_sharp, color: color3);
    final leading = Icon(icon, color: color2);

    return Material(
      color: Colors.transparent,
      child: isCollapsed
          ? ListTile(
              title: leading,
              // onTap: onClicked,
            )
          : ListTile(
              minLeadingWidth: 0,
              minVerticalPadding: 0,
              leading: leading,
              title: ExpansionTile(
                collapsedIconColor: color,
                childrenPadding: const EdgeInsets.all(0),
                title: Text(
                  text,
                  style: TextStyle(color: color, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  softWrap: true,
                ),
                children: innerChild.isEmpty
                    ? child
                        .map((et) => ListTile(
                            onTap: () => onClick(et.path),
                            title: Text(
                              et.title,
                              style:
                                  const TextStyle(color: color3, fontSize: 15),
                            )
                            // onTap: onClicked,
                            ))
                        .toList()
                    : child.map((e) {
                        return ExpansionTile(
                          collapsedIconColor: color,
                          title: Text(
                            e.title,
                            style: TextStyle(color: color, fontSize: 15),
                          ),
                          children: e.children.map((item) {
                            return ListTile(
                                onTap: () => onClick(item.path),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(
                                      color: color3, fontSize: 15),
                                )
                                // onTap: onClicked,
                                );
                          }).toList(),
                        );
                      }).toList(),
              ),

              // title: ExpansionTile(

              //   collapsedIconColor: color,
              //   title: Text(
              //     text,
              //     style: TextStyle(color: color, fontSize: 16),
              //     overflow: TextOverflow.ellipsis,
              //     maxLines: 2,
              //     softWrap: true,
              //   ),
              //   children: child.isNotEmpty
              //       ? child
              //           .map(
              //             (e) => ListTile(
              //                 onTap: () =>
              //                     e.children.isEmpty ? onClick(e.path) : {},
              //                 leading:
              //                     (e.children.isEmpty) ? leadingPdf : leading,
              //                 title: child2.isNotEmpty
              //                     ? ExpansionTile(
              //                         leading: leading,
              //                         title: Text(
              //                           e.title,
              //                           style: const TextStyle(
              //                               color: Colors.white),
              //                         ),
              //                         children: child2
              //                             .map((em) => ListTile(
              //                                   leading: leadingPdf,
              //                                   title: Text(
              //                                     em.title,
              //                                     style: const TextStyle(
              //                                         color: Colors.white),
              //                                   ),
              //                                 ))
              //                             .toList(),
              //                       )
              //                     : Text(
              //                         e.title,
              //                         style:
              //                             const TextStyle(color: Colors.white),
              //                       )),
              //           )
              //           .toList()
              //       : [
              //           const ListTile(
              //             title: Text(
              //               'empty',
              //               style: TextStyle(color: Colors.white),
              //             ),
              //           ),
              //         ],
              // ),
            ),
    );
  }

  // Main Nav tile
  Widget buildList({
    required bool isCollapsed,
    required List<DrawerItem> items,
    int indexOffset = 0,
  }) =>
      ListView.separated(
        padding: isCollapsed ? EdgeInsets.zero : padding,
        shrinkWrap: true,
        primary: false,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = items[index];

          return buildMenuItem(
            isCollapsed: isCollapsed,
            text: item.title,
            icon: item.icon,
            onClicked: () => selectItem(context, indexOffset + index),
          );
        },
      );

  void selectItem(BuildContext context, int index) {
    navigateTo(page) => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => page,
        ));

    Navigator.of(context).pop();

    switch (index) {
      case 0:
        navigateTo(const MyNav());
        break;
      case 1:
        navigateTo(const Classmate());
        break;
      case 2:
        navigateTo(const ProfilePage());
        break;
    }
  }

  Widget buildMenuItem({
    required bool isCollapsed,
    required String text,
    required IconData icon,
    VoidCallback? onClicked,
  }) {
    const color = Colors.white;
    final leading = Icon(icon, color: color);

    return Material(
      color: Colors.transparent,
      child: isCollapsed
          ? ListTile(
              title: leading,
              onTap: onClicked,
            )
          : ListTile(
              leading: leading,
              title: Text(text,
                  style: const TextStyle(color: color, fontSize: 16)),
              onTap: onClicked,
            ),
    );
  }

  Widget buildCollapseIcon(BuildContext context, bool isCollapsed) {
    const double size = 30;
    final icon = isCollapsed
        ? Icons.arrow_forward_ios_rounded
        : Icons.arrow_back_ios_rounded;
    final alignment = isCollapsed ? Alignment.center : Alignment.centerRight;
    // final margin = isCollapsed ? null : const EdgeInsets.only(right: 16);
    final width = isCollapsed ? double.infinity : size;

    return Container(
      alignment: alignment,
      // margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          child: SizedBox(
            width: width,
            height: size,
            child: Icon(
              icon,
              color: const Color(0xE7E91E63),
              size: 20,
            ),
          ),
          onTap: () {
            final provider =
                Provider.of<NavigationProvider>(context, listen: false);

            provider.toggleIsCollapsed();
          },
        ),
      ),
    );
  }

  Widget buildCollapseIcon2(BuildContext context, bool isCollapsed) {
    const double size = 52;
    final icon = isCollapsed
        ? Icons.arrow_back_ios_rounded
        : Icons.arrow_forward_ios_rounded;
    final alignment = isCollapsed ? Alignment.center : Alignment.centerRight;
    final margin = isCollapsed ? null : const EdgeInsets.only(right: 16);
    final width = isCollapsed ? double.infinity : size;

    return Container(
      alignment: alignment,
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          child: SizedBox(
            width: width,
            height: size,
            child: Icon(icon, color: const Color(0xE7E73A6E)),
          ),
          onTap: () {
            final provider =
                Provider.of<NavigationProvider>(context, listen: false);

            provider.toggleIsCollapsed();
          },
        ),
      ),
    );
  }

  Widget buildHeader(bool isCollapsed) => isCollapsed
      ? Image.file(
          height: 50,
          width: 50,
          File(pathFile),
          errorBuilder:
              (BuildContext context, Object exception, StackTrace? stackTrace) {
            // Return a fallback image or widget when an error occurs
            return Image.asset('img/liceo-logo.png');
          },
        )
      : Row(
          children: [
            const SizedBox(width: 24),
            Expanded(
              child: SizedBox(
                width: 50,
                child: Image.file(
                  width: 50,
                  height: 50,
                  File(pathFile),
                  fit: BoxFit.fill,
                  errorBuilder: (BuildContext context, Object exception,
                      StackTrace? stackTrace) {
                    // Return a fallback image or widget when an error occurs
                    return Image.asset('img/liceo-logo.png');
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Text(
                currentBook,
                style: const TextStyle(fontSize: 18, color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                softWrap: true,
              ),
            )
          ],
        );
}
