import 'package:flutter/material.dart';
import 'package:plamproject/pages/Mainmenu.dart';
import 'package:plamproject/pages/Savehead.dart';
import 'package:plamproject/pages/Savelife.dart';
import 'package:plamproject/pages/Savemaind.dart';
import 'package:plamproject/pages/Userprofile.dart';
import 'package:plamproject/pages/headresult.dart';
import 'package:plamproject/pages/history.dart';
import 'package:plamproject/pages/liferesult.dart';
import 'package:plamproject/pages/mindresult.dart';

class PalmScreenSaved extends StatefulWidget {
  @override
  _PalmScreenSavedState createState() => _PalmScreenSavedState();
}

class _PalmScreenSavedState extends State<PalmScreenSaved> {
  int selectedIndex = 1;
  List<bool> isSelected = [false, false, false]; // เพิ่มตัวแปร isSelected

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
        centerTitle: true,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/profilebackgground2.jpg"),
              colorFilter: ColorFilter.mode(
                Color.fromARGB(255, 255, 255, 255),
                BlendMode.colorBurn,
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
            color: Colors.blue[200], // สีฟ้าของพื้นหลัง
          ),
          // กล่องที่แสดงภาพฝ่ามือและเส้น
          Center(
            child: Container(
              width: 400,
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                image: const DecorationImage(
                  image: AssetImage('assets/hand.png'),
                  fit: BoxFit.cover,
                ),
              ),
              
            ),
          ),
          // ToggleButtons สำหรับเลือกเส้น
          Positioned(
  right: 20,
  top: 250,
  child: Column(
    children: [
      ToggleButtons(
        direction: Axis.vertical,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("เส้นจิตใจ"),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("เส้นสมอง"),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("เส้นชีวิต"),
          ),
        ],
        isSelected: isSelected,
        onPressed: (int index) {
          setState(() {
            for (int i = 0; i < isSelected.length; i++) {
              isSelected[i] = i == index;
            }
          });

          // Navigate to different pages based on the selected index
          switch (index) {
            case 0:
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => Savemaind(),
                ),
              );
              break;
            case 1:
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => Savehead(),
                ),
              );
              break;
            case 2:
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => Savelife(),
                ),
              );
              break;
          }
        },
        color: Colors.black,
        selectedColor: Colors.red,
        fillColor: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        selectedBorderColor: Colors.red,
      ),
    ],
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
