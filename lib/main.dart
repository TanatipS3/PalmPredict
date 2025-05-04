import 'package:flutter/material.dart';
import 'package:plamproject/pages/Mainmenu.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zvnxvmdklxtpnpmcznmm.supabase.co', // 🔁 Replace with your Supabase project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp2bnh2bWRrbHh0cG5wbWN6bm1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAzOTc3NzksImV4cCI6MjA1NTk3Mzc3OX0.q0YAjTwlXUxawJpSnwwbQg16LAr3ZZcgP4mmYX0hnt8',                    // 🔁 Replace with your Supabase anon key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Palm Project',
      debugShowCheckedModeBanner: false,
      home: const MainmenuPage(),
    );
  }
}
