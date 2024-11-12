import 'package:flutter/material.dart';

class Savelife extends StatefulWidget {
  @override
  _SavelifeState createState() => _SavelifeState();
}

class _SavelifeState extends State<Savelife> {
  int selectedIndex = 0;
  List<bool> isSelected = [false, false, false]; // ตัวแปรสำหรับบันทึกสถานะของปุ่ม

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("แสดง"),
        centerTitle: true,
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
          Container(color: Colors.blue[200]),

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
            right: 90,
            top: 250,
            child: Column(
              children: [
                ToggleButtons(
                  direction: Axis.vertical, // จัดปุ่มให้อยู่ในแนวตั้ง
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text("เส้นจิตใจ"),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text("เส้นสมอง"),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
        height: 80,
        child: BottomNavigationBar(
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          currentIndex: selectedIndex,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          iconSize: 30,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'ประวัติ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: 'เมนู',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info),
              label: 'ข้อมูล',
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
