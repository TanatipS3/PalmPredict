import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plamproject/pages/Mainmenu.dart';
import 'package:plamproject/pages/Userprofile.dart';
import 'package:plamproject/pages/history.dart';
import '../services/api_service.dart';

class PalmScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final String? imageToken;
  final String lifeLinePrediction;
  final String headLinePrediction;
  final String heartLinePrediction;

  const PalmScreen({
    Key? key,
    this.imageBytes,
    this.imageToken,
    required this.lifeLinePrediction,
    required this.headLinePrediction,
    required this.heartLinePrediction,
  }) : super(key: key);

  @override
  State<PalmScreen> createState() => _PalmScreenState();
}

class _PalmScreenState extends State<PalmScreen> {
  Uint8List? imageBytes;
  int selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    if (widget.imageBytes != null) {
      imageBytes = widget.imageBytes;
    } else if (widget.imageToken != null && widget.imageToken!.isNotEmpty) {
      loadImage();
    }
  }

  Future<void> loadImage() async {
    final bytes = await ApiService.fetchMaskImage(widget.imageToken!);
    if (mounted) {
      setState(() => imageBytes = bytes);
    }
  }

  void saveToLocalHistory() async {
    if (imageBytes == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'palm_history_$timestamp.jpg';
    final filepath = '${directory.path}/$filename';

    final imageFile = File(filepath);
    await imageFile.writeAsBytes(imageBytes!);

    final newRecord = {
      'timestamp': DateTime.now().toIso8601String(),
      'image_path': filepath,
      'life_line': widget.lifeLinePrediction,
      'head_line': widget.headLinePrediction,
      'heart_line': widget.heartLinePrediction,
    };

    final historyFile = File('${directory.path}/history.json');
    List<dynamic> history = [];
    if (await historyFile.exists()) {
      final content = await historyFile.readAsString();
      history = jsonDecode(content);

      final duplicate = history.any((item) =>
        item['life_line'] == newRecord['life_line'] &&
        item['head_line'] == newRecord['head_line'] &&
        item['heart_line'] == newRecord['heart_line']
      );

      if (duplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ ผลลัพธ์นี้ถูกบันทึกไว้แล้ว")),
        );
        return;
      }
    }

    history.add(newRecord);
    await historyFile.writeAsString(jsonEncode(history));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ บันทึกผลการทำนายเรียบร้อยแล้ว")),
    );
  }

  void onNavTap(int index) {
    if (index == selectedIndex) return;
    setState(() => selectedIndex = index);
    Widget page = const MainmenuPage();
    if (index == 0) page = const HistoryPage();
    if (index == 1) page = const MainmenuPage();
    if (index == 2) page = const UserprofilePage();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/profilebackgground2.jpg"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color.fromARGB(255, 44, 128, 196),
              BlendMode.colorBurn,
            ),
          ),
        ),
        child: SafeArea(
          child: imageBytes == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  const Center(
                                    child: Text(
                                      "ภาพแสดงเส้นฝ่ามือ",
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      imageBytes!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      buildLegend(color: Colors.green, label: "เส้นชีวิต"),
                                      const SizedBox(width: 20),
                                      buildLegend(color: Colors.blue, label: "เส้นสมอง"),
                                      const SizedBox(width: 20),
                                      buildLegend(color: Colors.red, label: "เส้นหัวใจ"),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "ผลการทำนาย",
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  predictionText("🧬", "เส้นชีวิต", widget.lifeLinePrediction),
                                  const SizedBox(height: 12),
                                  predictionText("🧠", "เส้นสมอง", widget.headLinePrediction),
                                  const SizedBox(height: 12),
                                  predictionText("❤️", "เส้นหัวใจ", widget.heartLinePrediction),
                                  const SizedBox(height: 30),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: saveToLocalHistory,
                                        icon: const Icon(Icons.save_alt),
                                        label: const Text("บันทึกลงแอป"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'ประวัติ'),
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'หน้าหลัก'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'ข้อมูล'),
        ],
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  static Widget buildLegend({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  static Widget predictionText(String emoji, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$emoji ", style: const TextStyle(fontSize: 20)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 16, color: Colors.black),
              children: [
                TextSpan(
                  text: "$title: ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: content),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
