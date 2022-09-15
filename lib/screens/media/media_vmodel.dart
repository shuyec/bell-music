import 'package:bell/general_functions.dart';
import 'package:bell/just_audio_modified.dart';
import 'package:bell/screens/library/library_vmodel.dart';
import 'package:bell/screens/media/audio_metadata.dart';
import 'package:bell/services/auth.dart';
import 'package:bell/services/database.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';

class MediaViewModel extends ChangeNotifier {
  final currentMediaTitleNotifier = ValueNotifier<String>('');
  final currentArtistsNotifier = ValueNotifier<String>("");
  final playlistNotifier = ValueNotifier<List<String>>([]);
  final progressNotifier = ProgressNotifier();
  final repeatButtonNotifier = RepeatButtonNotifier();
  final isFirstSongNotifier = ValueNotifier<bool>(true);
  final playButtonNotifier = PlayButtonNotifier();
  final isLastSongNotifier = ValueNotifier<bool>(true);
  final isShuffleModeEnabledNotifier = ValueNotifier<bool>(false);
  final isLoadingNotifier = ValueNotifier<bool>(true);
  final isLoadingTrackNotifier = ValueNotifier<bool>(false);
  final thumbnailUrlNotifier = ValueNotifier<String>("");
  final isMediaLikedNotifier = ValueNotifier<bool>(false);
  final currentVideoIdNotifier = ValueNotifier<String>("");
  final emptyQueueNotifier = ValueNotifier<bool>(false);

  late int nowPlayingIndex;
  late String thumbnailUrl;
  late dynamic currentMediaArtists;
  List queue = [];
  List originalQueue = [];

  late Map<String, dynamic> data;

  late AudioPlayer _audioPlayer;
  AudioPlayer get audioPlayer => _audioPlayer;
  late ConcatenatingAudioSource _playlist;
  late Database _database;
  late User? _user;
  late Map queueSongData;

  void update(User? user) {
    user = user;
    notifyListeners();
  }

  // @override
  // void dispose() {
  //   _database.updateNowPlayingData(audioplayer: _audioPlayer);
  //   _audioPlayer.dispose();
  //   super.dispose();
  // }

  void myDispose() {
    _database.updateNowPlayingData(audioplayer: _audioPlayer);
    _audioPlayer.dispose();
  }

  MediaViewModel() {
    init();
    notifyListeners();
  }

  void init() async {
    _user = FirebaseAuth.instance.currentUser;
    if (_user != null) {
      _database = Database(_user!.uid);
      _audioPlayer = AudioPlayer();
      playButtonNotifier.value = ButtonState.loading;

      data = await _database.getUserData(uid: _user!.uid) as Map<String, dynamic>;
      if (data["queue"].isNotEmpty) {
        emptyQueueNotifier.value = false;
        await updatePlayer();
      } else {
        isLoadingNotifier.value = false;
        emptyQueueNotifier.value = true;
      }
    }
  }

  Future<void> updatePlayer() async {
    if (isLoadingNotifier.value == true) {
      _audioPlayer.pause();
    }
    await _setInitialPlaylist();
    _listenForChangesInPlayerState();
    _listenForChangesInPlayerPosition();
    _listenForChangesInBufferedPosition();
    _listenForChangesInTotalDuration();
    _listenForChangesInSequenceState();
    if (isLoadingNotifier.value == true) {
      updateIsLoading(false);
    }
    // _audioPlayer.play();
    notifyListeners();
  }

  void updateIsLoading(bool isLoading) {
    if (emptyQueueNotifier.value == true) {
      emptyQueueNotifier.value = false;
    }
    isLoadingNotifier.value = isLoading;
  }

  void updateIsLoadingTrack(bool isLoading) {
    isLoadingTrackNotifier.value = isLoading;
  }

  void updateIsMediaLiked(bool isMediaLiked) {
    isMediaLikedNotifier.value = isMediaLiked;
  }

