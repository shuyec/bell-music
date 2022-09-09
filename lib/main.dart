import 'package:bell/screen_navigator.dart';
import 'package:bell/screens/album_artist_playlist/aap_vmodel.dart';
import 'package:bell/screens/album_artist_playlist/album_playlist.dart';
import 'package:bell/screens/album_artist_playlist/artist.dart';
import 'package:bell/screens/album_artist_playlist/artist_albums.dart';
import 'package:bell/screens/authenticate/authenticate.dart';
import 'package:bell/screens/library/library_content.dart';
import 'package:bell/screens/media/media_vmodel.dart';
import 'package:bell/services/auth.dart';
import 'package:bell/widgets/cupertino_bottom_bar.dart';
import 'package:bell/widgets/measure_size.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bell/screens/account.dart';
import 'package:bell/screens/home/home.dart';
import 'package:bell/screens/media/media.dart';
import 'package:bell/screens/library/library.dart';
import 'package:bell/screens/search/search.dart';
import 'package:bell/screens/wrapper.dart';
import 'package:iconsax/iconsax.dart';
// import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    const Bell(),
  );
}

class Bell extends StatelessWidget {
  const Bell({Key? key}) : super(key: key);
  // static User user = FirebaseAuth.instance.currentUser!;
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => Authentication()),
          // ChangeNotifierProxyProvider<Authentication, MediaViewModel>(
          //   create: (_) => MediaViewModel(),
          //   update: (context, auth, mediaVM) => mediaVM!..update(auth.user),
          // ),
          ChangeNotifierProvider(create: (_) => MediaViewModel()),
          ChangeNotifierProvider(create: (_) => AAPViewModel()),
        ],
        child: StreamProvider<User?>.value(
          value: Authentication().userStream,
          initialData: null,
          child: MaterialApp(
            title: 'Bell',
            theme: ThemeData(
                disabledColor: Colors.grey[700],
                scaffoldBackgroundColor: Colors.black,
                textTheme: Theme.of(context).textTheme.apply(
                      fontFamily: "Gilroy",
                      bodyColor: Colors.white,
                      displayColor: Colors.white,
                    ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.black,
                ),
                iconTheme: const IconThemeData(
                  color: Colors.white,
                )),
            initialRoute: "/",
            routes: {
              "/": (context) => const Wrapper(),
              "/login": (context) => const Authenticate(),
              "/home": (context) => const Home(),
              "/search": (context) => const Search(),
              "/media": (context) => const Media(),
              "/album-playlist": (context) => const AlbumPlaylist(),
              "/artist": (context) => const Artist(),
              "/artist-albums": (context) => const ArtistAlbums(),
              "/library-content": (context) => const LibraryContent(),
            },
          ),
        ));
  }
}

// BOTTOM BAR
class Main extends StatefulWidget {
  const Main({Key? key}) : super(key: key);

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  int selectedIndex = 0;
  final CupertinoTabController _tabController = CupertinoTabController();
  final GlobalKey<NavigatorState> _homeNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _searchNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _libraryNavKey = GlobalKey<NavigatorState>();
  final GlobalKey<NavigatorState> _accountNavKey = GlobalKey<NavigatorState>();
  final screens = <String>[
    "/media",
    "/search",
    "/library",
    "/account",
  ];

  void onChangedTab(int index) {
    final listOfKeys = <GlobalKey<NavigatorState>>[
      _homeNavKey,
      _searchNavKey,
      _libraryNavKey,
      _accountNavKey,
    ];
// Navigator.of(context).popUntil((route) => route.isFirst);
    if (index == _tabController.index) {
      listOfKeys[index].currentState!.popUntil((route) => route.isFirst);
    }
    setState(() {
      _tabController.index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ScreenNavigator screenNavigator = ScreenNavigator();
    final listOfKeys = <GlobalKey<NavigatorState>>[
      _homeNavKey,
      _searchNavKey,
      _libraryNavKey,
      _accountNavKey,
    ];
    final routes = {
      "/": (context) => const Wrapper(),
      "/login": (context) => const Authenticate(),
      "/home": (context) => const Home(),
      "/search": (context) => const Search(),
      "/media": (context) => const Media(),
      "/album-playlist": (context) => const AlbumPlaylist(),
      "/artist": (context) => const Artist(),
      "/artist-albums": (context) => const ArtistAlbums(),
      "/library-content": (context) => const LibraryContent(),
    };
    double paddingLeft = 165;
    double paddingRight = 70;
    return WillPopScope(
      onWillPop: () async {
        return !await listOfKeys[_tabController.index].currentState!.maybePop();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: IndexedStack(
          index: _tabController.index,
          children: [
            CupertinoTabView(navigatorKey: listOfKeys[0], routes: routes, builder: (context) => const Media()),
            CupertinoTabView(navigatorKey: listOfKeys[1], routes: routes, builder: (context) => const Search()),
            CupertinoTabView(navigatorKey: listOfKeys[2], routes: routes, builder: (context) => const Library()),
            CupertinoTabView(navigatorKey: listOfKeys[3], routes: routes, builder: (context) => const Account()),
          ],
        ),
        bottomNavigationBar: Visibility(
          visible: MediaQuery.of(context).viewInsets.bottom == 0.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ValueListenableBuilder<bool>(
                  valueListenable: context.read<MediaViewModel>().isLoadingNotifier,
                  builder: (context, isLoading, child) {
                    // TODO: MBS bug
                    // navigate to tab 0 when media click
                    if (isLoading) {
                      _tabController.index = 0;
                    }
                    return !isLoading
                        ? Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              color: Colors.white,
                            ),
                            alignment: Alignment.center,
                            width: double.infinity,
                            height: 70,
                            child: _tabController.index != 0
                                ? ListTile(
                                    title: ColorFiltered(
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.difference,
                                      ),
                                      child: CurrentMediaTitle(fontSize: 15, padding: EdgeInsets.only(left: paddingLeft, right: paddingRight)),
                                    ),
                                    subtitle: ColorFiltered(
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.difference,
                                      ),
                                      child: CurrentMediaArtists(fontSize: 15, padding: EdgeInsets.only(left: paddingLeft, right: paddingRight)),
                                    ),
                                    leading: MeasureSize(
                                        onChange: (size) {
                                          setState(() {
                                            paddingLeft = size.width;
                                          });
                                        },
                                        child: const ThumbnailMedia()),
                                    trailing: MeasureSize(
                                      onChange: (size) {
                                        paddingRight = size.width;
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          PreviousSongButton(color: Colors.black),
                                          NextSongButton(color: Colors.black),
                                        ],
                                      ),
                                    ),
                                    onTap: (() {
                                      // TODO: MBS bug
                                      onChangedTab(0);
                                      // screenNavigator.openMediaModal(context);
                                    }),
                                  )
                                : const AudioControlButtons())
                        : const SizedBox();
                  }),
              CupertinoBottomBar(
                index: _tabController.index,
                onChangedTab: onChangedTab,
              ),
            ],
          ),
        ),
        floatingActionButton: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: 5,
              child: FloatingActionButton(
                onPressed: () {},
                elevation: 0,
                highlightElevation: 0,
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(side: const BorderSide(width: 3, color: Colors.white), borderRadius: BorderRadius.circular(100)),
                child: FittedBox(
                  child: context.watch<MediaViewModel>().queue.isEmpty ? const Icon(Iconsax.music_play5) : const PlayButton(),
                ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}
