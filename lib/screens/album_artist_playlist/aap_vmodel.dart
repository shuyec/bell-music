import 'package:bell/screens/library/library_vmodel.dart';
import 'package:bell/services/auth.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import "package:bell/constants.dart";

class AAPViewModel extends ChangeNotifier {
  static const apiUrl = Constants.API_URL;
  final isAPLikedNotifier = ValueNotifier<bool>(false);
  final subStatusNotifier = ValueNotifier<bool?>(null);

  Future rateAlbumPlaylist({required String id, required String rating}) async {
    late Response response;
    late Response getResponse;
    bool connectionSuccessful = false;
    late String url;
    if (id.substring(0, 7) == "OLAK5uy") {
      url = "${apiUrl}api/album";
    } else if (id.substring(0, 2) == "PL" || id.substring(0, 6) == "RDCLAK") {
      url = "${apiUrl}api/playlist";
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

  bool changeIsAPLiked({required bool isAPLiked, required String id, required String privacy}) {
    late String rate;
    if (id == "LM" || privacy == "PRIVATE") {
      return true;
    } else if (isAPLiked) {
      rate = "INDIFFERENT";
      rateAlbumPlaylist(id: id, rating: rate);
    } else {
      rate = "LIKE";
      rateAlbumPlaylist(id: id, rating: rate);
    }
    isAPLikedNotifier.value = !isAPLiked;
    return !isAPLiked;
  }

  bool changeSubStatus({required String browseId, required bool subscribe}) {
    subscribeArtist(browseId: browseId, subscribe: subscribe);
    subStatusNotifier.value = subscribe;
    return subscribe;
  }

  Future<bool?> subscribeArtist({required String browseId, required bool subscribe}) async {
    late Response response;
    late Response getResponse;
    bool connectionSuccessful = false;
    late String url;
    url = "${apiUrl}api/artist";

    Dio dio = Dio();
    dio.options.contentType = 'application/json; charset=UTF-8';
    dio.options.headers['Connection'] = 'Keep-Alive';
    dio.options.headers["Accept"] = "application/json";

    while (!connectionSuccessful) {
      try {
        response = await dio.post(
          url,
          data: {'browseId': browseId, "subscribe": subscribe},
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
          data: {'browseId': browseId, "subscribe": subscribe},
        );
        if (getResponse.statusCode == 200) {
          connectionSuccessful = true;
          return subscribe;
        }
      } catch (e) {
        // print("errore è ${e.toString()}");
        // return Future.error(e.toString());
      }
    }
    return null;
  }

  Future<Map?> getAAPData({required String browseId, required String type}) async {
    late Response response;
    late Response getResponse;
    bool connectionSuccessful = false;
    late String url;
    if (type == "album") {
      url = "${apiUrl}api/album";
    } else if (type == "playlist") {
      url = "${apiUrl}api/playlist";
    } else if (type == "artist") {
      url = "${apiUrl}api/artist";
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
            'browseId': browseId,
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
            'browseId': browseId,
          },
        );
        if (getResponse.statusCode == 200) {
          connectionSuccessful = true;
          Map data = getResponse.data;

          // TODO: better solution than adding "rating" to the result
          if (type == "album" || type == "playlist") {
            late bool isAPInLibrary;
            bool areHeadersPresent = await Authentication().checkIfHeadersPresent();
            if (areHeadersPresent) {
              // for featured playlists
              if (browseId.substring(0, 7) == "VLRDCLA") {
                browseId = browseId.substring(2);
              }
              isAPInLibrary = await LibraryViewModel().checkIfInLibrary(browseId);
              isAPLikedNotifier.value = isAPInLibrary;
            } else {
              isAPInLibrary = false;
              isAPLikedNotifier.value = false;
            }
            data["rating"] = isAPLikedNotifier.value;
            List tracks = data["tracks"];
            Map? likedSongsPlaylist = await LibraryViewModel().getLikedSongs();
            if (likedSongsPlaylist != null) {
              List likedSongs = likedSongsPlaylist["tracks"];
              List likedSongsVideoIds = [];
              for (final likedSong in likedSongs) {
                likedSongsVideoIds.add(likedSong["videoId"]);
              }
              for (Map track in tracks) {
                bool isTrackLiked = likedSongsVideoIds.contains(track["videoId"]);
                if (isTrackLiked || track["likeStatus"] == "LIKE") {
                  track["likeStatus"] = "LIKE";
                } else {
                  track["likeStatus"] = "INDIFFERENT";
                }
              }
            }
          } else {
            isAPLikedNotifier.value = true;
          }

          return data;
        }
      } catch (e) {
        // print("errore è ${e.toString()}");
        // return Future.error(e.toString());
      }
    }
    return null;
  }

  Future<List?> getArtistAlbums({required String browseId, required String channelId, required String type}) async {
    bool connectionSuccessful = false;
    late Response response;
    late String url;
    url = "${apiUrl}api/artist/$type";
    Dio dio = Dio();
    dio.options.contentType = 'application/json; charset=UTF-8';
    dio.options.headers['Connection'] = 'Keep-Alive';
    dio.options.headers["Accept"] = "application/json";

    while (!connectionSuccessful) {
      try {
        response = await dio.post(
          url,
          data: {
            'channelId': channelId,
            'browseId': browseId,
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
        if (response.statusCode == 200) {
          connectionSuccessful = true;
          return response.data;
        }
      } catch (e) {
        // print("errore è ${e.toString()}");
        // return Future.error(e.toString());
      }
    }
    return null;
  }
}
