import 'package:bell/screen_navigator.dart';
import 'package:bell/screens/media/media_vmodel.dart';
import 'package:bell/services/database.dart';
import 'package:bell/widgets/loading.dart';
import 'package:bell/widgets/error.dart';
import 'package:bell/widgets/radio_buttons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bell/general_functions.dart';
import 'package:bell/screens/search/search_vmodel.dart';
import 'package:dio/dio.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

// This is the type used by the popup menu below.
enum Menu { itemOne, itemTwo }

final GlobalKey topResultKey = GlobalKey();
final GlobalKey songsKey = GlobalKey();
final GlobalKey albumsKey = GlobalKey();
final GlobalKey artistsKey = GlobalKey();
final GlobalKey videosKey = GlobalKey();
final GlobalKey commPlaylistsKey = GlobalKey();
final GlobalKey featPlaylistsKey = GlobalKey();
final List keys = [
  topResultKey,
  songsKey,
  albumsKey,
  artistsKey,
  videosKey,
  commPlaylistsKey,
  featPlaylistsKey,
];

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  State<Search> createState() => _SearchState();
}

late int _value;
late bool isTextFieldEmpty;
late bool isTextFieldFocused;
late bool showFilters;
late TextEditingController searchController;
late FocusNode searchFocus;
late CancelToken cancelToken;
late String selectedMenu;
late String query;
late ScreenNavigator _screenNavigator;

late User _user;
late Database _database;

class _SearchState extends State<Search> {
  void callSetState() {
    setState(() {});
  }

  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser!;
    _database = Database(_user.uid);
    cancelToken = CancelToken();
    searchController = TextEditingController();
    searchFocus = FocusNode();
    _screenNavigator = ScreenNavigator();
    _value = 0;
    isTextFieldEmpty = true;
    isTextFieldFocused = false;
    showFilters = false;
    selectedMenu = "";
    query = "";
    searchController.clear();
    super.initState();
  }

  // @override
  // void dispose() {
  //   searchController.dispose();
  //   searchFocus.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isTextFieldFocused) {
          setState(() {
            isTextFieldFocused = false;
          });
          searchFocus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Search',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          // actions: <Widget>[
          //   IconButton(
          //     icon: Icon(
          //       Icons.notifications,
          //     ),
          //     onPressed: () {},
          //   )
          // ],
          elevation: 0,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SearchBar(callSetState: callSetState),
            SearchFilters(callSetState: callSetState),
            // ignore: prefer_const_constructors
            SearchHistory(),
            SearchResults(callSetState: callSetState),
          ],
        ),
      ),
    );
  }
}

class SearchBar extends StatefulWidget {
  const SearchBar({Key? key, required this.callSetState}) : super(key: key);

  final Function callSetState;

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: TextField(
        style: const TextStyle(color: Colors.black),
        focusNode: searchFocus,
        controller: searchController,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          hintText: "Find your best music",
          hintStyle: const TextStyle(
            color: Colors.grey,
          ),
          prefixIcon: isTextFieldFocused || !isTextFieldEmpty
              ? IconButton(
                  onPressed: () {
                    searchFocus.unfocus();
                    searchController.clear();
                    isTextFieldFocused = false;
                    isTextFieldEmpty = true;
                    showFilters = false;
                    _value = 0;
                    widget.callSetState();
                  },
                  icon: const Icon(
                    Iconsax.arrow_left,
                    color: Colors.grey,
                  ))
              : const Icon(
                  IconlyLight.search,
                  color: Colors.grey,
                ),
          suffixIcon: !isTextFieldEmpty
              ? IconButton(
                  onPressed: () {
                    searchController.clear();
                    isTextFieldEmpty = true;
                    showFilters = false;
                    _value = 0;
                    widget.callSetState();
                  },
                  splashColor: Colors.transparent,
                  icon: const Icon(
                    Icons.clear,
                    color: Colors.grey,
                  ),
                )
              : null,
        ),
        onTap: (() {
          isTextFieldFocused = true;
          widget.callSetState();
        }),
        onChanged: ((search) {
          if (search.isNotEmpty) {
            query = search;
            isTextFieldEmpty = false;
            showFilters = true;
            isTextFieldFocused = true;
            widget.callSetState();
          } else {
            query = "";
            isTextFieldEmpty = true;
            showFilters = false;
            isTextFieldFocused = false;
          }
          widget.callSetState();
        }),
        onSubmitted: ((search) {
          if (search != query && search.isNotEmpty) {
            query = search;
            isTextFieldEmpty = false;
            showFilters = true;
            isTextFieldFocused = true;
            widget.callSetState();
          } else if (search == query && search.isNotEmpty) {
            isTextFieldEmpty = false;
            showFilters = true;
            isTextFieldFocused = true;
          } else {
            query = "";
            isTextFieldEmpty = true;
            showFilters = false;
            isTextFieldFocused = false;
          }
        }),
      ),
    );
  }
}

