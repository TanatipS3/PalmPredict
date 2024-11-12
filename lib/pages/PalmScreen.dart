import 'package:flutter/material.dart';
import 'package:plamproject/pages/Mainmenu.dart';
import 'package:plamproject/pages/Userprofile.dart';
import 'package:plamproject/pages/history.dart';

class PalmScreen extends StatefulWidget {
  @override
  _PalmScreenState createState() => _PalmScreenState();
}

class _PalmScreenState extends State<PalmScreen> {
 int selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "แสดง",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true, // Center-align the title
        backgroundColor:
            Colors.transparent, // Make AppBar background transparent
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/profilebackgground2.jpg"),
              colorFilter: ColorFilter.mode(
                Color.fromARGB(255, 255, 255, 255), // Overlay color
                BlendMode.colorBurn, // Blend mode
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Full-screen background with image, color overlay, and blend mode
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/profilebackgground2.jpg"),
                colorFilter: ColorFilter.mode(
                  Color.fromARGB(255, 44, 128, 196), // Overlay color
                  BlendMode.colorBurn, // Blend mode
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Center container displaying hand image and lines
          Center(
            child: Container(
              width: 400,
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/hand.png'), // Hand image
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Save icon at the bottom center
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.save, size: 50, color: Colors.white),
                onPressed: () {
                  // Save functionality
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
Expanded(
  child: GestureDetector(
    onTap: () {
      setState(() {
        selectedIndex = 1;
      });
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => HistoryPage()));
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.history,
          color: selectedIndex == 1 ? Colors.red : Colors.grey,
          size: 30,
        ),
        const SizedBox(height: 4), // Spacing between icon and text
        Text(
          'ประวัติ', 
          style: TextStyle(
            color: selectedIndex == 1 ? Colors.red : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    ),
  ),
),

Expanded(
  child: GestureDetector(
    onTap: () {
      setState(() {
        selectedIndex = 0;
      });
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => const MainmenuPage()));
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.menu,
          color: selectedIndex == 0 ? Colors.red : Colors.grey,
          size: 30,
        ),
        const SizedBox(height: 4), // Spacing between icon and text
        Text(
          'หน้าหลัก', // Text label for "Menu"
          style: TextStyle(
            color: selectedIndex == 0 ? Colors.red : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    ),
  ),
),

            Expanded(
              child: GestureDetector(
                 onTap: () {
                  setState(() {
                 selectedIndex = 2;
                 });
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => const UserprofilePage()));
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.info,
          color: selectedIndex == 2 ? Colors.red : Colors.grey,
          size: 30,
        ),
        const SizedBox(height: 4), // Spacing between icon and text
        Text(
          'ข้อมูล', // Text label
          style: TextStyle(
            color: selectedIndex == 2 ? Colors.red : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    ),
  ),
        ),

          ],
        ),
      ),
    );
  }
}

