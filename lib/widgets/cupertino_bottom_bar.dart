import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:iconsax/iconsax.dart';

class CupertinoBottomBar extends StatefulWidget {
  final int index;
  final ValueChanged<int> onChangedTab;

  const CupertinoBottomBar({
    required this.index,
    required this.onChangedTab,
    Key? key,
  }) : super(key: key);

  @override
  CupertinoBottomBarState createState() => CupertinoBottomBarState();
}

class CupertinoBottomBarState extends State<CupertinoBottomBar> {
  late ValueListenable<ScaffoldGeometry> geometryListenable;

  final items = <BottomNavigationBarItem>[
    // TODO: home
    // const BottomNavigationBarItem(
    //   icon: Icon(
    //     IconlyLight.home,
    //     color: Colors.white,
    //   ),
    //   activeIcon: Icon(
    //     IconlyBold.home,
    //     color: Colors.white,
    //     shadows: [
    //       BoxShadow(
    //         blurRadius: 30,
    //         color: Colors.white,
    //       ),
    //     ],
    //   ),
    //   label: 'Home',
    // ),
    const BottomNavigationBarItem(
      icon: Icon(
        Iconsax.play_circle4,
        color: Colors.white,
      ),
      activeIcon: Icon(
        Iconsax.play_circle5,
        color: Colors.white,
        shadows: [
          BoxShadow(
            blurRadius: 10,
            color: Colors.white,
          ),
        ],
      ),
      label: 'Playing',
    ),

    const BottomNavigationBarItem(
      icon: Icon(
        IconlyLight.search,
        color: Colors.white,
      ),
      activeIcon: Icon(
        IconlyBold.search,
        color: Colors.white,
        shadows: [
          BoxShadow(
            blurRadius: 30,
            color: Colors.white,
          ),
        ],
      ),
      label: 'Search',
    ),
    BottomNavigationBarItem(
      icon: Container(),
      label: "",
    ),
    const BottomNavigationBarItem(
      icon: Icon(
        Iconsax.music_library_2,
        color: Colors.white,
      ),
      activeIcon: Icon(
        Iconsax.music_library_25,
        color: Colors.white,
        shadows: [
          BoxShadow(
            blurRadius: 30,
            color: Colors.white,
          ),
        ],
      ),
      label: 'Library',
    ),
    const BottomNavigationBarItem(
      icon: Icon(
        IconlyLight.profile,
        color: Colors.white,
      ),
      activeIcon: Icon(
        IconlyBold.profile,
        color: Colors.white,
        shadows: [
          BoxShadow(
            blurRadius: 30,
            color: Colors.white,
          ),
        ],
      ),
      label: 'Account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoTabBar(
      activeColor: Colors.white,
      inactiveColor: Colors.white,
      backgroundColor: Colors.black,
      items: items,
      currentIndex: widget.index >= 2 ? widget.index + 1 : widget.index,
      onTap: (index) {
        final newIndex = getIndex(index);
        if (newIndex == null) {
          /// Ignore index == 2
          return;
        } else {
          widget.onChangedTab(newIndex);
        }
      },
    );
  }

  int? getIndex(int index) {
    if (index == 2) return null;

    final newIndex = index > 2 ? index - 1 : index;
    return newIndex;
  }
}
