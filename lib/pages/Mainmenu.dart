import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainmenuPage extends StatefulWidget {
  const MainmenuPage({Key? key}) : super(key: key);

  @override
  State<MainmenuPage> createState() => _MainmenuPageState();
}

int selectedIndex = 0;

class _MainmenuPageState extends State<MainmenuPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      body: const Stack(
        children: [
          Padding(padding: EdgeInsets.all(10),
          child: Column(),)
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
            //currentIndex: _selectedIndex,
            //onTap: _onItemTapped,
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
        ));
}
}