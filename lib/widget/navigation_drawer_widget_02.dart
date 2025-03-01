import 'dart:io';

import 'package:ebooks/app_util.dart';
import 'package:ebooks/data/drawer_items.dart';
import 'package:ebooks/models/drawer_item.dart';
import 'package:ebooks/pages/nav_main.dart';
import 'package:ebooks/provider/navigation_provider2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pdf_tile.dart';

class NavigationDrawerWidget2 extends StatefulWidget {
  final Function(String, String) updateData;

  const NavigationDrawerWidget2({super.key, required this.updateData});

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
  List<PdfTile> filteredItems = [];
  bool searchActivate = false;
  String selectedPdf = '';
  String pdfPath = '';
  String title = '';

  getSpfBook() async {
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    setState(() {
      currentBook = localStorage.getString('currentBook')!;
    });
  }

  getASD() async {
    dir = await getApplicationSupportDirectory();
    setState(() {
      pathFile = '${dir.path}/$currentBook/cover_image';
    });
  }

  @override
  void initState() {
    getSpfBook();
    getProviderFiles();
    getASD();
    super.initState();
  }

  getProviderFiles() {
    final provider = Provider.of<NavigationProvider2>(context, listen: false);
    setState(() {
      files = provider.files;
      selectedPdf = provider.selectedpdf;
    });
    if (files.isEmpty) {
      getDownloadedBooks();
    }
  }

  bool _checkDirectoryExistsSync(String path) {
    // print(Directory(path).existsSync());
    return Directory(path).existsSync();
  }

