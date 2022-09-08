import 'package:bell/general_functions.dart';
import 'package:bell/just_audio_modified.dart';
import 'package:bell/screens/media/audio_metadata.dart';
import 'package:bell/services/database.dart';
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
  final emptyQueueNotifier = ValueNotifier<bool>(true);

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

      data = await _database.getUserData(uid: _user!.uid) as Map<String, dynamic>;
      playButtonNotifier.value = ButtonState.loading;
      if (data["queue"].isNotEmpty) {
        emptyQueueNotifier.value = false;
        await updatePlayer();
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
    _audioPlayer.play();
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

  Future<void> _setInitialPlaylist() async {
    data = await _database.getUserData(uid: _user!.uid) as Map<String, dynamic>;
    String nowPlayingVideoId = data["nowPlaying"]["videoId"];
    originalQueue = data["queue"];
    queue = originalQueue;
    notifyListeners();
    _playlist = ConcatenatingAudioSource(children: []);
    Duration playerPosition = parseDuration(data["nowPlaying"]["playerPosition"]);

    // RESOLVING AUDIO SOURCE

    List tempQueue = [];
    // remove not playable tracks from queue and set nowPlayingIndex
    for (int i = 0; i < queue.length; i++) {
      if (queue[i]["videoId"] != null) {
        tempQueue.add(queue[i]);
        if (queue[i]["videoId"] == nowPlayingVideoId) {
          nowPlayingIndex = i;
        }
      }
    }
    queue = tempQueue;

    final resolvingAudioSource = [
      for (int i = 0; i < queue.length; i++)
        ResolvingAudioSource(
          uniqueId: queue[i]["videoId"],
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
              // print("DEBUG songUrl ${queueSong.mediaUrl}");
              queue[i] = queueSongData;
              currentMediaArtists = queueSong.artists;
              thumbnailUrl = queueSong.thumbnailUrl;
              _database.updateNowPlayingData(audioplayer: _audioPlayer, songData: queueSongData);
              return Uri.parse(queueSong.mediaUrl);
            }
            return null;
          }),
          tag: queue[i],
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

  void addSong() {
    final songNumber = _playlist.length + 1;
    final song = Uri.parse('TODO audio url');
    _playlist.add(AudioSource.uri(song, tag: 'Song $songNumber'));
  }

  void removeSong() {
    final index = _playlist.length - 1;
    if (index < 0) return;
    _playlist.removeAt(index);
  }
}
