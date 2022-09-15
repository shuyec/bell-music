import 'package:bell/general_functions.dart';
import 'package:bell/screens/loading_screen.dart';
import 'package:bell/services/auth.dart';
// import 'package:bell/services/database.dart';
import 'package:bell/widgets/custom_marquee.dart';
import 'package:bell/screens/media/media_vmodel.dart';
import 'package:bell/widgets/loading.dart';
import 'package:bell/widgets/error.dart';
// import 'package:drop_shadow/drop_shadow.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:iconsax/iconsax.dart';
import 'package:like_button/like_button.dart';
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
    const padding = EdgeInsets.all(20.0);
    return StreamProvider<User?>.value(
      value: context.watch<Authentication>().userStream,
      initialData: null,
      child: ValueListenableBuilder<bool>(
          valueListenable: context.watch<MediaViewModel>().emptyQueueNotifier,
          builder: (context, emptyQueue, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: context.watch<MediaViewModel>().isLoadingNotifier,
              builder: (context, isLoading, child) {
                return emptyQueue
                    ? Welcome(user: _user)
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
                                ValueListenableBuilder<String>(
                                    valueListenable: context.watch<MediaViewModel>().currentVideoIdNotifier,
                                    builder: (context, currentVideoId, _) {
                                      return IconButton(
                                        onPressed: () async {
                                          showCupertinoModalBottomSheet(
                                            context: context,
                                            expand: true,
                                            bounce: true,
                                            builder: (context) => Lyrics(videoId: currentVideoId),
                                          );
                                        },
                                        icon: const Icon(
                                          Iconsax.music_filter,
                                          color: Colors.white,
                                        ),
                                      );
                                    }),
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
                                        Expanded(child: Center(child: ThumbnailMedia())),
                                        RateButton(padding: padding),
                                        SizedBox(height: 10),
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

class Welcome extends StatelessWidget {
  const Welcome({super.key, required this.user});
  final User user;
  @override
  Widget build(BuildContext context) {
    final String? userName = user.displayName;
    return Scaffold(
      body: Center(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 120,
              child: Image.asset("assets/welcome.jpg"),
            ),
            Positioned(
              top: 120,
              child: Text(
                "Welcome, ${userName!.split(" ")[0]}!",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              child: Column(
                children: [
                  const Text(
                    "Your library is still empty!",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Find your best music in the search tab.",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 125,
                    child: Transform.translate(
                      offset: const Offset(-25, 50),
                      child: Transform.scale(
                        scaleY: 2,
                        scaleX: 1.2,
                        child: Transform.rotate(
                          angle: 1.5708,
                          child: Image.asset(
                            "assets/arrow.gif",
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RateButton extends StatelessWidget {
  const RateButton({super.key, required this.padding});
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
        valueListenable: context.watch<Authentication>().areHeadersPresentNotifier,
        builder: (context, areHeadersPresent, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: context.watch<MediaViewModel>().isMediaLikedNotifier,
            builder: (context, isMediaLiked, _) {
              return ValueListenableBuilder<String>(
                  valueListenable: context.watch<MediaViewModel>().currentVideoIdNotifier,
                  builder: (context, videoId, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CurrentMediaTitle(padding: padding, fontSize: 25),
                            CurrentMediaArtists(padding: padding, fontSize: 20),
                          ],
                        ),
                        const Spacer(),
                        areHeadersPresent
                            ? LikeButton(
                                isLiked: isMediaLiked,
                                likeBuilder: (_) {
                                  return isMediaLiked
                                      ? const Icon(
                                          Iconsax.heart5,
                                          color: Colors.redAccent,
                                        )
                                      : const Icon(
                                          Iconsax.heart4,
                                          color: Colors.white,
                                        );
                                },
                                onTap: (_) async {
                                  final mediaVMProvider = Provider.of<MediaViewModel>(context, listen: false);
                                  late String rating;
                                  if (isMediaLiked) {
                                    rating = "INDIFFERENT";
                                  } else {
                                    rating = "LIKE";
                                  }
                                  isMediaLiked = await mediaVMProvider.rateMedia(videoId: videoId, rating: rating);
                                  return isMediaLiked;
                                },
                              )
                            : const IconButton(
                                onPressed: null,
                                icon: Icon(
                                  Iconsax.heart_slash,
                                  color: Colors.grey,
                                ),
                              ),
                      ],
                    );
                  });
            },
          );
        });
  }
}

class CurrentMediaTitle extends StatelessWidget {
  const CurrentMediaTitle({Key? key, this.padding = EdgeInsets.zero, required this.fontSize}) : super(key: key);
  final EdgeInsets padding;
  final double fontSize;
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width - padding.left - padding.right - 50;
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
    final double width = MediaQuery.of(context).size.width - padding.left - padding.right - 50;
    return ValueListenableBuilder<String>(
      valueListenable: context.watch<MediaViewModel>().currentArtistsNotifier,
      builder: (_, currentArtists, __) {
        TextStyle artistsStyle = TextStyle(fontSize: fontSize);
        return CustomMarquee(text: currentArtists, style: artistsStyle, height: fontSize + 10, width: width);
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

class Lyrics extends StatelessWidget {
  const Lyrics({super.key, required this.videoId});
  final String videoId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: FutureBuilder(
          future: context.watch<MediaViewModel>().getLyrics(videoId),
          builder: (BuildContext context, AsyncSnapshot<Map?> snapshot) {
            Widget child;
            final data = snapshot.data;

            if (snapshot.connectionState != ConnectionState.done) {
              return const Loading();
            } else if (snapshot.hasData) {
              if (data != null && data.isNotEmpty) {
                late String currentArtist;
                final artists = data["artists"];
                if (artists.runtimeType == List) {
                  currentArtist = getArtists(artists);
                } else {
                  currentArtist = artists;
                }
                child = Padding(
                  padding: const EdgeInsets.all(10),
                  child: InkWell(
                    onTap: () {},
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Text(
                          '"${data["title"]}"',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'by $currentArtist',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          data["lyrics"],
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          data["source"],
                          style: const TextStyle(color: Colors.white),
                        )
                      ],
                    ),
                  ),
                );
              } else {
                child = const Center(
                  child: Text(
                    "Lyrics not available",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                );
              }
            } else if (snapshot.hasError) {
              String error = "Connection error. Try again.";
              return Error(error: error);
            } else {
              child = const Loading();
            }
            return child;
          },
        ),
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
