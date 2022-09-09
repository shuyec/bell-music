import 'package:bell/screen_navigator.dart';
import 'package:bell/services/auth.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class Library extends StatefulWidget {
  const Library({Key? key}) : super(key: key);

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  final ScreenNavigator _screenNavigator = ScreenNavigator();
  @override
  Widget build(BuildContext context) {
    const TextStyle textStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 20,
    );
    const Color color = Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Library',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        // actions: <Widget>[
        //   IconButton(
        //     icon: const Icon(
        //       Icons.notifications,
        //     ),
        //     onPressed: () {},
        //   )
        // ],
        elevation: 0,
      ),
      body: ValueListenableBuilder<bool>(
          valueListenable: context.watch<Authentication>().areHeadersPresentNotifier,
          builder: (context, areHeadersPresent, _) {
            return areHeadersPresent
                ? ListView(
                    children: ListTile.divideTiles(
                      context: context,
                      color: color,
                      tiles: [
                        ListTile(
                          title: const Text(
                            "Liked",
                            style: textStyle,
                          ),
                          leading: const Icon(
                            Iconsax.like_15,
                            color: color,
                          ),
                          onTap: (() async {
                            await _screenNavigator.visitPage(context: context, mediaData: {}, type: "liked");
                          }),
                        ),
                        ListTile(
                          title: const Text(
                            "Playlists",
                            style: textStyle,
                          ),
                          leading: const Icon(
                            Icons.playlist_play,
                            color: color,
                          ),
                          onTap: (() async {
                            await _screenNavigator.visitPage(context: context, mediaData: {}, type: "libraryPlaylists");
                          }),
                        ),
                        ListTile(
                          title: const Text(
                            "Albums",
                            style: textStyle,
                          ),
                          leading: const Icon(
                            Iconsax.cd5,
                            color: color,
                          ),
                          onTap: (() async {
                            await _screenNavigator.visitPage(context: context, mediaData: {}, type: "libraryAlbums");
                          }),
                        ),
                        ListTile(
                          title: const Text(
                            "Songs",
                            style: textStyle,
                          ),
                          leading: const Icon(
                            Iconsax.musicnote5,
                            color: color,
                          ),
                          onTap: (() async {
                            await _screenNavigator.visitPage(context: context, mediaData: {}, type: "librarySongs");
                          }),
                        ),
                        ListTile(
                          title: const Text(
                            "Artists",
                            style: textStyle,
                          ),
                          leading: const Icon(
                            IconlyBold.user_3,
                            color: color,
                          ),
                          onTap: (() async {
                            await _screenNavigator.visitPage(context: context, mediaData: {}, type: "libraryArtists");
                          }),
                        ),
                        ListTile(
                          title: const Text(
                            "Subscriptions",
                            style: textStyle,
                          ),
                          leading: const Icon(
                            Icons.subscriptions,
                            color: color,
                          ),
                          onTap: (() async {
                            await _screenNavigator.visitPage(context: context, mediaData: {}, type: "librarySubscriptions");
                          }),
                        ),
                      ],
                    ).toList(),
                  )
                : Center(
                    child: Container(
                      // width: MediaQuery.of(context).size.width * (2 / 3),
                      // height: MediaQuery.of(context).size.height / 3,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: FittedBox(
                          child: Column(
                            children: const [
                              Icon(
                                Iconsax.emoji_sad5,
                                size: 50,
                              ),
                              SizedBox(height: 15),
                              Text(
                                'Add headers_auth.json\nfile to access this feature.\n\nRefer to the doc to know how to get it:\n"https://ytmusicapi.readthedocs.io\n/en/latest/setup.html".\n\nPut it in the /lib/python directory.\n\nGood luck!',
                                style: TextStyle(fontSize: 20),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
          }),
    );
  }
}
