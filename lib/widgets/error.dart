import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class Error extends StatelessWidget {
  const Error({Key? key, required this.error}) : super(key: key);
  final String error;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Iconsax.danger,
            color: Colors.red,
            size: 60,
          ),
          Text(error),
        ],
      ),
    );
  }
}
