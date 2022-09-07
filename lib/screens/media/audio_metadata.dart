import 'package:dio/dio.dart';

class AudioMetadata {
  final String title;
  final String artists;
  final String mediaUrl;
  final String thumbnailUrl;
  final String videoId;

  AudioMetadata({
    required this.title,
    required this.artists,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.videoId,
  });
}

Future<AudioMetadata?> getMedia({required String videoId}) async {
  late Response response;
  late Response getResponse;
  String url = "http://10.0.2.2:8000/api/media";
  bool connectionSuccessful = false;

  Dio dio = Dio();
  dio.options.contentType = 'application/json; charset=UTF-8';
  dio.options.headers['Connection'] = 'Keep-Alive';
  dio.options.headers["Accept"] = "application/json";

  while (!connectionSuccessful) {
    try {
      response = await dio.post(
        url,
        data: {
          'videoId': videoId,
        },
        options: Options(
            followRedirects: true,
            validateStatus: (status) {
              return status! < 500;
            }),
      );
      String resphead = response.headers["location"]![0].toString();
      getResponse = await dio.post(
        resphead,
        data: {
          'videoId': videoId,
        },
      );
      if (getResponse.statusCode == 200) {
        connectionSuccessful = true;
        Map<String, dynamic> data = getResponse.data;
        String title = data["title"];
        String artists = data["author"];
        String mediaUrl = data["audioUrl"];
        String thumbnailUrl = data["thumbnail"];
        String videoId = data["videoId"];
        return AudioMetadata(title: title, artists: artists, mediaUrl: mediaUrl, thumbnailUrl: thumbnailUrl, videoId: videoId);
      }
    } catch (e) {
      // return Future.error(e.toString());
    }
  }
  return null;
}
