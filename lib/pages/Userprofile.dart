import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plamproject/pages/Mainmenu.dart';
import 'package:plamproject/pages/history.dart';

class UserprofilePage extends StatefulWidget {
  const UserprofilePage({Key? key}) : super(key: key);

  @override
  State<UserprofilePage> createState() => _UserprofilePageState();
}

int selectedIndex = 2;

class _UserprofilePageState extends State<UserprofilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 236, 238),
      body: Stack(
        children: [
          // Dark blue area (Header) with background image and overlay
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            alignment: Alignment.topLeft,
            height: 145,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 49, 14, 146),
              image: DecorationImage(
                image: AssetImage("assets/profilebackgground2.jpg"),
                colorFilter: ColorFilter.mode(
                  Color.fromARGB(255, 253, 253, 253),
                  BlendMode.colorBurn,
                ),
                fit: BoxFit.cover,
              ),
            ),
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
                        color: Color.fromARGB(
                            255, 6, 6, 6), // Set text color to white
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
              // Search bar and Transfer code
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color.fromARGB(255, 188, 173, 173)),
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
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
Expanded(
  child: GestureDetector(
    onTap: () {
      setState(() {
        selectedIndex = 1;
      });
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => HistoryPage()));
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.history,
          color: selectedIndex == 1 ? Colors.red : Colors.grey,
          size: 30,
        ),
        const SizedBox(height: 4), // Spacing between icon and text
        Text(
          'ประวัติ', 
          style: TextStyle(
            color: selectedIndex == 1 ? Colors.red : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    ),
  ),
),

Expanded(
  child: GestureDetector(
    onTap: () {
      setState(() {
        selectedIndex = 0;
      });
      Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => const MainmenuPage()));
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.menu,
          color: selectedIndex == 0 ? Colors.red : Colors.grey,
          size: 30,
        ),
        const SizedBox(height: 4), // Spacing between icon and text
        Text(
          'หน้าหลัก', // Text label for "Menu"
          style: TextStyle(
            color: selectedIndex == 0 ? Colors.red : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    ),
  ),
),

            Expanded(
              child: GestureDetector(
                 onTap: () {
                  setState(() {
                 selectedIndex = 2;
                 });
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (BuildContext context) => const UserprofilePage()));
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.info,
          color: selectedIndex == 2 ? Colors.red : Colors.grey,
          size: 30,
        ),
        const SizedBox(height: 4), // Spacing between icon and text
        Text(
          'ข้อมูล', // Text label
          style: TextStyle(
            color: selectedIndex == 2 ? Colors.red : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    ),
  ),
        ),

          ],
        ),
      ),
    );
  }
}

showAlertDialog(BuildContext context) {
  // Set up the buttons
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

  // Set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: const Text("Notice"),
    content: const Text("Are you sure to Transfer this Data"),
    actions: [
      cancelButton,
      confirmButton,
    ],
  );
  // Show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