  Future<void> _setInitialPlaylist() async {
    data = await _database.getUserData(uid: _user!.uid) as Map<String, dynamic>;
    String nowPlayingVideoId = data["nowPlaying"]["videoId"];
    originalQueue = data["queue"];
    queue = [];
    notifyListeners();
    _playlist = ConcatenatingAudioSource(children: []);
    Duration playerPosition = parseDuration(data["nowPlaying"]["playerPosition"]);

    // RESOLVING AUDIO SOURCE

    List tempQueue = [];
    for (int i = 0; i < originalQueue.length; i++) {
      if (originalQueue[i]["videoId"] != null) {
        queue.add(originalQueue[i]);
        tempQueue.add(originalQueue[i]);
      }
    }
    originalQueue = tempQueue;

    for (int i = 0; i < queue.length; i++) {
      if (queue[i]["videoId"] == nowPlayingVideoId) {
        nowPlayingIndex = i;
      }
    }

    final resolvingAudioSource = [
      for (int i = 0; i < queue.length; i++)
        ResolvingAudioSource(
          uniqueId: originalQueue[i]["videoId"],
          resolveSoundUrl: ((uniqueId) async {
            uniqueId = queue[i]["videoId"];
            AudioMetadata? queueSong = await getMedia(videoId: queue[i]["videoId"]);
            if (queueSong != null) {
              queueSongData = {
                "title": queueSong.title,
                "artists": queueSong.artists,
                "songUrl": queueSong.mediaUrl,
                "thumbnailUrl": queueSong.thumbnailUrl,
                "videoId": queueSong.videoId,
              };
              print("DEBUG songUrl ${queueSong.mediaUrl}");
              queue[i] = queueSongData;
              currentMediaArtists = queueSong.artists;
              thumbnailUrl = queueSong.thumbnailUrl;
              _database.updateNowPlayingData(audioplayer: _audioPlayer, songData: queueSongData);
              return Uri.parse(queueSong.mediaUrl);
            }
            return null;
          }),
          tag: originalQueue[i],
        ),
    ];
    _playlist.addAll(resolvingAudioSource);

    await _audioPlayer.setAudioSource(
      _playlist,
      initialIndex: nowPlayingIndex,
      initialPosition: playerPosition,
    );
  }

