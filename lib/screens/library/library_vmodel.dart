import 'package:bell/constants.dart';
import 'package:dio/dio.dart';

class LibraryViewModel {
  static const apiUrl = Constants.API_URL;

  Future<bool> checkIfInLibrary(String id) async {
    if (id.substring(0, 2) == "PL" || id.substring(0, 5) == "RDCLA") {
      List? libraryPlaylists = await getLibraryPlaylists();
      if (libraryPlaylists != null) {
        for (final playlist in libraryPlaylists) {
          if (playlist["playlistId"] == id) {
            return true;
          }
        }
      }
      return false;
    } else if (id.substring(0, 5) == "MPREb") {
      List? libraryAlbums = await getLibraryAlbums();
      if (libraryAlbums != null) {
        for (final album in libraryAlbums) {
          if (album["browseId"] == id) {
            return true;
          }
        }
      }
      return false;
    } else if (id.length == 11) {
      Map? likedSongsPlaylist = await getLikedSongs();
      if (likedSongsPlaylist != null) {
        List likedSongs = likedSongsPlaylist["tracks"];
        if (likedSongs.isNotEmpty) {
          for (final song in likedSongs) {
            if (song["videoId"] == id) {
              return true;
            }
          }
          return false;
        } else {
          return false;
        }
      }
    }
    return false;
  }

  // Future<bool?> checkIfInSubscriptions(String browseId) async {
  //   final librarySubscriptions = await getLibrarySubscriptions();
  //   if (librarySubscriptions != null) {
  //     for (final sub in librarySubscriptions) {
  //       if (sub["browseId"] == browseId) {
  //         return true;
  //       }
  //     }
  //     return false;
  //   }
  //   return null;
  // }

  Future getResponseData({required String type}) async {
    late Response response;
    late String url;
    bool connectionSuccessful = false;

    switch (type) {
      case "playlists":
        {
          url = "api/library/playlists";
        }
        break;
      case "liked":
        {
          url = "api/library/liked";
        }
        break;
      case "albums":
        {
          url = "api/library/albums";
        }
        break;
      case "songs":
        {
          url = "api/library/songs";
        }
        break;
      case "artists":
        {
          url = "api/library/artists";
        }
        break;
      case "subscriptions":
        {
          url = "api/library/subscriptions";
        }
        break;
      default:
        // {
        //   print("Error invalid apiUrl");
        // }
        break;
    }

    url = apiUrl + url;
    Dio dio = Dio();
    dio.options.contentType = 'application/json; charset=UTF-8';
    dio.options.headers['Connection'] = 'Keep-Alive';
    dio.options.headers["Accept"] = "application/json";

    while (!connectionSuccessful) {
      try {
        response = await dio.get(
          url,
          options: Options(
              followRedirects: true,
              validateStatus: (status) {
                if (status == 500) {
                  return true;
                }
                return status! < 500;
              }),
        );

        if (response.statusCode == 200) {
          connectionSuccessful = true;
          return response.data;
        }
      } catch (e) {
        // return Future.error(e.toString());
      }
    }
    return null;
  }

  Future<Map?> getLikedSongs() async {
    return await getResponseData(type: "liked");
  }

  Future<List?> getLibraryPlaylists() async {
    return await getResponseData(type: "playlists");
  }

  Future<List?> getLibraryAlbums() async {
    return await getResponseData(type: "albums");
  }

  Future<List?> getLibrarySongs() async {
    return await getResponseData(type: "songs");
  }

  Future<List?> getLibraryArtists() async {
    return await getResponseData(type: "artists");
  }

  Future<List?> getLibrarySubscriptions() async {
    return await getResponseData(type: "subscriptions");
  }
}