class SearchFilters extends StatefulWidget {
  const SearchFilters({Key? key, required this.callSetState}) : super(key: key);

  final Function callSetState;

  @override
  State<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends State<SearchFilters> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: showFilters
              ? Row(children: <Widget>[
                  MyRadioListTile<int>(
                    value: 0,
                    groupValue: _value,
                    leading: 'Top',
                    onChanged: (value) {
                      if (_value != value) {
                        cancelToken.cancel();
                        cancelToken = CancelToken();
                        _value = value!;
                        widget.callSetState();
                      }
                    },
                  ),
                  MyRadioListTile<int>(
                    value: 1,
                    groupValue: _value,
                    leading: 'Songs',
                    onChanged: (value) {
                      if (_value != value) {
                        cancelToken.cancel();
                        cancelToken = CancelToken();
                        _value = value!;
                        widget.callSetState();
                      }
                    },
                  ),
                  MyRadioListTile<int>(
                    value: 2,
                    groupValue: _value,
                    leading: 'Albums',
                    onChanged: (value) {
                      if (_value != value) {
                        cancelToken.cancel();
                        cancelToken = CancelToken();
                        _value = value!;
                        widget.callSetState();
                      }
                    },
                  ),
                  MyRadioListTile<int>(
                    value: 3,
                    groupValue: _value,
                    leading: 'Artists',
                    onChanged: (value) {
                      if (_value != value) {
                        cancelToken.cancel();
                        cancelToken = CancelToken();
                        _value = value!;
                        widget.callSetState();
                      }
                    },
                  ),
                  MyRadioListTile<int>(
                    value: 4,
                    groupValue: _value,
                    leading: 'Videos',
                    onChanged: (value) {
                      if (_value != value) {
                        cancelToken.cancel();
                        cancelToken = CancelToken();
                        _value = value!;
                        widget.callSetState();
                      }
                    },
                  ),
                  MyRadioListTile<int>(
                    value: 5,
                    groupValue: _value,
                    leading: 'Community playlists',
                    onChanged: (value) {
                      if (_value != value) {
                        cancelToken.cancel();
                        cancelToken = CancelToken();
                        _value = value!;
                        widget.callSetState();
                      }
                    },
                  ),
                  MyRadioListTile<int>(
                    value: 6,
                    groupValue: _value,
                    leading: 'Featured playlists',
                    onChanged: (value) {
                      if (_value != value) {
                        cancelToken.cancel();
                        cancelToken = CancelToken();
                        _value = value!;
                        widget.callSetState();
                      }
                    },
                  ),
                ])
              : null),
    );
  }
}

class SearchResults extends StatefulWidget {
  const SearchResults({Key? key, required this.callSetState}) : super(key: key);

  final Function callSetState;

