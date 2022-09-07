import 'dart:ui';
import 'package:flutter/material.dart';

String capitalize(String type) {
  return "${type[0].toUpperCase()}${type.substring(1).toLowerCase()}";
}

Duration parseDuration(String s) {
  int hours = 0;
  int minutes = 0;
  int micros;
  List<String> parts = s.split(':');
  if (parts.length > 2) {
    hours = int.parse(parts[parts.length - 3]);
  }
  if (parts.length > 1) {
    minutes = int.parse(parts[parts.length - 2]);
  }
  micros = (double.parse(parts[parts.length - 1]) * 1000000).round();
  return Duration(hours: hours, minutes: minutes, microseconds: micros);
}

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

String getArtists(List artistsList) {
  String artists = artistsList[0]["name"].toString();
  if (artistsList.length > 1) {
    for (int i = 1; i < artistsList.length; i++) {
      artists = "$artists, ${artistsList[i]["name"]}";
    }
  }
  return artists;
}
