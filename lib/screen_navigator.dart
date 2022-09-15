import 'package:bell/screens/media/media.dart';
import 'package:bell/screens/media/media_vmodel.dart';
import 'package:bell/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

class ScreenNavigator {
  void goToLogin({required BuildContext context}) {
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  }

  void goToBell({required BuildContext context}) {
    Navigator.pushNamedAndRemoveUntil(context, "/", ((Route<dynamic> route) => false));
  }

  void goToArtistAlbums({required BuildContext context, required Map data, required String artist}) {
    String route = "/artist-albums";

    Navigator.pushNamed(
      context,
      route,
      arguments: {
        "channelId": data["channelId"],
        "browseId": data["browseId"],
        "type": data["type"],
        "artist": artist,
      },
    );
  }

  void openMediaModal(BuildContext context) async {
    showCupertinoModalBottomSheet(
      context: context,
      expand: true,
      useRootNavigator: true,
      bounce: true,
      builder: (context) {
        return const Media();
      },
    );
  }

  void goToMedia({required BuildContext context}) async {
    final mediaVMProvider = Provider.of<MediaViewModel>(context, listen: false);
    mediaVMProvider.updateIsLoading(true);

    // TODO: modal bottom sheet bug
    // openMediaModal(context);

    await mediaVMProvider.updatePlayer();
    mediaVMProvider.play();
  }

  void goToAAP({required BuildContext context, required Map mediaData, required String type, String artist = ""}) {
    late String route;
    late String browseId;
    if (mediaData["resultType"] == "artist" || mediaData["subscribers"] != null) {
      route = "/artist";
    } else {
      route = "/album-playlist";
    }
    if (mediaData.isEmpty) {
      browseId = "";
    } else if (mediaData["playlistId"] != null) {
      browseId = mediaData["playlistId"];
    } else {
      browseId = mediaData["browseId"];
    }
    Navigator.pushNamed(
      context,
      route,
      arguments: {
        "browseId": browseId,
        "type": type,
        "artist": artist,
      },
    );
  }

  void goToLibraryContent({required BuildContext context, required String type}) {
    Navigator.pushNamed(context, "/library-content", arguments: {
      "type": type,
    });
  }

  Future<void> visitPage(
      {required BuildContext context,
      required Map mediaData,
      required String type,
      String artist = "",
      List queue = const [],
      bool shuffle = false}) async {
    final User user = FirebaseAuth.instance.currentUser!;
    final database = Database(user.uid);
    final mediaVMProvider = Provider.of<MediaViewModel>(context, listen: false);

    if (type == "libraryPlaylists" ||
        type == "libraryAlbums" ||
        type == "librarySongs" ||
        type == "libraryArtists" ||
        type == "librarySubscriptions") {
      goToLibraryContent(context: context, type: type);
    } else if (type == "artistAlbums") {
      goToArtistAlbums(context: context, data: mediaData, artist: artist);
    } else if (type == "song" || type == "videos") {
      if (queue.isEmpty) {
        database.updateUserData(queue: [mediaData], nowPlaying: mediaData);
      } else {
        database.updateUserData(queue: queue, nowPlaying: mediaData);
      }
      if (shuffle && !mediaVMProvider.isShuffleModeEnabledNotifier.value || !shuffle && mediaVMProvider.isShuffleModeEnabledNotifier.value) {
        mediaVMProvider.onShuffleButtonPressed();
      }
      goToMedia(context: context);
    } else if (type == "album" || type == "playlist" || type == "artist" || type == "liked") {
      goToAAP(context: context, mediaData: mediaData, type: type, artist: artist);
    } else if (type == "video") {
      database.updateUserData(queue: [mediaData], nowPlaying: mediaData);
      goToMedia(context: context);
    }
  }
}
