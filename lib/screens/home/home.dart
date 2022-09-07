import 'package:bell/general_functions.dart';
import 'package:bell/screen_navigator.dart';
import 'package:bell/screens/home/home_vmodel.dart';
import 'package:bell/widgets/loading.dart';
import 'package:bell/widgets/error.dart';
import 'package:flutter/material.dart';

final ScreenNavigator _screenNavigator = ScreenNavigator();

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    String category = "";
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.notifications_outlined),
        //     onPressed: () {},
        //   ),
        //   IconButton(
        //     icon: const Icon(Icons.settings_outlined),
        //     onPressed: () {},
        //   ),
        // ],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List?>(
              future: HomeViewModel().getHome(),
              builder: (BuildContext context, AsyncSnapshot<List?> snapshot) {
                Widget child;
                final data = snapshot.data;

                if (snapshot.connectionState != ConnectionState.done) {
                  child = const Loading();
                } else if (snapshot.hasData) {
                  if (data != null && data.isNotEmpty) {
                    child = ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        String oldCategory = category;
                        category = data[index]["title"];
                        return Column(
                          children: [
                            oldCategory != category && data[index]["title"] != "Recommended radios"
                                ? ListTile(
                                    contentPadding: const EdgeInsets.only(left: 15, right: 15),
                                    title: Text(
                                      data[index]["title"],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                    ),
                                  )
                                : const SizedBox(),
                            data[index]["title"] == "Listen again"
                                ? ListenAgain(data: data[index])
                                : data[index]["title"] != "Recommended radios"
                                    ? OtherContent(data: data[index])
                                    : const SizedBox(),
                          ],
                        );
                      },
                    );
                  } else {
                    child = const Error(error: "Error: no data");
                  }
                } else if (snapshot.hasError) {
                  String error = "Connection error. Try again.";
                  child = Error(error: error);
                } else {
                  child = const Loading();
                }
                return child;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ListenAgain extends StatelessWidget {
  const ListenAgain({Key? key, required this.data}) : super(key: key);
  final Map data;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: SizedBox(
        height: 290,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 100,
            crossAxisCount: 2,
          ),
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          itemCount: data["contents"].length,
          itemBuilder: (BuildContext context, index) {
            List contents = data["contents"];
            Map currentData = contents[index];
            List thumbnails = currentData["thumbnails"];
            String thumbnail = thumbnails[thumbnails.length - 1]["url"];
            String title = currentData["title"];
            String views = "";
            String description = "";
            if (currentData["views"] != null) {
              views = currentData["views"];
            }
            if (currentData["description"] != null) {
              description = currentData["description"];
            }

            return InkWell(
              borderRadius: BorderRadius.circular(15.0),
              onTap: (() async {
                if (currentData["videoId"] != null) {
                  await _screenNavigator.visitPage(context: context, mediaData: currentData, type: "song");
                } else {
                  await _screenNavigator.visitPage(context: context, mediaData: currentData, type: "playlist");
                }
              }),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.network(
                        thumbnail,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        views != ""
                            ? "$views views"
                            : description != ""
                                ? description
                                : "",
                        style: const TextStyle(fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class OtherContent extends StatelessWidget {
  const OtherContent({Key? key, required this.data}) : super(key: key);
  final Map data;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: SizedBox(
        height: 150,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            mainAxisExtent: 100,
            crossAxisCount: 1,
          ),
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          itemCount: data["contents"].length,
          itemBuilder: (BuildContext context, index) {
            List contents = data["contents"];
            Map currentData = contents[index];
            List thumbnails = currentData["thumbnails"];
            String thumbnail = thumbnails[thumbnails.length - 1]["url"];
            String title = currentData["title"];
            String views = "";
            String description = "";
            String info = "";
            String artists = "";
            if (currentData["views"] != null) {
              views = currentData["views"];
            }
            if (currentData["description"] != null) {
              description = currentData["description"];
            }
            if (currentData["year"] != null) {
              info = currentData["year"];
            }
            if (currentData["artists"] != null) {
              artists = getArtists(currentData["artists"]);
            }
            return InkWell(
              borderRadius: BorderRadius.circular(15.0),
              onTap: (() async {
                if (currentData["browseId"] != null) {
                  await _screenNavigator.visitPage(context: context, mediaData: currentData, type: "album");
                } else if (currentData["playlistId"] != null) {
                  await _screenNavigator.visitPage(context: context, mediaData: currentData, type: "playlist");
                } else if (currentData["videoId"] != null) {
                  await _screenNavigator.visitPage(context: context, mediaData: currentData, type: "song");
                }
              }),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.network(
                        thumbnail,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          views != ""
                              ? "$views views"
                              : description != ""
                                  ? description
                                  : info != ""
                                      ? info
                                      : artists != ""
                                          ? artists
                                          : "",
                          style: const TextStyle(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
