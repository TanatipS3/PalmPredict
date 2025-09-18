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
  final Uint8List? imageBytes;        // pass this from Mainmenu if you have it
  final String? imageToken;           // may be empty in demo backend
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

    // If bytes were passed in, use them immediately.
    if (widget.imageBytes != null) {
      imageBytes = widget.imageBytes;
      return;
    }

    // If we have a non-empty token AND fetchMaskImage is implemented,
    // try to load the image asynchronously. Otherwise just show predictions.
    if ((widget.imageToken ?? '').isNotEmpty) {
      loadImageFromToken(widget.imageToken!);
    }
  }

  Future<void> loadImageFromToken(String token) async {
  try {
    // 1) Try fetch from API
    final bytes = await ApiService.fetchMaskImage(token);
    if (bytes != null && mounted) {
      setState(() => imageBytes = bytes);
      return;
    }

    // 2) Fallback to local file
    final dir = await getApplicationDocumentsDirectory();
    final fallbackPath = '${dir.path}/masked_$token.jpg';
    final file = File(fallbackPath);

    if (await file.exists()) {
      final localBytes = await file.readAsBytes();  // <-- await outside setState
      if (mounted) {
        setState(() => imageBytes = localBytes);    // <-- no await inside setState
      }
    } else {
      debugPrint('❌ Local fallback file not found: $fallbackPath');
    }
  } catch (e) {
    // Show predictions even if no image; just log the error
    debugPrint('loadImageFromToken error: $e');
  }
}


  Future<void> saveToLocalHistory() async {
    // Save image only if we have it; predictions are always available
    String? savedImagePath;
    if (imageBytes != null) {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filepath = '${directory.path}/palm_history_$timestamp.jpg';
      await File(filepath).writeAsBytes(imageBytes!);
      savedImagePath = filepath;
    }

    final directory = await getApplicationDocumentsDirectory();
    final historyFile = File('${directory.path}/history.json');

    final newRecord = {
      'timestamp': DateTime.now().toIso8601String(),
      'image_path': savedImagePath, // may be null if no image
      'life_line': widget.lifeLinePrediction,
      'head_line': widget.headLinePrediction,
      'heart_line': widget.heartLinePrediction,
    };

    List<dynamic> history = [];
    if (await historyFile.exists()) {
      final content = await historyFile.readAsString();
      history = jsonDecode(content);
      final duplicate = history.any((item) =>
          item['life_line'] == newRecord['life_line'] &&
          item['head_line'] == newRecord['head_line'] &&
          item['heart_line'] == newRecord['heart_line']);
      if (duplicate && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ ผลลัพธ์นี้ถูกบันทึกไว้แล้ว")),
        );
        return;
      }
    }

    history.add(newRecord);
    await historyFile.writeAsString(jsonEncode(history));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ บันทึกผลการทำนายเรียบร้อยแล้ว")),
      );
    }
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
    final hasImage = imageBytes != null;

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
          child: Column(
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
                            if (hasImage) ...[
                              const SizedBox(height: 10),
                              const Center(
                                child: Text(
                                  "ภาพแสดงเส้นฝ่ามือ",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
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
                                  buildLegend(
                                      color: Colors.green, label: "เส้นชีวิต"),
                                  const SizedBox(width: 20),
                                  buildLegend(
                                      color: Colors.blue, label: "เส้นสมอง"),
                                  const SizedBox(width: 20),
                                  buildLegend(
                                      color: Colors.red, label: "เส้นหัวใจ"),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],
                            const Text(
                              "ผลการทำนาย",
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            predictionText(
                                "🧬", "เส้นชีวิต", widget.lifeLinePrediction),
                            const SizedBox(height: 12),
                            predictionText(
                                "🧠", "เส้นสมอง", widget.headLinePrediction),
                            const SizedBox(height: 12),
                            predictionText(
                                "❤️", "เส้นหัวใจ", widget.heartLinePrediction),
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
