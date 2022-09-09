class AudioMetadata {
  final String title;
  final String artists;
  final String mediaUrl;
  final String thumbnailUrl;
  final String videoId;
  final bool? rating;

  AudioMetadata({
    required this.title,
    required this.artists,
    required this.mediaUrl,
    required this.thumbnailUrl,
    required this.videoId,
    required this.rating,
  });
}
