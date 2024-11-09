import 'package:flutter/material.dart';
 
 
 
class UserprofilePage extends StatefulWidget {
  const UserprofilePage({Key? key}) : super(key: key);
 
  @override
  State<UserprofilePage> createState() => _UserprofilePageState();
}
 
class _UserprofilePageState extends State<UserprofilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 236, 238),
      body: Stack(
        children: [
          // Dark blue area (Header)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            alignment: Alignment.topLeft,
            height: 145,
            decoration: const BoxDecoration(
                color: Color.fromARGB(255, 49, 14, 146)),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 30,
                  color: Colors.white.withOpacity(0.8),
                  onPressed: () {
                    // Add your navigation logic here
                  },
                ),
              ],
            ),
          ),
 
          // Profile Content
          Column(
            children: [
              // Profile Header
              Container(
                color: const Color.fromARGB(255, 49, 14, 146),
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[400],
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Change photo',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
 
              // Search bar and Transfer code
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'ค้นหาผู้ใช้',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          Icon(Icons.search, color: Colors.grey),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
 
                    // Transfer code
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Transfer code: ifjpdfdfosidco16dfsghsdfgsdf87gds',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, color: Colors.grey),
                            onPressed: () {
                              // Implement copy functionality here
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
 
      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Set the initial selected index
        selectedItemColor: Colors.red,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'ประวัติ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'Menu',
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
 