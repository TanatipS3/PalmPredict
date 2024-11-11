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
  title: const Text(
    "แสดง",
    style: TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  centerTitle: true, // Center-align the title
  backgroundColor: Colors.transparent, // Make AppBar background transparent
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
              child: CustomPaint(
                painter: PalmLinePainter(),
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
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.3),
      paintRed,
    );

    // เส้นสีน้ำเงิน
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.5),
      Offset(size.width * 0.8, size.height * 0.5),
      paintBlue,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.6),
      Offset(size.width * 0.7, size.height * 0.7),
      paintBlue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
