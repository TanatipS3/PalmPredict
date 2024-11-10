import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UserprofilePage extends StatefulWidget {
  const UserprofilePage({Key? key}) : super(key: key);

  @override
  State<UserprofilePage> createState() => _UserprofilePageState();
}

int selectedIndex = 0;

class _UserprofilePageState extends State<UserprofilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 230, 236, 238),
        body: Stack(
          children: [
            // Dark blue area (Header)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              alignment: Alignment.topLeft,
              height: 145,
              decoration:
                  const BoxDecoration(color: Color.fromARGB(255, 49, 14, 146)),
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
                  //color: const Color.fromARGB(255, 49, 14, 146),
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[400],
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Change photo',
                        style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
                      ),
                    ],
                  ),
                ),

                // Search bar and Transfer code
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      // Search bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'ค้นหาผู้ใช้',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                                onPressed: () {
                                  showAlertDialog(context);
                                },
                                icon: const Icon(Icons.search))
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Transfer code
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Transfer code: ifjpdfdfosidco16dfsghsdfgsdf87gds',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.grey),
                              onPressed: () {
                                Clipboard.setData(const ClipboardData(
                                    text: "ifjpdfdfosidco16dfsghsdfgsdf87gds"));
                                ScaffoldMessenger.of(context).showSnackBar(
                                    (const SnackBar(
                                        content: Text(
                                            "Code has been copied to clipboard!"))));
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
        // Bottom Navigation Bar with larger icons and increased height
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

showAlertDialog(BuildContext context) {
  // set up the buttons

  Widget confirmButton = IconButton(
    onPressed: () {},
    icon: const Icon(Icons.check_circle),
    color: Colors.lightGreen,
    iconSize: 50,
  );
  Widget cancelButton = IconButton(
    onPressed: () {},
    icon: const Icon(Icons.cancel),
    color: Colors.red,
    iconSize: 50,
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: const Text("Notice"),
    content: const Text("Are you sure to Transfer this Data"),
    actions: [
      cancelButton,
      confirmButton,
    ],
  );
  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
