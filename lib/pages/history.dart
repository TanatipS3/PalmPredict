import 'package:flutter/material.dart';

// New Page to navigate to
class DetailPage extends StatelessWidget {
  final String name;
  final String dateTime;
  final String imagePath;

  DetailPage({required this.name, required this.dateTime, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Column(
        children: [
          Image.asset(imagePath), // Show image
          SizedBox(height: 20),
          Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text(dateTime, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class HistoryItem {
  final String name;
  final String dateTime;
  final String imagePath;

  HistoryItem({required this.name, required this.dateTime, required this.imagePath});
}

class _HistoryPageState extends State<HistoryPage> {
  final List<HistoryItem> items = [
    HistoryItem(name: 'James', dateTime: 'Jan 1, 2003 2:30', imagePath: 'assets/hand.png'),
    HistoryItem(name: 'Sarah', dateTime: 'Feb 5, 2021 14:45', imagePath: 'assets/hand2.PNG'),
    // Add more items as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/profilebackgground2.jpg"),
            colorFilter: ColorFilter.mode(Color.fromARGB(96, 123, 121, 121), BlendMode.colorBurn), // Path to your background image
            fit: BoxFit.cover, // Ensures the image covers the entire background
          ),
        ),
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.white
                    
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Enter text',
                          hintStyle: TextStyle(color: Colors.white),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search),
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20), // Space between search bar and grid

            // Scrollable grid of items
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columns
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.0, // Adjust aspect ratio to control item height
                  ),
                  itemCount: items.length, // Use the length of items list
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return GestureDetector(
                      onTap: () {
                        //item tap acti9on
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color.fromARGB(255, 188, 173, 173)),
                        ),
                        child: Column(
                          children: [
                            // Picture section
                            Container(
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(item.imagePath, fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Name and Date/Time section
                            Text(
                              item.name, // Display the actual name
                              style: const TextStyle(color: Colors.white,fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.dateTime, // Display the actual date/time
                              style: TextStyle(color: const Color.fromARGB(255, 255, 255, 255)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