  @override
  State<SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends State<SearchResults> {
  @override
  Widget build(BuildContext context) {
    return showFilters
        ? ValueListenableBuilder<String>(
            valueListenable: context.watch<MediaViewModel>().currentVideoIdNotifier,
            builder: (context, currentVideoId, _) {
              return FutureBuilder<List?>(
                future: SearchViewModel().createSearch(searchController.text, _value, cancelToken),
                builder: (BuildContext context, AsyncSnapshot<List?> snapshot) {
                  Widget child;
                  final data = snapshot.data;
                  Map categories = {};
                  String category = "";
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Expanded(
                      child: Loading(),
                    );
                  } else if (snapshot.hasData) {
                    if (data != null && data.isNotEmpty) {
                      child = ListView.builder(
                        key: keys[_value],
                        scrollDirection: Axis.vertical,
                        // shrinkWrap: true,
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          category = data[index]["category"];
                          if (!categories.containsKey(category)) {
                            categories[category] = index;
                          }
                          Map mediaData = data[index];
                          String type = mediaData["resultType"];
                          String thumbnail = mediaData["thumbnails"][0]["url"];
                          Color color = currentVideoId == mediaData["videoId"] ? Colors.black : Colors.white;
                          Color tileColor = currentVideoId == mediaData["videoId"] ? Colors.white : Colors.black;
                          return Column(
                            children: [
                              data[0]["category"] == "Top result" && categories[category] == index
                                  ? ListTile(
                                      onTap: category != "Top result"
                                          ? () {
                                              switch (data[index]["category"]) {
                                                case "Songs":
                                                  {
                                                    cancelToken.cancel();
                                                    cancelToken = CancelToken();
                                                    _value = 1;
                                                    widget.callSetState();
                                                  }
                                                  break;
                                                case "Albums":
                                                  {
                                                    cancelToken.cancel();
                                                    cancelToken = CancelToken();
                                                    _value = 2;
                                                    widget.callSetState();
                                                  }
                                                  break;
                                                case "Artists":
                                                  {
                                                    cancelToken.cancel();
                                                    cancelToken = CancelToken();
                                                    _value = 3;
                                                    widget.callSetState();
                                                  }
                                                  break;
                                                case "Videos":
                                                  {
                                                    cancelToken.cancel();
                                                    cancelToken = CancelToken();
                                                    _value = 4;
                                                    widget.callSetState();
                                                  }
                                                  break;
                                                case "Community playlists":
                                                  {
                                                    cancelToken.cancel();
                                                    cancelToken = CancelToken();
                                                    _value = 5;
                                                    widget.callSetState();
                                                  }
                                                  break;
                                                case "Featured playlists":
                                                  {
                                                    cancelToken.cancel();
                                                    cancelToken = CancelToken();
                                                    _value = 6;
                                                    widget.callSetState();
                                                  }
                                                  break;
                                                default:
                                                  break;
                                              }
                                            }
                                          : null,
                                      title: Text(
                                        category,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                      ),
                                      trailing: category != "Top result"
                                          ? const Text(
                                              "MORE",
                                              style: TextStyle(color: Colors.grey),
                                            )
                                          : null,
                                    )
                                  : const SizedBox(),
                              Material(
                                color: Colors.black,
                                child: ListTile(
                                  tileColor: tileColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: currentVideoId == mediaData["videoId"] ? BorderRadius.circular(10) : BorderRadius.circular(100)),
                                  onTap: () async {
                                    searchFocus.unfocus();
                                    Map mediaData = data[index];
                                    _database.updateSearchHistory(search: mediaData);
                                    await _screenNavigator.visitPage(context: context, mediaData: mediaData, type: type);
                                  },
                                  title: type == "artist"
                                      ? Text(
                                          mediaData["artist"],
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : Text(
                                          mediaData["title"],
                                          style: TextStyle(fontWeight: FontWeight.bold, color: color),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                  leading: type == "artist"
                                      ? CircleAvatar(
                                          radius: 30,
                                          backgroundImage: NetworkImage(thumbnail),
                                        )
                                      : ClipRRect(
                                          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
                                          child: SizedBox(height: 60, width: 60, child: Image.network(thumbnail)),
                                        ),
                                  trailing: type == "song" || type == "video"
                                      ? PopupMenuButton(
                                          color: Colors.grey[900],
                                          child: Icon(
                                            Iconsax.more_24,
                                            color: color,
                                          ),
                                          onSelected: (Menu item) {
                                            selectedMenu = item.name;
                                            widget.callSetState();
                                          },
                                          itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
                                                const PopupMenuItem<Menu>(
                                                  value: Menu.itemOne,
                                                  child: Text('Item 1'),
                                                ),
                                                const PopupMenuItem<Menu>(
                                                  value: Menu.itemTwo,
                                                  child: Text('Item 2'),
                                                ),
                                              ])
                                      : Icon(
                                          Iconsax.arrow_right_3,
                                          color: color,
                                        ),
                                  subtitle: type == "song"
                                      ? Row(
                                          children: [
                                            mediaData["isExplicit"] == true
                                                ? Row(
                                                    children: [
                                                      Icon(
                                                        Icons.explicit_rounded,
                                                        color: color,
                                                        size: 20,
                                                      ),
                                                      const Text(" "),
                                                    ],
                                                  )
                                                : const Text(""),
                                            Flexible(
                                              fit: FlexFit.loose,
                                              child: Text(
                                                "${capitalize(type)} • ${mediaData["duration"]} • ${getArtists(mediaData["artists"])} • ${mediaData["album"]["name"]}",
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: color),
                                              ),
                                            ),
                                          ],
                                        )
                                      : type == "artist"
                                          ? Text(
                                              capitalize(type),
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : type == "album"
                                              ? Row(
                                                  children: [
                                                    mediaData["isExplicit"] == true
                                                        ? Row(
                                                            children: const [
                                                              Icon(
                                                                Icons.explicit_rounded,
                                                                color: Colors.white,
                                                                size: 20,
                                                              ),
                                                              Text(" "),
                                                            ],
                                                          )
                                                        : const SizedBox(),
                                                    Flexible(
                                                      fit: FlexFit.loose,
                                                      child: mediaData["artists"].isNotEmpty
                                                          ? Text(
                                                              "${capitalize(type)} • ${getArtists(mediaData["artists"])} • ${mediaData["year"]}",
                                                              overflow: TextOverflow.ellipsis,
                                                            )
                                                          : Text(
                                                              "${capitalize(type)} • ${mediaData["year"]}",
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                    ),
                                                  ],
                                                )
                                              : data[index]["resultType"] == "playlist"
                                                  ? Text(
                                                      "${capitalize(type)} • ${mediaData["author"]} • ${mediaData["itemCount"]} Songs",
                                                      overflow: TextOverflow.ellipsis,
                                                    )
                                                  : data[index]["resultType"] == "video"
                                                      ? Text(
                                                          "${capitalize(type)} • ${mediaData["duration"]} • ${getArtists(mediaData["artists"])} • ${mediaData["views"]}",
                                                          overflow: TextOverflow.ellipsis,
                                                          style: TextStyle(color: color),
                                                        )
                                                      : null,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      child = Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.search_off,
                              color: Colors.white,
                              size: 60,
                            ),
                            Text("No results")
                          ],
                        ),
                      );
                    }
                  } else if (snapshot.hasError) {
                    String error = "Connection error. Try again.";
                    return Expanded(
                      child: Error(error: error),
                    );
                  } else {
                    child = const Expanded(child: Loading());
                  }
                  return Expanded(
                    child: child,
                  );
                },
              );
            })
        : const SizedBox();
  }
}

class SearchHistory extends StatefulWidget {
  const SearchHistory({Key? key}) : super(key: key);
  @override
  State<SearchHistory> createState() => _SearchHistoryState();
}

class _SearchHistoryState extends State<SearchHistory> {
  @override
  Widget build(BuildContext context) {
    return !showFilters
        ? Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 5, 0, 5),
                  child: Text(
                    "Search history",
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                  ),
                ),
                ValueListenableBuilder<String>(
                    valueListenable: context.watch<MediaViewModel>().currentVideoIdNotifier,
                    builder: (context, currentVideoId, _) {
                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _database.getUserData(uid: _user.uid),
                        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
                          Widget child;
                          final data = snapshot.data;

                          if (snapshot.connectionState != ConnectionState.done) {
                            return const Expanded(child: Loading());
                          } else if (snapshot.hasData) {
                            if (data != null && data.isNotEmpty) {
                              final searchHistoryData = data["searchHistory"]["data"];
                              if (searchHistoryData.isEmpty) {
                                child = Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Iconsax.music_square_search5,
                                        color: Colors.white,
                                        size: 60,
                                      ),
                                      Text("No searches"),
                                    ],
                                  ),
                                );
                              } else {
                                child = ListView.builder(
                                  key: ObjectKey(_value),
                                  scrollDirection: Axis.vertical,
                                  // shrinkWrap: true,
                                  itemCount: searchHistoryData.length,
                                  itemBuilder: (context, index) {
                                    Map mediaData = searchHistoryData[index];
                                    String type = mediaData["resultType"];
                                    String thumbnail = mediaData["thumbnails"][0]["url"];
                                    Color color = currentVideoId == mediaData["videoId"] ? Colors.black : Colors.white;
                                    Color tileColor = currentVideoId == mediaData["videoId"] ? Colors.white : Colors.black;
                                    return Material(
                                      color: Colors.black,
                                      child: ListTile(
                                        tileColor: tileColor,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                currentVideoId == mediaData["videoId"] ? BorderRadius.circular(10) : BorderRadius.circular(100)),
                                        onTap: () async {
                                          searchFocus.unfocus();
                                          await _screenNavigator.visitPage(context: context, mediaData: mediaData, type: type);
                                        },
                                        title: type == "artist"
                                            ? Text(
                                                mediaData["artist"],
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              )
                                            : Text(
                                                mediaData["title"],
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: color,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                        leading: type == "artist"
                                            ? CircleAvatar(
                                                radius: 30,
                                                backgroundImage: NetworkImage(thumbnail),
                                              )
                                            : ClipRRect(
                                                borderRadius: const BorderRadius.all(Radius.circular(6.0)),
                                                child: SizedBox(height: 60, width: 60, child: Image.network(thumbnail)),
                                              ),
                                        trailing: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: Icon(
                                            Icons.clear,
                                            color: color,
                                          ),
                                          onPressed: (() async {
                                            _database.updateSearchHistory(search: mediaData, type: "delete");
                                            await _database.getUserData(uid: _user.uid);
                                            setState(() {});
                                          }),
                                        ),
                                        subtitle: type == "song"
                                            ? Row(
                                                children: [
                                                  mediaData["isExplicit"] == true
                                                      ? Row(
                                                          children: [
                                                            Icon(
                                                              Icons.explicit_rounded,
                                                              color: color,
                                                              size: 20,
                                                            ),
                                                            const Text(" "),
                                                          ],
                                                        )
                                                      : const Text(""),
                                                  Flexible(
                                                    fit: FlexFit.loose,
                                                    child: Text(
                                                      "${capitalize(type)} • ${getArtists(mediaData["artists"])} • ${mediaData["album"]["name"]} • ${mediaData["duration"]}",
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(color: color),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : type == "artist"
                                                ? Text(
                                                    capitalize(type),
                                                    overflow: TextOverflow.ellipsis,
                                                  )
                                                : type == "album"
                                                    ? Row(
                                                        children: [
                                                          mediaData["isExplicit"] == true
                                                              ? Row(
                                                                  children: const [
                                                                    Icon(
                                                                      Icons.explicit_rounded,
                                                                      size: 20,
                                                                    ),
                                                                    Text(" "),
                                                                  ],
                                                                )
                                                              : const Text(""),
                                                          Flexible(
                                                            fit: FlexFit.loose,
                                                            child: Text(
                                                              "${capitalize(type)} • ${getArtists(mediaData["artists"])} • ${mediaData["year"]}",
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : mediaData["resultType"] == "playlist"
                                                        ? Text(
                                                            "${capitalize(type)} • ${mediaData["author"]} • ${mediaData["itemCount"]} Songs",
                                                            overflow: TextOverflow.ellipsis,
                                                          )
                                                        : mediaData["resultType"] == "video"
                                                            ? Text(
                                                                "${capitalize(type)} • ${getArtists(mediaData["artists"])} • ${mediaData["views"]} • ${mediaData["duration"]}",
                                                                overflow: TextOverflow.ellipsis,
                                                                style: TextStyle(color: color),
                                                              )
                                                            : null,
                                      ),
                                    );
                                  },
                                );
                              }
                            } else {
                              child = Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Iconsax.warning_25,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                                    Text("Error search")
                                  ],
                                ),
                              );
                            }
                          } else if (snapshot.hasError) {
                            String error = "Connection error. Try again.";
                            return Error(error: error);
                          } else {
                            child = const Expanded(child: Loading());
                          }
                          return Expanded(
                            child: child,
                          );
                        },
                      );
                    }),
              ],
            ),
          )
        : const SizedBox();
  }
}
