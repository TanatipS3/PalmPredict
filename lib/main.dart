import 'package:flutter/material.dart';
import 'package:plamproject/pages/Mainmenu.dart';
import 'package:plamproject/pages/PalmScreen.dart';
import 'package:plamproject/pages/Userprofile.dart';
import 'package:plamproject/pages/headresult.dart';
import 'package:plamproject/pages/Liferesult.dart';
import 'package:plamproject/pages/Mindresult.dart';
import 'package:plamproject/pages/Savehead.dart';
import 'package:plamproject/pages/Savelife.dart';
import 'package:plamproject/pages/Savemaind.dart';
import 'package:plamproject/pages/history.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter project',
      home: MainmenuPage(),
    );
  }
}
