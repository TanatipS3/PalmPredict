import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plamproject/pages/PalmScreen.dart';
import 'package:plamproject/pages/Userprofile.dart';
import 'package:plamproject/pages/history.dart';


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
        backgroundColor: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                backgroundColor: Colors.blueGrey,
              ),
              child: const Text(
                "ถ่ายใหม่",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
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

    if (file != null) {
      setState(() {
        _image = File(file.path);
      });
      // Navigate to PalmScreen after selecting the image
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => PalmScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(
            child: Image(
              image: AssetImage("assets/profilebackgground2.jpg"),
              color: Color.fromARGB(255, 44, 128, 196),
              colorBlendMode: BlendMode.colorBurn,
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    getImage();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 35, vertical: 25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor:
                        const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
                    side: const BorderSide(
                        color: Color.fromARGB(255, 226, 213, 213), width: 2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image_search, size: 45, color: Colors.white),
                      SizedBox(width: 40),
                      Text(
                        "ถ่ายรูป หรืออัปโหลดรูป",
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (BuildContext context) => HistoryPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 45, vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    backgroundColor:
                        const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
                    side: const BorderSide(
                        color: Color.fromARGB(255, 226, 213, 213), width: 2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 45, color: Colors.white),
                      SizedBox(width: 40),
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
        selectedIndex = 0;
      });
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => HistoryPage()));
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.history,
          color: selectedIndex == 0 ? Colors.red : Colors.grey,
          size: 30,
        ),
        const SizedBox(height: 4), // Spacing between icon and text
        Text(
          'ประวัติ', 
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
        selectedIndex = 1;
      });
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => const MainmenuPage()));
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.menu,
          color: selectedIndex == 1 ? Colors.red : Colors.grey,
          size: 30,
        ),
        const SizedBox(height: 4), // Spacing between icon and text
        Text(
          'หน้าหลัก', // Text label for "Menu"
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
