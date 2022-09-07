import 'package:bell/screens/loading_screen.dart';
import 'package:bell/services/auth.dart';
import 'package:bell/widgets/custom_marquee.dart';
import 'package:bell/screens/media/media_vmodel.dart';
import 'package:bell/widgets/loading.dart';
// import 'package:drop_shadow/drop_shadow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';
// import 'package:webview_flutter/webview_flutter.dart';
import 'notifiers/play_button_notifier.dart';
import 'notifiers/progress_notifier.dart';
import 'notifiers/repeat_button_notifier.dart';

class Media extends StatefulWidget {
  const Media({Key? key}) : super(key: key);
  @override
  State<Media> createState() => _MediaState();
}

class _MediaState extends State<Media> {
  late User _user;

  // late MediaViewModel _MediaViewModel;
  // late Database _database;

  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser!;
    // _database = Database(_user.uid);
    super.initState();
  }

  // @override
  // void didChangeDependencies() {
  //   _MediaViewModel = Provider.of<MediaViewModel>(context, listen: true);
  //   super.didChangeDependencies();
  // }

  @override
  void dispose() {
    // _database.updateNowPlayingData(audioplayer: _MediaViewModel.audioPlayer);
    // _MediaViewModel.audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? userName = _user.displayName;
    const padding = EdgeInsets.all(20.0);
    return StreamProvider<User?>.value(
      value: Authentication().userStream,
      initialData: null,
      child: ValueListenableBuilder<bool>(
          valueListenable: context.watch<MediaViewModel>().emptyQueueNotifier,
          builder: (context, emptyQueue, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: context.watch<MediaViewModel>().isLoadingNotifier,
              builder: (context, isLoading, child) {
                return emptyQueue
                    ? Scaffold(
                        body: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Welcome, $userName!",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15.0),
                                child: Image.asset("assets/beluga.gif"),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Find your best music in the search tab.",
                              style: TextStyle(
                                // fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      )
                    : (!isLoading)
                        ? Scaffold(
                            appBar: AppBar(
                              centerTitle: true,
                              title: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: const [
                                  // TODO: modal bottom sheet bug
                                  // Positioned(
                                  //   bottom: 5,
                                  //   child: Icon(
                                  //     Iconsax.minus,
                                  //     color: Colors.white54,
                                  //     size: 50,
                                  //   ),
                                  // ),
                                  Text(
                                    "Now Playing",
                                    style: TextStyle(fontSize: 20.0),
                                  ),
                                ],
                              ),
                              leading: IconButton(
                                onPressed: () {
                                  showCupertinoModalBottomSheet(
                                    context: context,
                                    expand: false,
                                    bounce: true,
                                    builder: (context) => const QueuePlaylist(),
                                  );
                                },
                                icon: const Icon(
                                  Iconsax.music_playlist,
                                  color: Colors.white,
                                ),
                              ),
                              actions: [
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Iconsax.music_filter,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            body: ValueListenableBuilder<bool>(
                              valueListenable: context.watch<MediaViewModel>().isLoadingTrackNotifier,
                              builder: (context, isLoadingTrack, _) {
                                if (isLoadingTrack) {
                                  return const Loading();
                                } else {
                                  return Padding(
                                    padding: padding,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: const [
                                        Expanded(child: ThumbnailMedia()),
                                        CurrentMediaTitle(padding: padding, fontSize: 35),
                                        SizedBox(height: 10),
                                        CurrentMediaArtists(padding: padding, fontSize: 25),
                                        SizedBox(height: 10),

                                        // AddRemoveSongButtons(),
                                        AudioProgressBar(),
                                        // AudioControlButtons(),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          )
                        : const LoadingScreen();
              },
            );
          }),
    );
  }
}

class CurrentMediaTitle extends StatelessWidget {
  const CurrentMediaTitle({Key? key, this.padding = EdgeInsets.zero, required this.fontSize}) : super(key: key);
  final EdgeInsets padding;
  final double fontSize;
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width - padding.left - padding.right - 10;
    return ValueListenableBuilder<String>(
      valueListenable: context.watch<MediaViewModel>().currentMediaTitleNotifier,
      builder: (_, title, __) {
        TextStyle titleStyle = TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold);
        return CustomMarquee(text: title, style: titleStyle, height: fontSize + 15, width: width);
      },
    );
  }
}

class CurrentMediaArtists extends StatelessWidget {
  const CurrentMediaArtists({Key? key, this.padding = EdgeInsets.zero, required this.fontSize}) : super(key: key);
  final EdgeInsets padding;
  final double fontSize;
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width - padding.left - padding.right - 10;
    final String artists = context.watch<MediaViewModel>().currentArtistsNotifier.value;
    TextStyle artistsStyle = TextStyle(fontSize: fontSize);
    return ValueListenableBuilder<String>(
      valueListenable: context.watch<MediaViewModel>().currentArtistsNotifier,
      builder: (context, currentArtists, _) {
        return CustomMarquee(text: artists, style: artistsStyle, height: fontSize + 10, width: width);
      },
    );
  }
}

class QueuePlaylist extends StatelessWidget {
  const QueuePlaylist({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: ValueListenableBuilder<List<String>>(
          valueListenable: context.watch<MediaViewModel>().playlistNotifier,
          builder: (context, playlistTitles, _) {
            return ListView.builder(
              itemCount: playlistTitles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    playlistTitles[index],
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AddRemoveSongButtons extends StatelessWidget {
  const AddRemoveSongButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: "addSong",
            onPressed: context.watch<MediaViewModel>().addSong,
            child: const Icon(Icons.add),
          ),
          FloatingActionButton(
            heroTag: "removeSong",
            onPressed: context.watch<MediaViewModel>().removeSong,
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}

class AudioProgressBar extends StatelessWidget {
  const AudioProgressBar({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: context.watch<MediaViewModel>().progressNotifier,
      builder: (_, value, __) {
        return ProgressBar(
          progress: value.current,
          buffered: value.buffered,
          total: value.total,
          onSeek: context.watch<MediaViewModel>().seek,
          progressBarColor: Colors.white,
          baseBarColor: Colors.white.withOpacity(0.24),
          bufferedBarColor: Colors.white.withOpacity(0.24),
          thumbColor: Colors.white,
        );
      },
    );
  }
}

// TODO: modal bottom sheet bug
class AudioControlButtons extends StatelessWidget {
  const AudioControlButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: const [
        ShuffleButton(color: Colors.black),
        PreviousSongButton(color: Colors.black),
        // PlayButton(),
        NextSongButton(color: Colors.black),
        RepeatButton(color: Colors.black),
      ],
    );
  }
}

class RepeatButton extends StatelessWidget {
  const RepeatButton({Key? key, this.color = Colors.white}) : super(key: key);
  final Color color;
  @override
  Widget build(BuildContext context) {
    List<BoxShadow> buttonShadow = const [
      BoxShadow(
        blurRadius: 50,
        color: Colors.white,
      ),
    ];
    return ValueListenableBuilder<RepeatState>(
      valueListenable: context.read<MediaViewModel>().repeatButtonNotifier,
      builder: (context, value, child) {
        Icon icon;
        switch (value) {
          case RepeatState.off:
            icon = const Icon(Iconsax.repeate_music, color: Colors.grey);
            break;
          case RepeatState.repeatSong:
            icon = Icon(
              Iconsax.repeate_one,
              color: color,
              shadows: buttonShadow,
            );
            break;
          case RepeatState.repeatPlaylist:
            icon = Icon(
              Iconsax.repeate_music5,
              color: color,
              shadows: buttonShadow,
            );
            break;
        }
        return IconButton(
          icon: icon,
          onPressed: context.watch<MediaViewModel>().onRepeatButtonPressed,
        );
      },
    );
  }
}

class PreviousSongButton extends StatelessWidget {
  const PreviousSongButton({Key? key, this.color = Colors.white}) : super(key: key);
  final Color color;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: context.watch<MediaViewModel>().isFirstSongNotifier,
      builder: (_, isFirst, __) {
        return IconButton(
          icon: isFirst
              ? const Icon(
                  Iconsax.previous,
                  color: Colors.grey,
                )
              : Icon(
                  Iconsax.previous5,
                  color: color,
                ),
          onPressed: (isFirst) ? null : context.watch<MediaViewModel>().onPreviousSongButtonPressed,
        );
      },
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({Key? key, this.color = Colors.white}) : super(key: key);
  final Color color;
  @override
  Widget build(BuildContext context) {
    Color iconColor = color;
    return ValueListenableBuilder<ButtonState>(
      valueListenable: context.watch<MediaViewModel>().playButtonNotifier,
      builder: (_, value, __) {
        switch (value) {
          case ButtonState.loading:
            return Container(
              margin: const EdgeInsets.all(8.0),
              width: 60,
              height: 60,
              child: SpinKitChasingDots(
                size: 50.0,
                color: iconColor,
              ),
            );
          case ButtonState.paused:
            return IconButton(
              splashRadius: 35,
              icon: Icon(
                Iconsax.play5,
                color: iconColor,
                shadows: [
                  BoxShadow(
                    blurRadius: 20,
                    color: iconColor,
                  ),
                ],
              ),
              iconSize: 60.0,
              onPressed: context.watch<MediaViewModel>().play,
            );
          case ButtonState.playing:
            return IconButton(
              splashRadius: 35,
              icon: Icon(
                Iconsax.pause5,
                color: iconColor,
                shadows: [
                  BoxShadow(
                    blurRadius: 20,
                    color: iconColor,
                  ),
                ],
              ),
              iconSize: 60.0,
              onPressed: context.watch<MediaViewModel>().pause,
            );
        }
      },
    );
  }
}

class NextSongButton extends StatelessWidget {
  const NextSongButton({Key? key, this.color = Colors.white}) : super(key: key);
  final Color color;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: context.watch<MediaViewModel>().isLastSongNotifier,
      builder: (_, isLast, __) {
        return IconButton(
          icon: isLast
              ? const Icon(
                  Iconsax.next,
                  color: Colors.grey,
                )
              : Icon(
                  Iconsax.next5,
                  color: color,
                ),
          onPressed: (isLast) ? null : context.watch<MediaViewModel>().onNextSongButtonPressed,
        );
      },
    );
  }
}

class ShuffleButton extends StatelessWidget {
  const ShuffleButton({Key? key, this.color = Colors.white}) : super(key: key);
  final Color color;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: context.watch<MediaViewModel>().isShuffleModeEnabledNotifier,
      builder: (context, isEnabled, child) {
        return IconButton(
          icon: (isEnabled)
              ? Icon(
                  Iconsax.shuffle,
                  color: color,
                  shadows: const [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.white,
                    ),
                  ],
                )
              : const Icon(Iconsax.shuffle, color: Colors.grey),
          onPressed: context.watch<MediaViewModel>().onShuffleButtonPressed,
        );
      },
    );
  }
}

class ThumbnailMedia extends StatelessWidget {
  const ThumbnailMedia({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: context.watch<MediaViewModel>().thumbnailUrlNotifier,
      builder: (_, thumbnailUrl, __) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15.0),
          child: thumbnailUrl != ""
              ? Image.network(
                  thumbnailUrl!,
                )
              : const SpinKitChasingDots(
                  color: Colors.white,
                ),
        );
      },
    );
  }
}
