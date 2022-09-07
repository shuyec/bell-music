import 'package:bell/screen_navigator.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

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
      body: ListView(
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
      ),
    );
  }
}
