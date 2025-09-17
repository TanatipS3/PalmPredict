import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plamproject/pages/Mainmenu.dart';
import 'package:plamproject/pages/history.dart';
import '../services/api_service.dart';

class UserprofilePage extends StatefulWidget {
  const UserprofilePage({Key? key}) : super(key: key);

  @override
  State<UserprofilePage> createState() => _UserprofilePageState();
}

class _UserprofilePageState extends State<UserprofilePage> {
  int selectedIndex = 2;
  File? profileImage;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController searchCodeController = TextEditingController();
  String transferCode = '';
  bool codeGenerated = false;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('username');
    final savedCode = prefs.getString('transferCode');
    final savedPath = prefs.getString('profileImage');

    if (savedName != null) nameController.text = savedName;
    if (savedCode != null) transferCode = savedCode;
    if (savedPath != null && File(savedPath).existsSync()) {
      profileImage = File(savedPath);
    }

    if (mounted) {
      setState(() {
        codeGenerated = transferCode.isNotEmpty;
      });
    }
  }

  Future<void> saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', nameController.text);
    await prefs.setString('transferCode', transferCode);
    if (profileImage != null) {
      await prefs.setString('profileImage', profileImage!.path);
    }
  }

   Future<void> overwriteHistory(List<dynamic> history) async {
    final directory = await getApplicationDocumentsDirectory();
    final historyFile = File('${directory.path}/history.json');
    await historyFile.writeAsString(jsonEncode(history));
  }

  Future<void> searchAccountByPasscode() async {
  final code = searchCodeController.text.trim();
  if (code.isEmpty) return;

  final response = await supabase
      .from('user_profiles')
      .select()
      .eq('transfer_code', code)
      .maybeSingle();

  if (response == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("ไม่พบรหัสนี้ในระบบ")),
    );
    return;
  }

  final imageUrl = response['image_url'] as String?;
  final userName = response['user_name'] as String? ?? '';

  File? downloadedFile;

  if (imageUrl != null && imageUrl.isNotEmpty) {
  final response = await HttpClient().getUrl(Uri.parse(imageUrl)).timeout(Duration(seconds: 30), onTimeout: () {
                            throw Exception("Server timeout");});
  final bytes = await (await response.close()).fold<BytesBuilder>(
    BytesBuilder(),
    (builder, data) => builder..add(data),
  );

  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/profile_from_db.jpg';
  downloadedFile = File(filePath);
  await downloadedFile.writeAsBytes(bytes.takeBytes());
  }
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("ยืนยันการเปลี่ยนบัญชี"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null)
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(imageUrl),
            ),
          const SizedBox(height: 10),
          Text("ชื่อผู้ใช้: $userName"),
          const SizedBox(height: 10),
          const Text("คุณต้องการใช้บัญชีนี้กับอุปกรณ์นี้หรือไม่?"),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ยกเลิก")),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('username', userName);
            await prefs.setString('transferCode', code);
            if (downloadedFile != null) {
              await prefs.setString('profileImage', downloadedFile.path);
            }
            setState(() {
              nameController.text = userName;
              transferCode = code;
              codeGenerated = true;
              profileImage = downloadedFile;
              });
            await saveUserData(); 
            // Fetch prediction history
            final history = await supabase
                .from('prediction_history')
                .select()
                .eq('user_code', code);

            final List<Map<String, dynamic>> updatedHistory = [];
            final dir = await getApplicationDocumentsDirectory();

            for (final item in history) {
              final imgUrl = item['image_url'];
              final createdAt = item['created_at'];

              String? localPath;

              if (imgUrl != null && imgUrl is String) {
                try {
                  final response = await HttpClient().getUrl(Uri.parse(imgUrl)).timeout(Duration(seconds: 30), onTimeout: () {
                            throw Exception("Server timeout");});
                  final bytes = await response.close().then((res) => res.fold<List<int>>([], (b, d) => b..addAll(d)));
                  final filename = 'downloaded_${DateTime.now().millisecondsSinceEpoch}.jpg';
                  final file = File('${dir.path}/$filename');
                  await file.writeAsBytes(bytes);
                  localPath = file.path;
                } catch (e) {
                  print('❌ Download failed: $e');
                }
              }

              updatedHistory.add({
                'life_line': item['life_line'] ?? '',
                'head_line': item['head_line'] ?? '',
                'heart_line': item['heart_line'] ?? '',
                'image_path': localPath ?? '',
                'timestamp': createdAt ?? DateTime.now().toIso8601String(),
              });
            }

            final historyFile = File('${dir.path}/history.json');
            await historyFile.writeAsString(jsonEncode(updatedHistory));

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ เชื่อมบัญชีเรียบร้อยแล้ว")),
            );

            setState(() {});
          },
          child: const Text("ยืนยัน"),
        ),
      ],
    ),
  );
}

  
  void pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        profileImage = File(picked.path);
      });
      await saveUserData();
    }
  }

  String generateSecureCode({int length = 20}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$-_';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> backupHistoryToSupabase(String code) async {
    final directory = await getApplicationDocumentsDirectory();
    final historyFile = File('${directory.path}/history.json');
    if (!historyFile.existsSync()) return;

    final content = await historyFile.readAsString();
    final List<dynamic> history = jsonDecode(content);

    for (final item in history) {
      final imagePath = item['image_path'];
      if (!File(imagePath).existsSync()) continue;
      final imageBytes = await File(imagePath).readAsBytes();
      final fileName = 'history_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('user-history')
          .uploadBinary(fileName, imageBytes, fileOptions: const FileOptions(upsert: true));

      final imageUrl = Supabase.instance.client.storage
          .from('user-history')
          .getPublicUrl(fileName);

      await supabase.from('prediction_history').upsert({
        'user_code': code,
        'life_line': item['life_line'],
        'head_line': item['head_line'],
        'heart_line': item['heart_line'],
        'image_url': imageUrl,
        'created_at': item['timestamp'] ?? DateTime.now().toIso8601String()
      }, onConflict: 'created_at');
    }
  }

  Future<void> generateTransferCode() async {
    final newCode = generateSecureCode();
    final now = DateTime.now().toIso8601String();
    final bytes = await profileImage?.readAsBytes();
    String? imageUrl;
    if (profileImage != null) {
      final imageBytes = await profileImage!.readAsBytes();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final response = await Supabase.instance.client.storage
          .from('user-profiles')
          .uploadBinary(fileName, imageBytes, fileOptions: const FileOptions(upsert: true));
      imageUrl = Supabase.instance.client.storage
          .from('user-profiles')
          .getPublicUrl(fileName);
    }

    await supabase.from('user_profiles').upsert({
      'transfer_code': newCode,
      'user_name': nameController.text,
      'image_url': imageUrl,
      'last_updated': now
    });

    setState(() {
      transferCode = newCode;
      codeGenerated = true;
    });

    await saveUserData();
    await backupHistoryToSupabase(newCode);
    Clipboard.setData(ClipboardData(text: transferCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ คัดลอกรหัสเรียบร้อย")),
    );
  }

  Future<void> syncProfileAndHistory() async {
    if (transferCode.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    final bytes = await profileImage?.readAsBytes();
    String? imageUrl;
    if (profileImage != null) {
      final imageBytes = await profileImage!.readAsBytes();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from('user-profiles')
          .uploadBinary(fileName, imageBytes, fileOptions: const FileOptions(upsert: true));
      imageUrl = Supabase.instance.client.storage
          .from('user-profiles')
          .getPublicUrl(fileName);
    }

    await supabase.from('user_profiles').upsert({
      'transfer_code': transferCode,
      'user_name': nameController.text,
      'image_url': imageUrl,
      'last_updated': now
    },onConflict: 'transfer_code');

    await backupHistoryToSupabase(transferCode);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🔄 ข้อมูลถูกอัปเดตแล้ว")),
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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 48, 64, 237),
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          "โปรไฟล์ผู้ใช้",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Container(
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
                      backgroundColor: Colors.grey.shade300,
                      child: profileImage == null
                          ? const Icon(Icons.person, size: 60, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    onChanged: (_) => saveUserData(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: const InputDecoration(
                      hintText: "ชื่อของคุณ",
                      hintStyle: TextStyle(color: Colors.white),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (!codeGenerated)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      child: ElevatedButton(
                        onPressed: generateTransferCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Generate Transfer Code", style: TextStyle(fontSize: 16)),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: transferCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("📋 คัดลอกรหัสและกำลังซิงค์...")),
                              );
                              await syncProfileAndHistory();
                            },
                            icon: const Icon(Icons.sync),
                            label: Text(transferCode),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchCodeController,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: "ค้นหาผู้ใช้",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: searchAccountByPasscode,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.info_outline, color: Colors.white, size: 30),
                        SizedBox(height: 10),
                        Text(
                          "ข้อมูลเพิ่มเติม",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "คุณสามารถแก้ไขโปรไฟล์และใช้รหัสเพื่อโอนย้ายข้อมูลได้",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
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
}
