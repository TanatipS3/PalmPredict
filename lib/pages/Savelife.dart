import 'package:flutter/material.dart';
import 'package:plamproject/pages/Mainmenu.dart';
import 'package:plamproject/pages/Savehead.dart';
import 'package:plamproject/pages/Savemaind.dart';
import 'package:plamproject/pages/Userprofile.dart';
import 'package:plamproject/pages/headresult.dart';
import 'package:plamproject/pages/history.dart';
import 'package:plamproject/pages/liferesult.dart';
import 'package:plamproject/pages/mindresult.dart';

class Savelife extends StatefulWidget {
  @override
  _SavelifeState createState() => _SavelifeState();
}

class _SavelifeState extends State<Savelife> {
  int selectedIndex = 1;
  List<bool> isSelected = [false, false, false]; // ตัวแปรสำหรับบันทึกสถานะของปุ่ม

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

        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 30,
          color: Colors.white.withOpacity(0.8),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [

          //from here
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/profilebackgground2.jpg"),
                colorFilter: ColorFilter.mode(
                  Color.fromARGB(255, 44, 128, 196),
                  BlendMode.colorBurn,
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Center(
            child: Container(
              width: 400,
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                image: DecorationImage(
                  image: AssetImage('assets/hand1.PNG'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    painter: PalmLinePainter(),
                    child: Container(),
                  ),
                  Positioned(
                    top: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        'เส้นชีวิต\nนิทานชีวิตจะเกี่ยวข้องกับร่างกายและอารมณ์รวมทั้งจิตใจ '
                        'อาจเป็นคนที่มีแต่คำถามได้ควรให้ความอ่อนข้อให้ผู้อื่น '
                        'ชะตาชีวิตประสบความล้มเหลวได้ง่าย',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
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

// CustomPainter สำหรับวาดเส้นบนฝ่ามือ
class PalmLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // ลบหรือคอมเมนต์โค้ดการวาดเส้นสีทั้งหมดออก
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
