import 'package:bell/general_functions.dart';
import 'package:bell/screen_navigator.dart';
import 'package:bell/screens/library/library_vmodel.dart';
import 'package:bell/widgets/loading.dart';
import 'package:bell/widgets/error.dart';
import 'package:flutter/material.dart';

class LibraryContent extends StatefulWidget {
  const LibraryContent({Key? key}) : super(key: key);

  @override
  State<LibraryContent> createState() => _LibraryContentState();
}

class _LibraryContentState extends State<LibraryContent> {
  @override
  Widget build(BuildContext context) {
    final ScreenNavigator screenNavigator = ScreenNavigator();
    final LibraryViewModel libraryVM = LibraryViewModel();
    final Map arguments = ModalRoute.of(context)!.settings.arguments as Map;
    final String type = arguments["type"];
    late String typeString;
    late String navigatorType;
    late Future<List?> future;
    String artists = "";
    switch (type) {
      case "libraryPlaylists":
        {
          navigatorType = "playlist";
          typeString = "Playlists";
          future = libraryVM.getLibraryPlaylists();
        }
        break;
      case "libraryAlbums":
        {
          navigatorType = "album";
          typeString = "Albums";
          future = libraryVM.getLibraryAlbums();
        }
        break;
      case "librarySongs":
        {
          navigatorType = "song";
          typeString = "Songs";
          future = libraryVM.getLibrarySongs();
        }
        break;
      case "libraryArtists":
        {
          navigatorType = "artist";
          typeString = "Artists";
          future = libraryVM.getLibraryArtists();
        }
        break;
      case "librarySubscriptions":
        {
          navigatorType = "artist";
          typeString = "Subscriptions";
          future = libraryVM.getLibrarySubscriptions();
        }
        break;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(typeString),
      ),
      body: Column(
        children: [
          Flexible(
            child: FutureBuilder<List?>(
              future: future,
              builder: (BuildContext context, AsyncSnapshot<List?> snapshot) {
                Widget child;
                List? data = snapshot.data;

                if (snapshot.connectionState != ConnectionState.done) {
                  return const Loading();
                } else if (snapshot.hasData) {
                  if (type == "libraryPlaylists" && data != null && data.isNotEmpty && data[0]["playlistId"] == "LM") {
                    if (data.length > 1) {
                      data = data.sublist(1);
                    } else {
                      data = [];
                    }
                  }
                  if (data != null && data.isNotEmpty) {
                    child = Padding(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        scrollDirection: Axis.vertical,
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          while (index < data!.length) {
                            const TextStyle titleStyle = TextStyle(fontWeight: FontWeight.bold);
                            List thumbnails = data[index]["thumbnails"];
                            String thumbnail = thumbnails[thumbnails.length - 1]["url"];
                            late String title;
                            if (type == "libraryArtists" || type == "librarySubscriptions") {
                              title = data[index]["artist"];
                            } else {
                              title = data[index]["title"];
                            }

                            if (data[index]["artists"] != null) {
                              artists = getArtists(data[index]["artists"]);
                            }
                            // Generate subtitle
                            late String subtitle;
                            switch (type) {
                              case "libraryPlaylists":
                                {
                                  subtitle = data[index]["description"];
                                }
                                break;
                              case "libraryAlbums":
                                {
                                  String type = data[index]["type"];
                                  String year = data[index]["year"];
                                  String artists = getArtists(data[index]["artists"]);
                                  subtitle = "$type • $artists • $year";
                                }
                                break;
                              case "librarySongs":
                                {
                                  String artists = getArtists(data[index]["artists"]);
                                  String duration = data[index]["duration"];
                                  String album = data[index]["album"]["name"];
                                  subtitle = "$duration • $artists • $album";
                                }
                                break;
                              case "libraryArtists":
                              case "librarySubscriptions":
                                {
                                  String subs = data[index]["subscribers"];
                                  subtitle = "$subs subscribers";
                                }
                                break;
                              default:
                                {
                                  subtitle = "";
                                }
                                break;
                            }

                            return ListTile(
                              contentPadding: const EdgeInsets.all(5),
                              onTap: (() async {
                                await screenNavigator.visitPage(context: context, mediaData: data![index], type: navigatorType, artist: artists);
                              }),
                              title: Text(
                                title,
                                style: titleStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                subtitle,
                                overflow: TextOverflow.ellipsis,
                              ),
                              leading: data[index]["isAvailable"] == false
                                  ? const Icon(
                                      Icons.error,
                                      color: Colors.grey,
                                      size: 15,
                                    )
                                  : type == "libraryArtists" || type == "librarySubscriptions"
                                      ? CircleAvatar(
                                          radius: 30,
                                          backgroundImage: NetworkImage(thumbnail),
                                        )
                                      : ClipRRect(
                                          borderRadius: const BorderRadius.all(Radius.circular(6.0)),
                                          child: SizedBox(height: 60, width: 60, child: Image.network(thumbnail)),
                                        ),
                              enabled: data[index]["isAvailable"] == false ? false : true,
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    );
                  } else {
                    child = Center(
                        child: Text(
                      "Here you'll see your ${typeString.toLowerCase()}",
                      style: const TextStyle(fontSize: 15),
                    ));
                  }
                } else if (snapshot.hasError) {
                  String error = "Connection error. Try again";
                  child = Error(error: error);
                } else {
                  child = const Loading();
                }
                return RefreshIndicator(
                    onRefresh: () {
                      return Future(() {
                        setState(() {});
                      });
                    },
                    child: child);
              },
            ),
          ),
        ],
      ),
    );
  }
}
