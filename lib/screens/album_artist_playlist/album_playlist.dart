import 'package:bell/general_functions.dart';
import 'package:bell/screen_navigator.dart';
import 'package:bell/screens/album_artist_playlist/aap_vmodel.dart';
import 'package:bell/screens/library/library_vmodel.dart';
import 'package:bell/services/auth.dart';
import 'package:bell/widgets/custom_marquee.dart';
import 'package:bell/widgets/loading.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:bell/widgets/error.dart';
import 'dart:math';
import 'package:like_button/like_button.dart';
import 'package:provider/provider.dart';

class AlbumPlaylist extends StatefulWidget {
  const AlbumPlaylist({Key? key}) : super(key: key);

  @override
  State<AlbumPlaylist> createState() => _AlbumPlaylistState();
}

final ScreenNavigator _screenNavigator = ScreenNavigator();

class _AlbumPlaylistState extends State<AlbumPlaylist> {
  @override
  Widget build(BuildContext context) {
    Map arguments = ModalRoute.of(context)!.settings.arguments as Map;
    String browseId = arguments["browseId"];
    String type = arguments["type"];
    String artist = arguments["artist"];
    late Future<Map?> future;
    if (type == "liked") {
      future = LibraryViewModel().getLikedSongs();
    } else {
      future = AAPViewModel().getAAPData(browseId: browseId, type: type);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(IconlyLight.arrow_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // actions: <Widget>[
        //   IconButton(
        //     onPressed: () {},
        //     icon: const Icon(IconlyLight.search),
        //   ),
        // ],
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<Map?>(
        future: future,
        builder: (BuildContext context, AsyncSnapshot<Map?> snapshot) {
          Widget child;
          final data = snapshot.data;

          if (snapshot.connectionState != ConnectionState.done) {
            return const Loading();
          } else if (snapshot.hasData) {
            if (data != null && data.isNotEmpty) {
              late bool rating;
              late String id;
              String privacy = "PUBLIC";
              if (type == "album") {
                id = data["audioPlaylistId"];
                rating = data["rating"];
              } else if (type == "playlist") {
                privacy = data["privacy"];
                id = data["id"];
                rating = data["rating"];
              } else {
                id = data["id"];
                rating = true;
              }
              List tracks = data["tracks"];
              List thumbnails = data["thumbnails"];
              child = ListView(
                padding: EdgeInsets.zero,
                children: [
                  Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ThumbnailBackground(thumbnails: thumbnails),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 90),
                          Thumbnail(thumbnails: thumbnails),
                          MediaInfo(data: data, artist: artist),
                          privacy == "PRIVATE" ? Buttons(id: id, rating: rating, privacy: privacy) : Buttons(id: id, rating: rating),
                          PlayShuffleButtons(tracks: tracks),
                          Tracks(
                            tracks: tracks,
                            playlistTitle: data["title"],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            } else {
              child = const Error(error: "Error: no album data");
            }
          } else if (snapshot.hasError) {
            String error = "Connection error. Try again.";
            return Error(error: error);
          } else {
            child = const Loading();
          }
          return child;
        },
      ),
    );
  }
}

class ThumbnailBackground extends StatelessWidget {
  const ThumbnailBackground({Key? key, required this.thumbnails}) : super(key: key);

  final List thumbnails;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.transparent, Colors.black],
        ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
      },
      blendMode: BlendMode.dstIn,
      child: Container(
        height: thumbnails[0]["width"] == thumbnails[0]["height"] ? 400 : 200,
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.fitWidth,
            image: NetworkImage(
              thumbnails[thumbnails.length - 1]["url"],
            ),
          ),
        ),
      ),
    );
  }
}

class Thumbnail extends StatelessWidget {
  const Thumbnail({Key? key, required this.thumbnails}) : super(key: key);

  final List thumbnails;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: thumbnails.length > 1
          ? Image.network(
              thumbnails[thumbnails.length - 2]["url"],
              width: 160,
            )
          : Image.network(
              thumbnails[thumbnails.length - 1]["url"],
              width: 160,
            ),
    );
  }
}

class MediaInfo extends StatelessWidget {
  const MediaInfo({Key? key, required this.data, this.artist = ""}) : super(key: key);

  final Map data;
  final String artist;

  @override
  Widget build(BuildContext context) {
    TextStyle titleStyle = const TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold);
    TextStyle artistsStyle = const TextStyle(fontSize: 20);
    TextStyle infoStyle = const TextStyle(fontSize: 15, color: Colors.grey);
    late String artists;
    if (artist != "") {
      artists = artist;
    } else if (data["type"] == "Album" || data["type"] == "Single") {
      artists = getArtists(data["artists"]);
    } else if (data["author"] != null) {
      if (data["author"].runtimeType == String) {
        artists = data["author"];
      } else {
        artists = data["author"]["name"];
      }
    } else {
      artists = "";
    }
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Column(
        children: [
          // title
          CustomMarquee(
            text: data["title"] == "Songs" ? "$artists's songs" : data["title"],
            style: titleStyle,
            height: 40.0,
          ),
          // artists
          artists.isNotEmpty ? CustomMarquee(text: artists, style: artistsStyle, height: 30) : const Text(""),
          // info
          data["title"] == "Songs"
              ? Text(
                  "Playlist • ${data["trackCount"].toString()} songs • ${data["duration"]}",
                  style: infoStyle,
                )
              : data["title"] == "Videos"
                  ? Text(
                      "Playlist • ${data["trackCount"].toString()} videos • ${data["duration"]}",
                      style: infoStyle,
                    )
                  : data["title"] == "Your Likes"
                      ? Text(
                          "Auto Playlist • ${data["trackCount"].toString()} songs",
                          style: infoStyle,
                        )
                      : data["type"] == "Album"
                          ? Text(
                              data["type"] + " • " + data["trackCount"].toString() + " songs • " + data["year"] + " • " + data["duration"],
                              style: infoStyle,
                            )
                          : data["year"] == null
                              ? Text(
                                  "Playlist • ${data["trackCount"].toString()} songs • ${data["duration"]}",
                                  style: infoStyle,
                                )
                              : Text(
                                  "Playlist • ${data["trackCount"].toString()} songs • ${data["year"]} • ${data["duration"]}",
                                  style: infoStyle,
                                ),
        ],
      ),
    );
  }
}

