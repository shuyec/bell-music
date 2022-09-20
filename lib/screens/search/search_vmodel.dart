import 'package:bell/constants.dart';
import 'package:dio/dio.dart';

class SearchViewModel {
  static const apiUrl = Constants.API_URL;

  Future<List?> createSearch(String search, int value, CancelToken cancelToken) async {
    late Response response;
    late Response getResponse;
    bool connectionSuccessful = false;
    final List<String> types = ["top", "songs", "albums", "artists", "videos", "community-playlists", "featured-playlists"];
    String url = "${apiUrl}api/search";

    if (value < 0 && value > 6) {
      throw Exception("Invalid value");
    }

    Dio dio = Dio();
    dio.options.contentType = 'application/json; charset=UTF-8';
    dio.options.headers['Connection'] = 'Keep-Alive';
    dio.options.headers["Accept"] = "application/json";

    while (!connectionSuccessful) {
      try {
        if (value != 0) {
          response = await dio.post(
            url,
            data: {
              'search': search,
            },
            queryParameters: {
              "type": types[value],
            },
            options: Options(
                followRedirects: true,
                validateStatus: (status) {
                  return status! < 500;
                }),
            cancelToken: cancelToken,
          );
        } else {
          response = await dio.post(
            url,
            data: {
              'search': search,
            },
            options: Options(
                followRedirects: true,
                validateStatus: (status) {
                  return status! < 500;
                }),
            cancelToken: cancelToken,
          );
        }

        String resphead = response.headers["location"]![0].toString();
        getResponse = await dio.post(
          resphead,
          data: {
            'search': search,
          },
          cancelToken: cancelToken,
        );
        if (getResponse.statusCode == 201) {
          connectionSuccessful = true;
          return getResponse.data;
        } else if (getResponse.statusCode == 404) {
          return [];
        }
      } catch (e) {
        // return Future.error(e.toString());
      }
    }
    return null;
  }
}
