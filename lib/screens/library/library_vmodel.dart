import 'package:dio/dio.dart';

class LibraryViewModel {
  Future rateAlbumPlaylist({required String id, required String rating}) async {
    late Response response;
    late Response getResponse;
    bool connectionSuccessful = false;
    late String url;
    if (id.substring(0, 7) == "OLAK5uy") {
      url = "http://10.0.2.2:8000/api/album";
    } else if (id.substring(0, 2) == "PL") {
      url = "http://10.0.2.2:8000/api/playlist";
    } else {
      return null;
    }

    Dio dio = Dio();
    dio.options.contentType = 'application/json; charset=UTF-8';
    dio.options.headers['Connection'] = 'Keep-Alive';
    dio.options.headers["Accept"] = "application/json";

    while (!connectionSuccessful) {
      try {
        response = await dio.post(
          url,
          data: {
            'browseId': id,
            "rating": rating,
          },
          options: Options(
              followRedirects: true,
              validateStatus: (status) {
                if (status == 500) {
                  return true;
                }
                return status! < 500;
              }),
        );
        String resphead = response.headers["location"]![0].toString();
        getResponse = await dio.post(
          resphead,
          data: {
            'browseId': id,
            "rating": rating,
          },
        );
        if (getResponse.statusCode == 200) {
          connectionSuccessful = true;
          return getResponse.data;
        }
      } catch (e) {
        // print("errore è ${e.toString()}");
        // return Future.error(e.toString());
      }
    }
    return null;
  }

  Future<bool> checkIfInLibrary(String id) async {
    if (id.substring(0, 2) == "PL") {
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
    }
    return false;
  }

  Future getResponseData({required String type}) async {
    late Response response;
    const String baseUrl = "http://10.0.2.2:8000/api/";
    late String apiUrl;
    bool connectionSuccessful = false;

    switch (type) {
      case "playlists":
        {
          apiUrl = "library/playlists";
        }
        break;
      case "liked":
        {
          apiUrl = "library/liked";
        }
        break;
      case "albums":
        {
          apiUrl = "library/albums";
        }
        break;
      case "songs":
        {
          apiUrl = "library/songs";
        }
        break;
      case "artists":
        {
          apiUrl = "library/artists";
        }
        break;
      case "subscriptions":
        {
          apiUrl = "library/subscriptions";
        }
        break;
      default:
        // {
        //   print("Error invalid apiUrl");
        // }
        break;
    }

    String url = baseUrl + apiUrl;
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
