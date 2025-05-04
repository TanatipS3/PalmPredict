import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plamproject/pages/PalmScreen.dart';
import 'package:plamproject/pages/Userprofile.dart';
import 'package:plamproject/pages/history.dart';
import '../components/custom_button.dart';
import '../services/api_service.dart';
import 'package:path_provider/path_provider.dart';

class MainmenuPage extends StatefulWidget {
  const MainmenuPage({Key? key}) : super(key: key);

  @override
  State<MainmenuPage> createState() => _MainmenuPageState();
}

class _MainmenuPageState extends State<MainmenuPage> {
  int selectedIndex = 1; // default is main page
  File? _image;
  final picker = ImagePicker();

  Future<String> saveJsonToFile(Map<String, dynamic> jsonData) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${directory.path}/palm_result_$timestamp.json';
    final file = File(path);
    await file.writeAsString(jsonEncode(jsonData));
    return path;
  }

  Future<void> getImage() async {
    bool? isCamera = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Align(
          alignment: Alignment.topLeft,
          child: Text("เลือกแหล่งรูปภาพ", style: TextStyle(color: Colors.white, fontSize: 20)),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              child: const Text("ถ่ายใหม่", style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
              child: const Text("มีรูปภาพอยู่แล้ว", style: TextStyle(color: Colors.white)),
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
      setState(() => _image = File(file.path));

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final palmDetected = await ApiService.detectPalm(_image!);
      Navigator.pop(context);

      if (!palmDetected) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("ไม่พบฝ่ามือ"),
            content: const Text("ไม่สามารถตรวจพบฝ่ามือในรูปภาพ กรุณาลองใหม่"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("ตกลง")),
            ],
          ),
        );
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("ตรวจพบฝ่ามือ"),
          content: const Text("ต้องการดำเนินการทำนายต่อหรือไม่?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("ยกเลิก")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("ดำเนินการต่อ")),
          ],
        ),
      );

      if (confirm != true) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final PalmResult? result = await ApiService.processPalm(_image!);
      Navigator.pop(context);

      if (result != null) {
        final resultMap = {
          'lifeLinePrediction': result.lifeLinePrediction,
          'headLinePrediction': result.headLinePrediction,
          'heartLinePrediction': result.heartLinePrediction,
        };

        try {
          final savedPath = await saveJsonToFile(resultMap);
          print("💾 Saved: $savedPath");

          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PalmScreen(
                imageToken: result.imageToken,
                lifeLinePrediction: result.lifeLinePrediction,
                headLinePrediction: result.headLinePrediction,
                heartLinePrediction: result.heartLinePrediction,
              ),
            ),
          );
        } catch (e) {
          print("❌ Error saving JSON: $e");

          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PalmScreen(
                imageToken: result.imageToken,
                lifeLinePrediction: result.lifeLinePrediction,
                headLinePrediction: result.headLinePrediction,
                heartLinePrediction: result.heartLinePrediction,
              ),
            ),
          );
        }
      }
    }
  }

  void onNavTap(int index) {
    if (index == selectedIndex) return;

    setState(() => selectedIndex = index);
    Widget page = const MainmenuPage(); // fallback

    if (index == 0) page = const HistoryPage();
    if (index == 1) page = const MainmenuPage();
    if (index == 2) page = const UserprofilePage();

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
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
                CustomButton(
                  icon: Icons.image_search,
                  text: "ถ่ายรูป หรืออัปโหลดรูป",
                  onPressed: getImage,
                ),
                const SizedBox(height: 30),
                CustomButton(
                  icon: Icons.history,
                  text: "ประวัติผลการทำนาย",
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryPage()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onNavTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'ประวัติ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'หน้าหลัก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'ข้อมูล',
          ),
        ],
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
