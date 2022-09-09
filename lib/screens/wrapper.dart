import 'package:bell/screens/authenticate/authenticate.dart';
import 'package:bell/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bell/main.dart';
import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);
    context.watch<Authentication>().checkIfHeadersPresent();

    if (currentUser != null) {
      return const Main();
    } else {
      return const Authenticate();
    }
  }
}
