import 'package:bell/general_functions.dart';
import 'package:bell/screen_navigator.dart';
import 'package:bell/screens/album_artist_playlist/aap_vmodel.dart';
import 'package:bell/widgets/loading.dart';
import 'package:bell/widgets/error.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';

final ScreenNavigator _screenNavigator = ScreenNavigator();

class Artist extends StatefulWidget {
  const Artist({Key? key}) : super(key: key);

  @override
  State<Artist> createState() => _ArtistState();
}

class _ArtistState extends State<Artist> {
  @override
  Widget build(BuildContext context) {
    Map arguments = ModalRoute.of(context)!.settings.arguments as Map;
    String browseId = arguments["browseId"];
    String type = arguments["type"];
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
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<Map?>(
          future: AAPViewModel().getAAPData(browseId: browseId, type: type),
          builder: (BuildContext context, AsyncSnapshot<Map?> snapshot) {
            Widget child;
            final data = snapshot.data;
            if (snapshot.connectionState != ConnectionState.done) {
              return const Loading();
            } else if (snapshot.hasData) {
              if (data != null && data.isNotEmpty) {
                List thumbnails = data["thumbnails"];
                child = ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Thumbnail(thumbnails: thumbnails),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 160,
                                color: Colors.transparent,
                              ),
                              ArtistName(data: data),
                              ArtistWorks(data: data),
                              data["description"] != null
                                  ? AboutArtist(
                                      description: data["description"],
                                      views: data["views"],
                                    )
                                  : const SizedBox(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              } else {
                child = const Error(error: "Error: no artist data");
              }
            } else if (snapshot.hasError) {
              String error = "Connection error. Try again.";
              return Error(error: error);
            } else {
              child = const Loading();
            }
            return child;
          }),
    );
  }
}

class ArtistName extends StatelessWidget {
  const ArtistName({Key? key, required this.data}) : super(key: key);
  final Map data;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "ARTIST",
          style: TextStyle(fontSize: 15),
        ),
        Text(
          data["name"],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
      ],
    );
  }
}

class Thumbnail extends StatelessWidget {
  const Thumbnail({Key? key, required this.thumbnails}) : super(key: key);

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
            fit: BoxFit.fitHeight,
            image: NetworkImage(
              thumbnails[thumbnails.length - 1]["url"],
            ),
          ),
        ),
      ),
    );
  }
}

class ArtistWorks extends StatelessWidget {
  const ArtistWorks({Key? key, required this.data}) : super(key: key);
  final Map data;
  @override
  Widget build(BuildContext context) {
    String category = "";
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: data.length - 9,
      itemBuilder: (context, index) {
        String oldCategory = category;
        int keyIndex = index + 9;
        category = data.keys.elementAt(keyIndex);
        keyIndex++;
        return Column(
          children: [
            oldCategory != category
                ? ListTile(
                    contentPadding: const EdgeInsets.only(left: 10, right: 10),
                    onTap: data[category]["browseId"] != null || data[category]["params"] != null
                        ? () async {
                            String categ = data.keys.elementAt(keyIndex - 1);
                            if (categ == "songs" || categ == "videos") {
                              _screenNavigator.visitPage(context: context, mediaData: {"browseId": data[categ]["browseId"]}, type: "playlist");
                            } else {
                              _screenNavigator.visitPage(
                                  context: context,
                                  mediaData: {
                                    "browseId": data[categ]["params"],
                                    "channelId": data["channelId"],
                                    "type": categ,
                                  },
                                  type: "artistAlbums",
                                  artist: data["name"]);
                            }
                          }
                        : null,
                    title: Text(
                      category == "songs"
                          ? "Top songs"
                          : category == "related"
                              ? "Fans might also like"
                              : capitalize(category),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    trailing: data[category]["browseId"] != null || data[category]["params"] != null
                        ? const Text(
                            "MORE",
                            style: TextStyle(color: Colors.grey),
                          )
                        : null,
                  )
                : const SizedBox(),
            category == "songs"
                ? Songs(data: data, category: category)
                : category == "albums"
                    ? AlbumsSingles(context: context, data: data, category: category)
                    : category == "singles"
                        ? AlbumsSingles(context: context, data: data, category: category)
                        : category == "videos"
                            ? Videos(context: context, data: data, category: category)
                            : category == "related"
                                ? Related(data: data, category: category)
                                : const SizedBox(),
          ],
        );
      },
    );
  }
}

