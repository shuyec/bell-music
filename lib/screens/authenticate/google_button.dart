import 'package:bell/screens/media/media_vmodel.dart';
import 'package:bell/services/auth.dart';
import 'package:bell/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({Key? key}) : super(key: key);

  @override
  GoogleSignInButtonState createState() => GoogleSignInButtonState();
}

class GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _isSigningIn
          ? const SpinKitChasingDots(
              color: Colors.white,
              size: 40.0,
            )
          : OutlinedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.white),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              onPressed: () async {
                final mediaVMProvider = Provider.of<MediaViewModel>(context, listen: false);
                final navigator = Navigator.of(context);
                setState(() {
                  _isSigningIn = true;
                });

                User? user = await Provider.of<Authentication>(context, listen: false).signInWithGoogle(context: context);

                if (user != null) {
                  final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  bool docExists = await Database(user.uid).checkIfDocExists(userSnapshot.reference.id);
                  if (!docExists) {
                    await Database(user.uid).initUserData();
                  }
                  navigator.popUntil((route) => route.isFirst);
                  navigator.popAndPushNamed("/");
                  mediaVMProvider.init();

                  // navigator.pushAndRemoveUntil(
                  //   MaterialPageRoute(
                  //     builder: (_) => const Bell(),
                  //   ),
                  //   (_) => false,
                  // );
                } else {
                  setState(() {
                    _isSigningIn = false;
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Image(
                      image: AssetImage("assets/google_logo.png"),
                      height: 35.0,
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
