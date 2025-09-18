import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plamproject/pages/Mainmenu.dart';
import 'package:plamproject/pages/Userprofile.dart';
import 'package:plamproject/pages/PalmScreen.dart';


class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> history = [];
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final directory = await getApplicationDocumentsDirectory();
    final historyFile = File('${directory.path}/history.json');
    if (await historyFile.exists()) {
      final content = await historyFile.readAsString();
      final List<dynamic> parsed = jsonDecode(content);
      setState(() {
        history = parsed.cast<Map<String, dynamic>>().reversed.toList();
      });
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

  Widget buildHistoryCard(Map<String, dynamic> record, int index) {
    final file = File(record['image_path'] ?? '');
    final TextEditingController nameController = TextEditingController(
      text: record['name'] ?? 'Palm #${index + 1}',
    );
    final String timestamp = record['timestamp']?.split('T').join(' ') ?? 'ไม่ทราบเวลา';

    return GestureDetector(
      onTap: () async {
        if (!file.existsSync()) return;
        final imageBytes = await file.readAsBytes();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PalmScreen(
              imageBytes: imageBytes,
              lifeLinePrediction: record['life_line'] ?? '-',
              headLinePrediction: record['head_line'] ?? '-',
              heartLinePrediction: record['heart_line'] ?? '-',
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              ),
              onSubmitted: (newName) async {
                record['name'] = newName;
                final dir = await getApplicationDocumentsDirectory();
                final historyFile = File('${dir.path}/history.json');
                final content = await historyFile.readAsString();
                final List<dynamic> parsed = jsonDecode(content);
                parsed[parsed.length - 1 - index]['name'] = newName;
                await historyFile.writeAsString(jsonEncode(parsed));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ เปลี่ยนชื่อเรียบร้อยแล้ว")),
                );
                setState(() {}); // refresh UI
              },
            ),
            const SizedBox(height: 6),
            Expanded(
              child: file.existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(file, fit: BoxFit.cover),
                    )
                  : const Center(child: Text("❌ ไม่พบรูป")),
            ),
            const SizedBox(height: 6),
            Text(
              timestamp,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 48, 64, 237),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "ประวัติผลการทำนาย",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: GridView.builder(
                itemCount: history.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (context, index) {
                  return buildHistoryCard(history[index], index);
                },
              ),
            ),
          ),
        ],
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
}
