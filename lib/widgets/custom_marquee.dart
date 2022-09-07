import 'package:bell/general_functions.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class CustomMarquee extends StatelessWidget {
  const CustomMarquee({Key? key, required this.text, required this.style, required this.height, this.width = 0}) : super(key: key);

  final double height;
  final double width;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return width == 0
        ? SizedBox(
            height: height,
            child: willTextOverflow(
              text: text,
              style: style,
            )
                ? Marquee(
                    key: UniqueKey(),
                    text: text,
                    style: style,
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    blankSpace: 20.0,
                    velocity: 100.0,
                    startAfter: const Duration(seconds: 1),
                    pauseAfterRound: const Duration(seconds: 1),
                    showFadingOnlyWhenScrolling: true,
                    startPadding: 10.0,
                    accelerationDuration: const Duration(seconds: 1),
                    accelerationCurve: Curves.linear,
                    decelerationDuration: const Duration(milliseconds: 500),
                    decelerationCurve: Curves.easeOut,
                  )
                : SizedBox(
                    height: height,
                    child: Text(
                      text,
                      style: style,
                    ),
                  ),
          )
        : SizedBox(
            height: height,
            child: willTextOverflow(
              text: text,
              style: style,
              maxWidth: width,
            )
                ? Marquee(
                    key: UniqueKey(),
                    text: text,
                    style: style,
                    scrollAxis: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    blankSpace: 20.0,
                    velocity: 100.0,
                    startAfter: const Duration(seconds: 1),
                    pauseAfterRound: const Duration(seconds: 1),
                    showFadingOnlyWhenScrolling: true,
                    accelerationDuration: const Duration(seconds: 1),
                    accelerationCurve: Curves.linear,
                    decelerationDuration: const Duration(milliseconds: 500),
                    decelerationCurve: Curves.easeOut,
                  )
                : SizedBox(
                    height: height,
                    child: Text(
                      text,
                      style: style,
                    ),
                  ),
          );
  }
}