class Buttons extends StatelessWidget {
  const Buttons({Key? key, required this.id, required this.rating, this.privacy = "PUBLIC"}) : super(key: key);
  final String id;
  final bool rating;
  final String privacy;
  @override
  Widget build(BuildContext context) {
    bool rating2 = rating;
    return ValueListenableBuilder<bool>(
        valueListenable: context.watch<Authentication>().areHeadersPresentNotifier,
        builder: (context, areHeadersPresent, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: Provider.of<AAPViewModel>(context, listen: true).isAPLikedNotifier,
            builder: (context, isAPLiked, _) {
              isAPLiked = rating2;
              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    areHeadersPresent
                        ? LikeButton(
                            isLiked: isAPLiked,
                            likeBuilder: (_) {
                              return isAPLiked
                                  ? const Icon(
                                      Iconsax.heart5,
                                      color: Colors.redAccent,
                                    )
                                  : const Icon(
                                      Iconsax.heart4,
                                      color: Colors.white,
                                    );
                            },
                            onTap: (_) async {
                              isAPLiked = await Provider.of<AAPViewModel>(context, listen: false)
                                  .changeIsAPLiked(isAPLiked: isAPLiked, id: id, privacy: privacy);
                              rating2 = isAPLiked;
                              return rating2;
                            },
                          )
                        : const IconButton(
                            onPressed: null,
                            icon: Icon(
                              Iconsax.heart_slash,
                              color: Colors.white,
                            ),
                          ),
                    // IconButton(
                    //   onPressed: () {},
                    //   icon: const Icon(IconlyBroken.download),
                    //   padding: EdgeInsets.zero,
                    //   constraints: const BoxConstraints(),
                    // ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(IconlyBroken.more_square),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          );
        });
  }
}

class PlayShuffleButtons extends StatefulWidget {
  const PlayShuffleButtons({Key? key, required this.tracks}) : super(key: key);

  final List tracks;

  @override
  State<PlayShuffleButtons> createState() => _PlayShuffleButtonsState();
}

class _PlayShuffleButtonsState extends State<PlayShuffleButtons> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Container(
              width: 180,
              color: Colors.white,
              child: TextButton(
                  onPressed: () async {
                    await _screenNavigator.visitPage(
                      context: context,
                      mediaData: widget.tracks[0],
                      type: "song",
                      queue: widget.tracks,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Icon(
                        Iconsax.play5,
                        color: Colors.black,
                        size: 25,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: Text(
                          "Play",
                          style: TextStyle(color: Colors.black, fontSize: 20),
                        ),
                      )
                    ],
                  )),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 180,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: Colors.black,
                border: Border.all(
                  color: Colors.white,
                )),
            child: TextButton(
                onPressed: () async {
                  int randomTrackNumber = Random().nextInt(widget.tracks.length) + 1;
                  await _screenNavigator.visitPage(
                    context: context,
                    mediaData: widget.tracks[randomTrackNumber],
                    type: "song",
                    queue: widget.tracks,
                    shuffle: true,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Icon(
                      Iconsax.shuffle,
                      color: Colors.white,
                      size: 25,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        "Shuffle",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    )
                  ],
                )),
          ),
        ],
      ),
    );
  }
}

class Tracks extends StatefulWidget {
  const Tracks({Key? key, required this.tracks, required this.playlistTitle}) : super(key: key);

  final List tracks;
  final String playlistTitle;

  @override
  State<Tracks> createState() => _TracksState();
}

class _TracksState extends State<Tracks> {
  @override
  Widget build(BuildContext context) {
    return widget.tracks.isEmpty
        ? const Expanded(child: Text("Here's you'll see your liked songs"))
        : ListView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: widget.tracks.length,
            itemBuilder: (context, index) {
              String trackArtists = getArtists(widget.tracks[index]["artists"]);
              return ListTile(
                leading: widget.playlistTitle == "Songs" || widget.playlistTitle == "Videos" || widget.playlistTitle == "Your Likes"
                    ? ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
                        child: SizedBox(height: 60, width: 60, child: Image.network(widget.tracks[index]["thumbnails"][0]["url"])),
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        widget.tracks[index]["videoId"] == null
                            ? const Icon(
                                Icons.error,
                                color: Colors.grey,
                                size: 15,
                              )
                            : Text(
                                (index + 1).toString().padLeft(2, '0'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ]),
                minLeadingWidth: 10,
                title: Text(
                  widget.tracks[index]["title"].trim(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    widget.tracks[index]["isExplicit"] == true
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
                        : const Text(""),
                    Flexible(
                      fit: FlexFit.loose,
                      child: widget.tracks[index]["duration"] != null
                          ? Text(
                              "${widget.tracks[index]["duration"]} • $trackArtists",
                              overflow: TextOverflow.ellipsis,
                            )
                          : Text(
                              trackArtists,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
                onTap: () async {
                  await _screenNavigator.visitPage(context: context, mediaData: widget.tracks[index], type: "song", queue: widget.tracks);
                },
                enabled: widget.tracks[index]["videoId"] == null ? false : true,
              );
            },
          );
  }
}
