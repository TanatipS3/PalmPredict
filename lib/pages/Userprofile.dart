import 'package:flutter/material.dart';

class UserprofilePage extends StatefulWidget{
  const UserprofilePage({Key? key}) : super(key: key);


  @override
  State<UserprofilePage> createState() => _UserprofilePageState();
}

class _UserprofilePageState extends State<UserprofilePage>{

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color.fromARGB(255, 230, 236, 238),
    body: Stack(
      children: [
        // Dark blue area
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          alignment: Alignment.topLeft,
          height: 145,
          decoration: const BoxDecoration(color: Color.fromARGB(255, 49, 14, 146)),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                iconSize: 30,
                color: Colors.white.withOpacity(0.8),
                onPressed: () {},
              ),
            ],
          ),
        ),
        // Black circle positioned in the center and slightly overlapping the dark blue area
        Positioned(
          top: 50, // Adjust this value to move the circle up or down
          left: MediaQuery.of(context).size.width / 2 - 70, // Center horizontally
          child: const CircleAvatar(
            radius: 70,
            backgroundColor: Colors.black,
          ),
        ),
      ],
    ),
  );
}
}