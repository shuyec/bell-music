import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'dart:ui';

class CustomMarquee extends StatelessWidget {
  const CustomMarquee({Key? key, required this.text, required this.style, required this.height, this.width = 0}) : super(key: key);

  final double height;
  final double width;
  final String text;
  final TextStyle style;

  bool willTextOverflow({required String text, required TextStyle style, double maxWidth = 0}) {
    if (maxWidth == 0) {
      var pixelRatio = window.devicePixelRatio;
      var logicalScreenSize = window.physicalSize / pixelRatio;
      maxWidth = logicalScreenSize.width;
    }
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
  }

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
                    // velocity: 100.0,
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
            width: width,
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
                    // velocity: 100.0,
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
