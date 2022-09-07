import 'package:bell/screens/media/media_vmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class Authentication extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;

  late String? token;

  Stream<User?> get userStream => _auth.authStateChanges();

  static Future<FirebaseApp> initializeFirebase({
    required BuildContext context,
  }) async {
    FirebaseApp firebaseApp = await Firebase.initializeApp();
    return firebaseApp;
  }

  Future<User?> signInWithGoogle({required BuildContext context}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
          // scopes: [
          //   'email',
          //   'https://www.googleapis.com/auth/youtube',
          // ],
          );
      final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();
      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        try {
          final UserCredential userCredential = await _auth.signInWithCredential(credential);
          user = userCredential.user;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'account-exists-with-different-credential') {
            showSnackbar(context: context, content: "The account already exists with a different credential.");
          } else if (e.code == 'invalid-credential') {
            showSnackbar(context: context, content: "Error occurred while accessing credentials. Try again.");
          }
        } catch (e) {
          showSnackbar(context: context, content: "Error occurred using Google Sign-In. Try again.");
        }
      }
    } on PlatformException {
      showSnackbar(context: context, content: "No internet. Try again when you're connected.");
    } catch (e) {
      showSnackbar(context: context, content: "Error. Something went wrong. Try again");
    }

    return user;
  }

  Future<void> signOut({required BuildContext context}) async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    Provider.of<MediaViewModel>(context, listen: false).updateIsLoading(true);

    try {
      if (!kIsWeb) {
        await googleSignIn.signOut();
      }
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      showSnackbar(context: context, content: "Error signing out. Try again");
    }
  }

  void showSnackbar({required BuildContext context, required String content}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.black,
      content: Text(
        content,
        style: const TextStyle(color: Colors.white, letterSpacing: 0.5),
      ),
    ));
  }
}