  void _listenForChangesInPlayerState() {
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering || isLoadingNotifier.value) {
        playButtonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        playButtonNotifier.value = ButtonState.paused;
      } else if (processingState != ProcessingState.completed) {
        playButtonNotifier.value = ButtonState.playing;
      } else {
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });
  }

  void _listenForChangesInPlayerPosition() {
    _audioPlayer.positionStream.listen((position) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });
  }

  void _listenForChangesInBufferedPosition() {
    _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: bufferedPosition,
        total: oldState.total,
      );
    });
  }

  void _listenForChangesInTotalDuration() {
    _audioPlayer.durationStream.listen((totalDuration) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: totalDuration ?? Duration.zero,
      );
    });
  }

  void _listenForChangesInSequenceState() {
    _audioPlayer.sequenceStateStream.listen((sequenceState) async {
      if (sequenceState == null) return;

      // update current song title, artists and thumbnail
      final currentItem = sequenceState.currentSource;
      int currentTagIndex = originalQueue.indexOf(currentItem!.tag);
      if (currentTagIndex != -1) {
        final currentTag = queue[currentTagIndex];
        final String? title = currentTag["title"];
        currentMediaTitleNotifier.value = title ?? '';
        currentVideoIdNotifier.value = currentTag["videoId"];
        thumbnailUrlNotifier.value = currentTag["thumbnailUrl"] ?? "";

        final artists = currentTag["artists"] ?? "";
        if (artists.runtimeType == List) {
          currentArtistsNotifier.value = getArtists(artists);
        } else {
          currentArtistsNotifier.value = artists;
        }
      }

      // update playlist
      final playlist = sequenceState.effectiveSequence;
      final titles = playlist.map((item) => item.tag["title"] as String).toList();
      playlistNotifier.value = titles;

      // update shuffle mode
      isShuffleModeEnabledNotifier.value = sequenceState.shuffleModeEnabled;

      // update previous and next buttons
      if (playlist.isEmpty || currentItem == null) {
        isFirstSongNotifier.value = true;
        isLastSongNotifier.value = true;
      } else {
        isFirstSongNotifier.value = playlist.first == currentItem;
        isLastSongNotifier.value = playlist.last == currentItem;
      }
    });

    notifyListeners();
  }

  void play() async {
    _audioPlayer.play();
  }

  void pause() {
    _audioPlayer.pause();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  void onRepeatButtonPressed() {
    repeatButtonNotifier.nextState();
    switch (repeatButtonNotifier.value) {
      case RepeatState.off:
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
      case RepeatState.repeatSong:
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case RepeatState.repeatPlaylist:
        _audioPlayer.setLoopMode(LoopMode.all);
    }
  }

  void onPreviousSongButtonPressed() async {
    updateIsLoadingTrack(true);
    await _audioPlayer.seekToPrevious();
    _listenForChangesInSequenceState();
    updateIsLoadingTrack(false);
  }

  void onNextSongButtonPressed() async {
    updateIsLoadingTrack(true);
    await _audioPlayer.seekToNext();
    _listenForChangesInSequenceState();
    updateIsLoadingTrack(false);
  }

  void onShuffleButtonPressed() async {
    final enable = !_audioPlayer.shuffleModeEnabled;
    if (enable) {
      await _audioPlayer.shuffle();
    }
    await _audioPlayer.setShuffleModeEnabled(enable);
    _database.updateNowPlayingData(audioplayer: _audioPlayer, onShuffleClick: true);
  }

// TODO: does not work
  void addSong(Map media) {
    // final songNumber = _playlist.length + 1;
    // final song = Uri.parse('TODO audio url');
    // _playlist.add(AudioSource.uri(song, tag: 'Song $songNumber'));
    _database.updateQueue(media);
    _playlist.add(
      ResolvingAudioSource(
        uniqueId: media["videoId"],
        resolveSoundUrl: ((uniqueId) async {
          uniqueId = media["videoId"];
          AudioMetadata? queueSong = await getMedia(videoId: media["videoId"]);
          if (queueSong != null) {
            queueSongData = {
              "title": queueSong.title,
              "artists": queueSong.artists,
              "songUrl": queueSong.mediaUrl,
              "thumbnailUrl": queueSong.thumbnailUrl,
              "videoId": queueSong.videoId,
            };
            queue.add(queueSongData);
            currentMediaArtists = queueSong.artists;
            thumbnailUrl = queueSong.thumbnailUrl;
            _database.updateNowPlayingData(audioplayer: _audioPlayer, songData: queueSongData);
            return Uri.parse(queueSong.mediaUrl);
          }
          return null;
        }),
        tag: media,
      ),
    );
  }

  void removeSong() {
    final index = _playlist.length - 1;
    if (index < 0) return;
    _playlist.removeAt(index);
  }

  // API request get lyrics
  CancelToken cancelLyricsToken = CancelToken();
  Future<Map> getLyrics(String videoId) async {
    late Response response;
    late Response getResponse;
    String url = "http://10.0.2.2:8000/api/media";
    bool connectionSuccessful = false;

    Dio dio = Dio();
    dio.options.contentType = 'application/json; charset=UTF-8';
    dio.options.headers['Connection'] = 'Keep-Alive';
    dio.options.headers["Accept"] = "application/json";

    cancelLyricsToken.cancel();
    cancelLyricsToken = CancelToken();
    while (!connectionSuccessful) {
      try {
        response = await dio.post(
          url,
          data: {
            'videoId': videoId,
            "lyrics": true,
          },
          options: Options(
              followRedirects: true,
              validateStatus: (status) {
                return status! < 500;
              }),
          cancelToken: cancelLyricsToken,
        );
        String resphead = response.headers["location"]![0].toString();
        getResponse = await dio.post(
          resphead,
          data: {
            'videoId': videoId,
            "lyrics": true,
          },
          cancelToken: cancelLyricsToken,
        );
        if (getResponse.statusCode == 200) {
          connectionSuccessful = true;
          return getResponse.data;
        }
      } catch (e) {
        // return Future.error(e.toString());
      }
    }
    return {};
  }

  // API request rate media
  CancelToken cancelMediaRateToken = CancelToken();
  Future<bool> rateMedia({required String videoId, required String rating}) async {
    late Response response;
    late Response getResponse;
    String url = "http://10.0.2.2:8000/api/media";
    bool connectionSuccessful = false;

    Dio dio = Dio();
    dio.options.contentType = 'application/json; charset=UTF-8';
    dio.options.headers['Connection'] = 'Keep-Alive';
    dio.options.headers["Accept"] = "application/json";

    cancelMediaRateToken.cancel();
    cancelMediaRateToken = CancelToken();
    while (!connectionSuccessful) {
      try {
        response = await dio.post(
          url,
          data: {
            'videoId': videoId,
            "rating": rating,
          },
          options: Options(
              followRedirects: true,
              validateStatus: (status) {
                return status! < 500;
              }),
          cancelToken: cancelMediaRateToken,
        );
        String resphead = response.headers["location"]![0].toString();
        getResponse = await dio.post(
          resphead,
          data: {
            'videoId': videoId,
            "rating": rating,
          },
          cancelToken: cancelMediaRateToken,
        );
        if (getResponse.statusCode == 200) {
          connectionSuccessful = true;
          switch (rating) {
            case "LIKE":
              return true;
            case "DISLIKE":
            case "INDIFFERENT":
              return false;
            default:
              throw "Rating value invalid";
          }
        }
      } catch (e) {
        // return Future.error(e.toString());
      }
    }
    return false;
  }

  // API request get media
  CancelToken cancelMediaToken = CancelToken();
  Future<AudioMetadata?> getMedia({required String videoId}) async {
    late Response response;
    late Response getResponse;
    String url = "http://10.0.2.2:8000/api/media";
    bool connectionSuccessful = false;

    Dio dio = Dio();
    dio.options.contentType = 'application/json; charset=UTF-8';
    dio.options.headers['Connection'] = 'Keep-Alive';
    dio.options.headers["Accept"] = "application/json";

    cancelMediaToken.cancel();
    cancelMediaToken = CancelToken();
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
          cancelToken: cancelMediaToken,
        );
        String resphead = response.headers["location"]![0].toString();
        getResponse = await dio.post(
          resphead,
          data: {
            'videoId': videoId,
          },
          options: Options(
              followRedirects: true,
              validateStatus: (status) {
                return status! < 500;
              }),
          cancelToken: cancelMediaToken,
        );
        if (getResponse.statusCode == 200) {
          connectionSuccessful = true;
          late bool isMediaLiked;
          bool areHeadersPresent = await Authentication().checkIfHeadersPresent();
          if (areHeadersPresent) {
            isMediaLiked = await LibraryViewModel().checkIfInLibrary(videoId);
            isMediaLikedNotifier.value = isMediaLiked;
          } else {
            isMediaLiked = false;
            isMediaLikedNotifier.value = false;
          }
          Map<String, dynamic> data = getResponse.data;
          String title = data["title"];
          String artists = data["author"];
          String mediaUrl = data["audioUrl"];
          String thumbnailUrl = data["thumbnail"];
          return AudioMetadata(
              title: title, artists: artists, mediaUrl: mediaUrl, thumbnailUrl: thumbnailUrl, videoId: videoId, rating: isMediaLiked);
        }
      } catch (e) {
        // return Future.error(e.toString());
      }
    }
    return null;
  }
}
