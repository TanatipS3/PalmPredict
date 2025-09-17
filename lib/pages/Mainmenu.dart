import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:plamproject/pages/PalmScreen.dart';
import 'package:plamproject/pages/Userprofile.dart';
import 'package:plamproject/pages/history.dart';
import '../components/custom_button.dart';
import '../services/api_service.dart'; // must expose PalmResult + processPalm(File)

class MainmenuPage extends StatefulWidget {
  const MainmenuPage({Key? key}) : super(key: key);

  @override
  State<MainmenuPage> createState() => _MainmenuPageState();
}

class _MainmenuPageState extends State<MainmenuPage> {
  int selectedIndex = 1; // default is main page
  File? _image;
  final picker = ImagePicker();

  /// ---------- Small helpers ----------
  void showLoader(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void hideLoader(BuildContext context) {
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) nav.pop();
  }

  Future<String> saveJsonToFile(Map<String, dynamic> jsonData) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${directory.path}/palm_result_$timestamp.json';
    final file = File(path);
    await file.writeAsString(jsonEncode(jsonData));
    return path;
  }

  /// ---------- Main flow ----------
  Future<void> getImage() async {
    // 1) Choose source
    final bool? isCamera = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Align(
          alignment: Alignment.topLeft,
          child: Text("เลือกแหล่งรูปภาพ",
              style: TextStyle(color: Colors.white, fontSize: 20)),
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
              child:
                  const Text("มีรูปภาพอยู่แล้ว", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (isCamera == null) return;

    // 2) Pick image
    final XFile? picked = await picker.pickImage(
      source: isCamera ? ImageSource.camera : ImageSource.gallery,
    );
    if (picked == null) return;

    _image = File(picked.path); // keep local reference (optional preview/use)

    // 3) Show loader ONCE
    showLoader(context);

    PalmResult result;
    try {
      // 4) Call backend ONCE
      result = await ApiService.processPalm(_image!);

      // 5) Optional basic “detected?” check
      final palmDetected = result.lifeLinePrediction.isNotEmpty ||
          result.headLinePrediction.isNotEmpty ||
          result.heartLinePrediction.isNotEmpty;

      if (!palmDetected) {
        if (mounted) hideLoader(context);
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("ไม่พบฝ่ามือ"),
            content: const Text("ไม่สามารถตรวจพบฝ่ามือในรูปภาพ กรุณาลองใหม่"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("ตกลง")),
            ],
          ),
        );
        return;
      }

      // 6) Save JSON (optional)
      final resultMap = {
        'lifeLinePrediction': result.lifeLinePrediction,
        'headLinePrediction': result.headLinePrediction,
        'heartLinePrediction': result.heartLinePrediction,
      };
      try {
        final savedPath = await saveJsonToFile(resultMap);
        // ignore: avoid_print
        print("💾 Saved: $savedPath");
      } catch (e) {
        // ignore: avoid_print
        print("❌ Error saving JSON: $e");
      }
    } catch (e) {
      // Any error from API
      if (mounted) hideLoader(context);
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("เกิดข้อผิดพลาด"),
          content: Text(e.toString()),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ตกลง")),
          ],
        ),
      );
      return;
    } finally {
      // 7) Always close loader
      if (mounted) hideLoader(context);
    }

    // 8) Navigate after loader is closed
    if (!mounted || result == null) return;
    final bytes = await ApiService.fetchMaskImage(result.imageToken) ?? await _image!.readAsBytes();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PalmScreen(
          imageBytes: bytes,
          imageToken: result.imageToken,
          lifeLinePrediction: result.lifeLinePrediction,
          headLinePrediction: result.headLinePrediction,
          heartLinePrediction: result.heartLinePrediction,
        ),
      ),
    );
  }

  /// ---------- Bottom nav ----------
  void onNavTap(int index) {
    if (index == selectedIndex) return;

    setState(() => selectedIndex = index);
    Widget page = const MainmenuPage(); // fallback

    if (index == 0) page = const HistoryPage();
    if (index == 1) page = const MainmenuPage();
    if (index == 2) page = const UserprofilePage();

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  /// ---------- UI ----------
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
                    MaterialPageRoute(
                        builder: (context) => const HistoryPage()),
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
