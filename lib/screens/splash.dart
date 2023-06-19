import 'dart:async';

import 'package:flutter/material.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/home');
    });

    return const Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        body: Center(
          child: Image(
            image: AssetImage('assets/icons/icon.png'),
            width: 150, // Ajusta el ancho según tus necesidades
          ),
        ));
  }
}
