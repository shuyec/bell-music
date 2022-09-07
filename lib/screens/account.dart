import 'package:bell/screen_navigator.dart';
import 'package:bell/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'media/media_vmodel.dart';

class Account extends StatefulWidget {
  const Account({Key? key}) : super(key: key);

  @override
  AccountState createState() => AccountState();
}

class AccountState extends State<Account> {
  late User _user;
  bool _isSigningOut = false;

  @override
  void initState() {
    _user = FirebaseAuth.instance.currentUser!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaVMProvider = Provider.of<MediaViewModel>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        // actions: <Widget>[
        //   IconButton(
        //     icon: const Icon(
        //       Icons.notifications,
        //     ),
        //     onPressed: () {},
        //   )
        // ],
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: 20.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(),
              _user.photoURL != null
                  ? ClipOval(
                      child: Material(
                        color: Colors.grey,
                        child: Image.network(
                          _user.photoURL!,
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                    )
                  : const ClipOval(
                      child: Material(
                        color: Colors.grey,
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 16.0),
              Text(
                _user.displayName!,
                style: const TextStyle(
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: 24.0),
              _isSigningOut
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          Colors.redAccent,
                        ),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      onPressed: () async {
                        final ScreenNavigator screenNavigator = ScreenNavigator();
                        setState(() {
                          _isSigningOut = true;
                        });

                        await Authentication().signOut(context: context);
                        mediaVMProvider.myDispose();

                        // setState(() {
                        //   _isSigningOut = false;
                        // });
                        screenNavigator.goToLogin(context: context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
