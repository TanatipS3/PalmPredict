import 'package:flutter/material.dart';



class PalmScreen extends StatefulWidget {
  @override
  _PalmScreenState createState() => _PalmScreenState();
}

class _PalmScreenState extends State<PalmScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("แสดง"),
        centerTitle: true, // จัดตำแหน่งข้อความให้อยู่ตรงกลาง
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          // เปลี่ยนพื้นหลังเป็นสีฟ้า
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
                image: DecorationImage(
                  image:
                      AssetImage('assets/hand.png'), // เพิ่มรูปฝ่ามือที่ต้องการ
                  fit: BoxFit.cover,
                ),
              ),
              child: CustomPaint(
                painter: PalmLinePainter(),
              ),
            ),
          ),
          // ไอคอนบันทึก
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                icon: Icon(Icons.save, size: 50, color: Colors.black),
                onPressed: () {
                  // ใส่ฟังก์ชันการบันทึกที่ต้องการ
                },
              ),
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
    final paintRed = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    final paintBlue = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;

    // เส้นสีแดง
    canvas.drawLine(Offset(size.width * 0.4, size.height * 0.2),
        Offset(size.width * 0.5, size.height * 0.3), paintRed);

    // เส้นสีน้ำเงิน
    canvas.drawLine(Offset(size.width * 0.2, size.height * 0.5),
        Offset(size.width * 0.8, size.height * 0.5), paintBlue);
    canvas.drawLine(Offset(size.width * 0.3, size.height * 0.6),
        Offset(size.width * 0.7, size.height * 0.7), paintBlue);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
