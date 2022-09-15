import 'package:bell/just_audio_modified.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  final String uid;
  Database(this.uid);

  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  void updateQueue(Map media) async {
    final userDoc = usersCollection.doc(uid);
    final userData = await getUserData(uid: uid);
    List queue = userData!["queue"];
    queue.add(media);
    userDoc.update({
      "queue": queue,
    });
  }

  void updateUserData({required List queue, required Map nowPlaying}) {
    final userDoc = usersCollection.doc(uid);
    userDoc.update({
      "queue": queue,
    });
    nowPlaying["playerPosition"] = Duration.zero.toString();
    nowPlaying["shuffle"] = false;
    userDoc.update({
      "nowPlaying": nowPlaying,
    });
  }

  void updateNowPlayingData({required AudioPlayer audioplayer, Map songData = const {}, bool onShuffleClick = false}) {
    Map nowPlayingData;
    final userDoc = usersCollection.doc(uid);
    if (songData.isNotEmpty) {
      nowPlayingData = songData;
      nowPlayingData["playerPosition"] = Duration.zero.toString();
      nowPlayingData["shuffle"] = audioplayer.shuffleModeEnabled;
      userDoc.update({
        "nowPlaying": nowPlayingData,
      });
    } else if (onShuffleClick) {
      userDoc.update({
        "nowPlaying.shuffle": audioplayer.shuffleModeEnabled,
      });
    } else {
      audioplayer.positionStream.listen((position) {
        userDoc.update({
          "nowPlaying.playerPosition": position.toString(),
          "nowPlaying.shuffle": audioplayer.shuffleModeEnabled,
        });
      });
    }
  }

  String _getSearchId(Map search) {
    if (search["browseId"] != null) {
      return search["browseId"];
    } else if (search["videoId"] != null) {
      return search["videoId"];
    }
    return "";
  }

  void updateSearchHistory({required Map search, String type = "search"}) async {
    final data = await getUserData(uid: uid);
    final Map searchHistory = await data!["searchHistory"];
    final searchHistoryData = searchHistory["data"];
    final searchHistoryId = searchHistory["id"];
    final userDoc = usersCollection.doc(uid);
    String id = _getSearchId(search);

    if (type == "delete") {
      searchHistoryData.removeAt(searchHistoryId.indexOf(id));
      searchHistoryId.removeAt(searchHistoryId.indexOf(id));
    } else if (type == "search") {
      if (searchHistoryData.isEmpty) {
        searchHistoryData.add(search);
        searchHistoryId.add(id);
      } else if (searchHistoryId.contains(id)) {
        searchHistoryData.removeAt(searchHistoryId.indexOf(id));
        searchHistoryId.removeAt(searchHistoryId.indexOf(id));
        searchHistoryData.insert(0, search);
        searchHistoryId.insert(0, id);
      } else {
        searchHistoryData.insert(0, search);
        searchHistoryId.insert(0, id);
      }
    } else {
      return null;
    }
    userDoc.update({
      "searchHistory.data": searchHistoryData,
      "searchHistory.id": searchHistoryId,
    });
  }

  void deleteSearch(Map search) async {
    final data = await getUserData(uid: uid);
    final Map searchHistory = await data!["searchHistory"];
    final List searchHistoryData = searchHistory["data"];
    final List searchHistoryId = searchHistory["id"];
    String id = _getSearchId(search);
    searchHistoryData.removeAt(searchHistoryId.indexOf(id));
    searchHistoryId.removeAt(searchHistoryId.indexOf(id));
  }

  Future<Map<String, dynamic>?> getUserData({required String uid}) async {
    final userSnapshot = await usersCollection.doc(uid).get();
    if (userSnapshot.exists) {
      return userSnapshot.data() as Map<String, dynamic>?;
    }
    return null;
  }

  Future initUserData() async {
    return await usersCollection.doc(uid).set({
      "queue": [],
      "nowPlaying": {},
      "searchHistory": {
        "data": [],
        "id": [],
      },
    });
  }

  Future<bool> checkIfDocExists(String docId) async {
    try {
      var collectionRef = usersCollection;
      var doc = await collectionRef.doc(docId).get();
      return doc.exists;
    } catch (e) {
      rethrow;
    }
  }
}