  getDownloadedBooks() async {
    files.clear();
    SharedPreferences localStorage = await SharedPreferences.getInstance();
    setState(() {
      currentBook = localStorage.getString('currentBook')!;
    });
    // final List<PdfTile> listOfChild = [];
    var foldrChild = await AppUtil().readFilesDir(currentBook);
    if (foldrChild != null) {
      foldrChild.forEach((element) async {
        // print("starting get chapter...");
        // print(element.path);
        List<PdfTile> secondChild = [];
        if (element.path.isNotEmpty &&
            AppUtil().splitPath(element.path).toString() != "cover_image") {
          // print(element.path);
          var split = AppUtil().splitPath(element.path);
          var foldrChild2 = await AppUtil().readFilesDir('$currentBook/$split');
          // print(foldrChild2);
          if (foldrChild2 != null) {
            foldrChild2.forEach((child) async {
              // print('getting lessons');
              List<PdfTile> thirdChild = [];
              // print(child.path);
              // get the inner if has parts
              // false if no parts and child is a file directory
              //check if its directory
              var splitted = AppUtil().splitPath(child.path);
              bool isDirectory = _checkDirectoryExistsSync(
                  '${dir.path}/$currentBook/$split/$splitted');
              if (child != null && isDirectory) {
                // print('yes its a directory!');
                var split2 = AppUtil().splitPath(child.path);
                var foldrChild3 =
                    await AppUtil().readFilesDir('$currentBook/$split/$split2');
                // print(foldrChild3);
                if (foldrChild3 != null) {
                  foldrChild3.forEach((item) {
                    // print('lesson detected');
                    setState(() {
                      thirdChild.add(
                        PdfTile(
                            title: AppUtil().splitPath(item.path),
                            path: item.path,
                            isExpanded: false),
                      );
                    });
                  });
                }
                if (thirdChild.isNotEmpty) {
                  setState(() {
                    secondChild.add(
                      PdfTile(
                        title: AppUtil().splitPath(child.path),
                        path: child.path,
                        children: thirdChild,
                        isExpanded: false,
                      ),
                    );
                  });
                } else {
                  setState(() {
                    secondChild.add(
                      PdfTile(
                        title: AppUtil().splitPath(child.path),
                        path: child.path,
                        isExpanded: false,
                      ),
                    );
                  });
                }
              } else {
                setState(() {
                  secondChild.add(
                    PdfTile(
                      title: AppUtil().splitPath(child.path),
                      path: child.path,
                      isExpanded: false,
                    ),
                  );
                });
              }
            });
          }
          setState(() {
            files.add(
              PdfTile(
                title: AppUtil().splitPath(element.path),
                path: element.path,
                children: secondChild,
                isExpanded: false,
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

  List<PdfTile> flattenNestedArray(List<PdfTile> nestedArray) {
    List<PdfTile> flattenedArray = [];

    for (var object in nestedArray) {
      // flattenedArray.add(object);
      if (object.children.isNotEmpty) {
        List<PdfTile> innerChld = object.children;
        for (var element in innerChld) {
          var isDir = _checkDirectoryExistsSync(element.path);
          if (isDir) {
            if (element.children.isNotEmpty) {
              var fldr = element.children;
              for (var elem in fldr) {
                var isFldr = _checkDirectoryExistsSync(elem.path);
                if (!isFldr) {
                  flattenedArray.addAll(fldr);
                  continue;
                }
              }
            }
          } else {
            flattenedArray.addAll(innerChld);
            continue;
          }
        }
      }
    }

    return flattenedArray;
  }

  void filterSearchResults(String query) {
    List<PdfTile> flattenedArray = [];
    List<PdfTile> searchResults = [];

    if (query.isNotEmpty) {
      flattenedArray = flattenNestedArray(files);
      // for (var object in flattenedArray) {
      //   // print(object.title);
      // }

      searchResults = flattenedArray.where((element) {
        if (element.title.toLowerCase().contains(query.toLowerCase())) {
          return true;
        }
        return searchResults.isNotEmpty;
      }).toList();
    } else {
      setState(() {
        searchActivate = false;
      });
    }
    setState(() {
      filteredItems = searchResults.toSet().toList();
    });
  }

  // Custom comparator function
  int customComparator(PdfTile a, PdfTile b) {
    bool aIsLetter = a.title[0].toUpperCase() != a.title[0].toLowerCase();
    bool bIsLetter = b.title[0].toUpperCase() != b.title[0].toLowerCase();
    bool aIsColon = a.title[0] == ':';
    bool bIsColon = b.title[0] == ':';
    bool aContainsConsecutiveNumbers = RegExp(r'\d{2}').hasMatch(a.title);
    bool bContainsConsecutiveNumbers = RegExp(r'\d{2}').hasMatch(b.title);

    if (!aContainsConsecutiveNumbers && bContainsConsecutiveNumbers) {
      return -1; // a comes before b (a doesn't contain consecutive numbers)
    } else if (aContainsConsecutiveNumbers && !bContainsConsecutiveNumbers) {
      return 1; // b comes before a (b doesn't contain consecutive numbers)
    } else if (aIsLetter && !bIsLetter) {
      return -1; // a comes before b (b contains consecutive numbers)
    } else if (!aIsLetter && bIsLetter) {
      return 1; // b comes before a (a contains consecutive numbers)
    } else if (aIsColon && !bIsColon) {
      return 1; // b comes before a (a is a colon)
    } else if (!aIsColon && bIsColon) {
      return -1; // a comes before b (b is a colon)
    } else {
      return a.title
          .compareTo(b.title); // If both are letters or numbers, sort normally
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;
    final safeArea =
        EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top);

    final provider = Provider.of<NavigationProvider2>(context);
    var isCollapsed = provider.isCollapsed;
    files.sort(customComparator);
    return SizedBox(
      width: isCollapsed ? MediaQuery.of(context).size.width * 0.2 : null,
      child: Drawer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF221484), Color(0xFF221484)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          // color: const Color(0xff292735),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                ).add(safeArea),
                width: double.infinity,
                color: Colors.white10,
                child: buildHeader(isCollapsed),
              ),
              const SizedBox(height: 5),
              buildList(items: itemsFirst3, isCollapsed: isCollapsed),
              const Divider(
                color: Colors.white24,
              ),
              Container(
                padding: const EdgeInsets.only(left: 10.0, right: 8.0),
                child: TextField(
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchActivate = true;
                      filterSearchResults(value);
                    });
                  },
                  decoration: const InputDecoration(
                    labelStyle: TextStyle(color: Colors.white),
                    labelText: 'Search lesson',
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Divider(
                color: Colors.white24,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: files.isNotEmpty && !searchActivate
                      ? buildTile(isCollapsed: isCollapsed, items: files)
                      : filteredItems.isNotEmpty && searchActivate
                          ? buildTile2(
                              isCollapsed: isCollapsed, items: filteredItems)
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
                              color: Colors.white,
                              size: 18.0,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Text(
                              'Copyright $currentYear',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Powered by',
                              style: GoogleFonts.poppins(
                                  color: Colors.white, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.transparent,
                              child: Image.asset(
                                "img/cklogo.png",
                                height: 25,
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
                  : CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.transparent,
                      child: Image.asset(
                        "img/cklogo.png",
                        height: 25,
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

  Widget buildTile2({
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

          return buildMenuItemTiles2(
            isCollapsed: isCollapsed,
            text: item.title,
            path: item.path,
          );
        },
      );
  Widget buildMenuItemTiles2({
    required bool isCollapsed,
    required String text,
    required String path,
  }) {
    const color = Color.fromRGBO(70, 191, 247, 1);
    const leadingPdf = Icon(Icons.menu_book, color: color);

    return Material(
      color: Colors.transparent,
      child: isCollapsed
          ? const ListTile(
              title: leadingPdf,
              // onTap: onClicked,
            )
          : ListTile(
              leading: selectedPdf == text
                  ? const Icon(
                      Icons.menu_book,
                      color: Colors.greenAccent,
                    )
                  : leadingPdf,
              onTap: () {
                final provider =
                    Provider.of<NavigationProvider2>(context, listen: false);
                setState(() {
                  selectedPdf = text;
                });

                provider.selectPdf(text);
                widget.updateData(path, text);
              },
              title: Text(
                removeFileExtension(text),
                style: TextStyle(
                    color:
                        selectedPdf == text ? Colors.greenAccent : Colors.white,
                    fontSize: 15),
              ),
            ),
    );
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
              c2.add(PdfTile(
                  title: elem.title, path: elem.path, isExpanded: false));
            }
          }
          c2.sort(customComparator);

          return buildMenuItemTiles(
            item: item,
            isCollapsed: isCollapsed,
            text: item.title,
            path: item.path,
            child: c1,
            innerChild: c2,
            icon: Icons.add_circle_outline,
            index: index,
            // items: item.lessons,
          );
        },
      );

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

  Widget buildMenuItemTiles({
    required PdfTile item,
    required bool isCollapsed,
    required String text,
    required String path,
    required List<PdfTile> child,
    required List<PdfTile> innerChild,
    required IconData icon,
    required int index,
  }) {
    const color = Colors.white;
    const blue = Color.fromRGBO(70, 191, 247, 1);
    const color2 = Colors.greenAccent;
    const color3 = Colors.red;
    // final color2 = Colors.pink.shade400;
    const leadingPdf = Icon(Icons.menu_book, color: blue);
    const leadingVidSelected =
        Icon(Icons.play_circle_outline, color: Colors.greenAccent);
    const leadingVid = Icon(Icons.play_circle_outline, color: Colors.orange);
    final leading = Icon(icon, color: color2);
    child.sort(customComparator);
    innerChild.sort(customComparator);

    return Material(
      color: Colors.transparent,
      child: isCollapsed
          ? ListTile(
              title: leading,
              // onTap: onClicked,
            )
          : ListTile(
              horizontalTitleGap: 0,
              contentPadding: const EdgeInsets.all(0),
              selectedTileColor: color3,
              minLeadingWidth: 0,
              minVerticalPadding: 0,
              leading: item.isExpanded
                  ? const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.yellowAccent,
                    )
                  : leading,
              title: ExpansionTile(
                onExpansionChanged: (bool expanded) {
                  setState(() {
                    item.isExpanded = expanded;
                  });
                },
                initiallyExpanded: item.isExpanded,
                collapsedIconColor: color,
                childrenPadding: const EdgeInsets.all(0),
                title: Text(
                  text,
                  style: GoogleFonts.poppins(
                      color: color, fontSize: 15, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  softWrap: true,
                ),
                children: innerChild.isEmpty
                    ? child
                        .map(
                          (et) => ListTile(
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(4),
                              ),
                            ),
                            leading: (selectedPdf == et.title &&
                                    getFileExtension(et.title) == ".pdf")
                                ? const Icon(
                                    Icons.menu_book,
                                    color: Colors.greenAccent,
                                  )
                                : (selectedPdf == et.title &&
                                        getFileExtension(et.title) == ".mp4")
                                    ? leadingVidSelected
                                    : (selectedPdf != et.title &&
                                            getFileExtension(et.title) ==
                                                ".mp4")
                                        ? leadingVid
                                        : leadingPdf,

                            horizontalTitleGap: 0,
                            contentPadding: const EdgeInsets.only(
                              left: 4,
                              right: 4,
                            ),
                            tileColor: selectedPdf == et.title
                                ? Colors.white24
                                : Colors.transparent,
                            onTap: () {
                              final provider = Provider.of<NavigationProvider2>(
                                  context,
                                  listen: false);
                              setState(() {
                                selectedPdf = et.title;
                              });

                              provider.selectPdf(et.title);
                              widget.updateData(et.path, et.title);
                            },
                            title: Text(
                              removeFileExtension(et.title),
                              style: GoogleFonts.poppins(
                                  color: selectedPdf == et.title
                                      ? Colors.greenAccent
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            // onTap: onClicked,
                          ),
                        )
                        .toList()
                    : child.map((e) {
                        return ListTile(
                          minLeadingWidth: 0,
                          minVerticalPadding: 0,
                          leading: e.isExpanded
                              ? const Icon(
                                  Icons.remove_circle_outline,
                                  color: Colors.yellowAccent,
                                )
                              : leading,
                          horizontalTitleGap: 0,
                          contentPadding: const EdgeInsets.all(0),
                          title: ExpansionTile(
                            onExpansionChanged: (bool expanded) {
                              setState(() {
                                e.isExpanded = expanded;
                              });
                            },
                            initiallyExpanded: e.isExpanded,
                            collapsedIconColor: color,
                            title: Text(
                              e.title,
                              style: GoogleFonts.poppins(
                                color: color,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            children: e.children.map((item) {
                              return ListTile(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(4),
                                    ),
                                  ),
                                  horizontalTitleGap: 0,
                                  contentPadding:
                                      const EdgeInsets.only(left: 3),
                                  leading: (selectedPdf == item.title &&
                                          getFileExtension(item.title) ==
                                              ".pdf")
                                      ? const Icon(
                                          Icons.menu_book,
                                          color: Colors.greenAccent,
                                        )
                                      : (selectedPdf == item.title &&
                                              getFileExtension(item.title) ==
                                                  ".mp4")
                                          ? leadingVidSelected
                                          : (selectedPdf != item.title &&
                                                  getFileExtension(
                                                          item.title) ==
                                                      ".mp4")
                                              ? leadingVid
                                              : leadingPdf,
                                  tileColor: selectedPdf == item.title
                                      ? Colors.white24
                                      : Colors.transparent,
                                  onTap: () {
                                    final provider =
                                        Provider.of<NavigationProvider2>(
                                            context,
                                            listen: false);
                                    setState(() {
                                      selectedPdf = item.title;
                                    });

                                    provider.selectPdf(item.title);
                                    widget.updateData(item.path, item.title);
                                  },
                                  title: Text(
                                    removeFileExtension(item.title),
                                    style: GoogleFonts.poppins(
                                        color: selectedPdf == item.title
                                            ? Colors.greenAccent
                                            : Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  )
                                  // onTap: onClicked,
                                  );
                            }).toList(),
                          ),
                        );
                      }).toList(),
              ),
            ),
    );
  }

  String removeFileExtension(String fileName) {
    int dotIndex = fileName.lastIndexOf('_');
    if (dotIndex != -1) {
      return fileName.substring(0, dotIndex);
    } else {
      return fileName;
    }
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
    navigateTo(page) => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => page,
        ),
        (Route<dynamic> route) => false);

    Navigator.of(context).pop();

    switch (index) {
      case 0:
        navigateTo(const MyNav());
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
              color: Colors.white,
              size: 20,
            ),
          ),
          onTap: () {
            final provider =
                Provider.of<NavigationProvider2>(context, listen: false);

            provider.toggleIsCollapsed2();
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
            // return Image.asset('img/liceo-logo.png');
            return const CircularProgressIndicator();
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
                    return const CircularProgressIndicator();
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Text(
                currentBook,
                style: GoogleFonts.prompt(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                softWrap: true,
              ),
            )
          ],
        );
}
