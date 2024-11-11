import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class MainmenuPage extends StatefulWidget {
  const MainmenuPage({Key? key}) : super(key: key);

  @override
  State<MainmenuPage> createState() => _MainmenuPageState();

}

int selectedIndex = 0;

class _MainmenuPageState extends State<MainmenuPage> {

  File? _image;
  final picker = ImagePicker();
  Future getImage() async {
  bool? isCamera = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.8), // Match theme color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Rounded corners
      title: const Align(
        alignment: Alignment.topLeft,
        child: Text(
          "เลือกแหล่งรูปภาพ", 
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey, // Adjust button color
            ),
            child: const Text(
              "ถ่ายใหม่",
              style: TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 20), // Space between buttons
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey, // Adjust button color
            ),
            child: const Text(
              "มีรูปภาพอยู่แล้ว",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );

  if (isCamera == null) return;

  XFile? file = await picker.pickImage(
    source: isCamera ? ImageSource.camera : ImageSource.gallery,
  );

  setState(() {
    if (file != null) {
      _image = File(file.path);
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image
          const Positioned.fill(
            child: Image(
              image: AssetImage("assets/profilebackgground2.jpg"),
              color: Color.fromARGB(255, 44, 128, 196),
              colorBlendMode: BlendMode.colorBurn,
              fit: BoxFit.cover,
            ),
          ),
          // Centered button with icon and text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 ElevatedButton(
              onPressed: () {
                    getImage(); // Call getImage each time the button is clicked
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                
                ),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
              side: const BorderSide(color: Color.fromARGB(255, 226, 213, 213), width: 2),
                
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min, // Keeps row compact around content
                children: [
                  Icon(Icons.image_search, size: 45, color: Colors.white), // Icon

                  SizedBox(width: 40), // Space between icon and text
                  Text(
                    "ถ่ายรูป หรืออัปโหลดรูป",
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30,),
            ElevatedButton(
              onPressed: () {
                // Add button action here
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                
                ),
              backgroundColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
              side: const BorderSide(color: Color.fromARGB(255, 226, 213, 213), width: 2),
                
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min, // Keeps row compact around content
                children: [
                  Icon(Icons.history, size: 45, color: Colors.white), // Icon

                  SizedBox(width: 40), // Space between icon and text
                  Text(
                    "ประวัติผลการทำนาย",
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
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
    );
  }
}