class Videos extends StatelessWidget {
  const Videos({Key? key, required this.context, required this.data, required this.category}) : super(key: key);
  final BuildContext context;
  final Map data;
  final String category;

  @override
  Widget build(BuildContext context) {
    double size = 140;
    return SizedBox(
      height: size,
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: data[category]["results"].length,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          Map currentData = data[category]["results"][index];
          List thumbnails = currentData["thumbnails"];
          String thumbnail = thumbnails[thumbnails.length - 1]["url"];
          String title = currentData["title"];
          String views = currentData["views"];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(15.0),
              onTap: (() async {
                await _screenNavigator.visitPage(context: context, mediaData: currentData, type: "videos", artist: data["name"]);
              }),
              child: SizedBox(
                width: size,
                child: Column(
                  children: [
                    SizedBox(
                      width: size,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Image.network(thumbnail),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        Text(
                          "$views views",
                          style: const TextStyle(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AlbumsSingles extends StatelessWidget {
  const AlbumsSingles({Key? key, required this.context, required this.data, required this.category}) : super(key: key);
  final BuildContext context;
  final Map data;
  final String category;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: data[category]["results"].length,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          Map currentData = data[category]["results"][index];
          List thumbnails = currentData["thumbnails"];
          String thumbnail = thumbnails[thumbnails.length - 1]["url"];
          String title = currentData["title"];
          String year = currentData["year"];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(15.0),
              onTap: (() async {
                await _screenNavigator.visitPage(context: context, mediaData: currentData, type: "album", artist: data["name"]);
              }),
              child: SizedBox(
                width: 130,
                child: Column(
                  children: [
                    SizedBox(
                      height: 130,
                      width: 130,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15.0),
                        child: Image.network(thumbnail),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          year,
                          style: const TextStyle(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Songs extends StatelessWidget {
  const Songs({Key? key, required this.data, required this.category}) : super(key: key);
  final Map data;
  final String category;
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data[category]["results"].length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          Map currentData = data[category]["results"][index];
          List thumbnails = currentData["thumbnails"];
          String thumbnail = thumbnails[thumbnails.length - 1]["url"];
          String title = currentData["title"];
          String artists = getArtists(currentData["artists"]);
          return ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              artists,
              overflow: TextOverflow.ellipsis,
            ),
            leading: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(6.0)),
              child: SizedBox(height: 60, width: 60, child: Image.network(thumbnail)),
            ),
            onTap: (() async {
              await _screenNavigator.visitPage(context: context, mediaData: currentData, type: "song");
            }),
          );
        });
  }
}

class Related extends StatelessWidget {
  const Related({Key? key, required this.data, required this.category}) : super(key: key);
  final Map data;
  final String category;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: MediaQuery.of(context).size.width,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: data[category]["results"].length,
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          Map currentData = data[category]["results"][index];
          List thumbnails = currentData["thumbnails"];
          String thumbnail = thumbnails[thumbnails.length - 1]["url"];
          String title = currentData["title"];
          String subs = currentData["subscribers"];
          return Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(15.0),
              onTap: (() {
                _screenNavigator.visitPage(context: context, mediaData: currentData, type: "artist");
              }),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 130,
                    width: 130,
                    child: CircleAvatar(
                      radius: 130,
                      backgroundImage: NetworkImage(thumbnail),
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    "$subs subscribers",
                    style: const TextStyle(fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AboutArtist extends StatelessWidget {
  const AboutArtist({Key? key, required this.description, required this.views}) : super(key: key);
  final String description;
  final String? views;

  @override
  Widget build(BuildContext context) {
    late String text;
    if (views == null) {
      text = "\n\n$description";
    } else {
      text = "$views\n\n$description";
    }

    return ExpandableNotifier(
      child: ScrollOnExpand(
        child: ExpandablePanel(
          theme: const ExpandableThemeData(
            tapBodyToExpand: true,
            tapBodyToCollapse: true,
            iconColor: Colors.white,
            expandIcon: IconlyLight.arrow_down_2,
            collapseIcon: IconlyLight.arrow_up_2,
          ),
          header: const Text(
            "About",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          collapsed: Text(
            text,
            maxLines: 6,
          ),
          expanded: Text(
            text,
          ),
        ),
      ),
    );
  }
}
