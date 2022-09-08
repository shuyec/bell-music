import 'package:bell/screens/library/library_vmodel.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AAPViewModel extends ChangeNotifier {
  final isAPLikedNotifier = ValueNotifier<bool>(false);

  Future<bool?> changeIsAPLiked({required bool isAPLiked, required String id}) async {
    late String rate;
    if (id == "LM") {
      return true;
    } else if (isAPLiked) {
      rate = "INDIFFERENT";
      LibraryViewModel().rateAlbumPlaylist(id: id, rating: rate);
    } else {
      rate = "LIKE";
      LibraryViewModel().rateAlbumPlaylist(id: id, rating: rate);
    }
    isAPLikedNotifier.value = !isAPLiked;
    return !isAPLiked;
  }

  Future<Map?> getAAPData({required String browseId, required String type}) async {
    late Response response;
    late Response getResponse;
    bool connectionSuccessful = false;
    late String url;
    if (type == "album") {
      url = "http://10.0.2.2:8000/api/album";
    } else if (type == "playlist") {
      url = "http://10.0.2.2:8000/api/playlist";
    } else if (type == "artist") {
      url = "http://10.0.2.2:8000/api/artist";
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
          if (type == "album" || type == "playlist") {
            bool? isAPInLibrary = await LibraryViewModel().checkIfInLibrary(browseId);
            data["rating"] = isAPInLibrary;
            print("DEBUG isAPInLibrary GETAPP $isAPInLibrary");
            isAPLikedNotifier.value = isAPInLibrary as bool;
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
    url = "http://10.0.2.2:8000/api/artist/$type";
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
