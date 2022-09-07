import 'package:bell/general_functions.dart';
import 'package:bell/screen_navigator.dart';
import 'package:bell/screens/album_artist_playlist/aap_vmodel.dart';
import 'package:bell/widgets/loading.dart';
import 'package:bell/widgets/error.dart';
import 'package:flutter/material.dart';

final ScreenNavigator _screenNavigator = ScreenNavigator();

class ArtistAlbums extends StatelessWidget {
  const ArtistAlbums({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Map arguments = ModalRoute.of(context)!.settings.arguments as Map;
    String channelId = arguments["channelId"];
    String browseId = arguments["browseId"];
    String artist = arguments["artist"];
    String type = arguments["type"];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          artist,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              capitalize(type),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
            Albums(
              channelId: channelId,
              browseId: browseId,
              type: type,
              artist: artist,
            ),
          ],
        ),
      ),
    );
  }
}

class Albums extends StatelessWidget {
  const Albums({Key? key, required this.channelId, required this.browseId, required this.type, required this.artist}) : super(key: key);
  final String channelId;
  final String browseId;
  final String type;
  final String artist;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List?>(
        future: AAPViewModel().getArtistAlbums(browseId: browseId, channelId: channelId, type: type),
        builder: (BuildContext context, AsyncSnapshot<List?> snapshot) {
          Widget child;
          final data = snapshot.data;

          if (snapshot.connectionState != ConnectionState.done) {
            return const Expanded(child: Loading());
          } else if (snapshot.hasData) {
            if (data != null && data.isNotEmpty) {
              child = Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 230,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 230,
                    ),
                    padding: EdgeInsets.zero,
                    scrollDirection: Axis.vertical,
                    itemCount: data.length,
                    itemBuilder: (BuildContext context, index) {
                      Map currentData = data[index];
                      List thumbnails = currentData["thumbnails"];
                      String thumbnail = thumbnails[thumbnails.length - 1]["url"];
                      return InkWell(
                        borderRadius: BorderRadius.circular(15.0),
                        onTap: (() async {
                          await _screenNavigator.visitPage(context: context, mediaData: currentData, type: "album", artist: artist);
                        }),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: Image.network(thumbnail),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentData["title"],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  currentData["year"],
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
            } else {
              child = const Error(error: "Error: no artist data");
            }
          } else if (snapshot.hasError) {
            String error = "Connection error. Try again.";
            return Error(error: error);
          } else {
            child = const Expanded(child: Loading());
          }
          return child;
        });
  }
}
