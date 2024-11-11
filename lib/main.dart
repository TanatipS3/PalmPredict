import 'package:flutter/material.dart';
import 'package:plamproject/pages/Mainmenu.dart';
import 'package:plamproject/pages/PalmScreen.dart';
import 'package:plamproject/pages/Userprofile.dart';
import 'package:plamproject/pages/headresult.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter project',
      home: UserprofilePage(),
    );
  }
}
