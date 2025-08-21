import 'package:booking/constant.dart';
import 'package:flutter/material.dart';
// import 'package:login/booking/Mbooking.dart';
// import 'package:login/booking/carpeneter.dart';
// import 'package:login/booking/computer.dart';
// import 'package:login/booking/content.dart';
// import 'package:login/booking/electric.dart';
// import 'package:login/booking/hometeach.dart';
// import 'package:login/booking/maid.dart';
// import 'package:login/booking/welder.dart';
// import 'package:login/constanst.dart';
// import 'package:curved_navigation_bar/curved_navigation_bar.dart';
// import 'package:login/booking/plumber.dart';

void main() => runApp(const FududeeyeApp());

class FududeeyeApp extends StatelessWidget {
  const FududeeyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B0935),
        elevation: 0,
        automaticallyImplyLeading: false, // No back button
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: Image.asset(
                'images/logo.jpg', // Replace with your logo path
                // height: 50,
                width: 50,
                fit: BoxFit.contain,
              ),
            ),

            // Center title
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: 'FUDU',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'DEEYE',
                    style: TextStyle(color: Color(0xFF00B8B0)),
                  ),
                ],
              ),
            ),

            // Notification icon
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.logout, color: Color(0xFF00B8B0)),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 0, bottom: 20, left: 0, right: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              ClipRRect(
                // borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      height: 300,
                      width: MediaQuery.of(context).size.width / 0.5,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('images/home.png'),
                          // Replace with actual image
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.4),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      // left: 16,
                      // top: 16,
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: const Text(
                                "Find the right freelancer\nand client for you\nChoose Fududeeye",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: () {
                                // Navigator.push(
                                //   context,
                                //   MaterialPageRoute(
                                //     builder: (context) => const Booking(),
                                //   ),
                                // );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text("Book Now"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Raadi xirfadle ama shaqaale",
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Search",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 34),

              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: const Text(
                  "CATEGORIES",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1B0935),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.only(right: 10, left: 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: custom(
                            Onpress: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) =>
                              //         const ElectricianDetailsPage(),
                              //   ),
                              // );
                            },
                            title: 'Electricity',
                            icon: Icons.flash_on,
                          ),
                        ),
                        Expanded(
                          child: custom(
                            Onpress: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => const welder(),
                              //   ),
                              // );
                            },
                            title: 'Welder',
                            icon: Icons.build,
                          ),
                        ),
                        Expanded(
                          child: custom(
                            Onpress: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => const plumber(),
                              //   ),
                              // );
                            },
                            title: 'Plumber',
                            icon: Icons.handyman,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: custom(
                            Onpress: () {},
                            title: 'Handyman',
                            icon: Icons.engineering,
                          ),
                        ),
                        Expanded(
                          child: custom(
                            Onpress: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => const content(),
                              //   ),
                              // );
                            },
                            title: 'Content Creators',
                            icon: Icons.video_call,
                          ),
                        ),
                        Expanded(
                          child: custom(
                            Onpress: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => const computersupport(),
                              //   ),
                              // );
                            },
                            title: 'Computer Support',
                            icon: Icons.computer,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: custom(
                            Onpress: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => const hometeaching(),
                              //   ),
                              // );
                            },
                            title: 'Home Teaching',
                            icon: Icons.menu_book,
                          ),
                        ),
                        Expanded(
                          child: custom(
                            Onpress: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => const maids(),
                              //   ),
                              // );
                            },
                            title: 'Maids',
                            icon: Icons.cleaning_services,
                          ),
                        ),
                        Expanded(
                          child: custom(
                            Onpress: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => const carpeneter(),
                              //   ),
                              // );
                            },
                            title: 'Carpenter',
                            icon: Icons.chair_alt,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              //Most Popular Categories
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: const Text(
                  "Most Popular Categories",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                height: 150,

                width: double.infinity,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Row(
                      children: [
                        custom2(
                          imagePath: category.imagePath,
                          title: category.title,
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Do you have a skill?\nJoin as a freelancer today!",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.teal,
                        ),
                        child: const Text("Register"),
                      ),
                    ],
                  ),
                ),
              ),

              // const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      // Add the custom bottom navigation bar here
//       bottomNavigationBar: CurvedNavigationBar(
//         // index: 0,
//         height: 75,
//         color: const Color(0xFF00163A),
//         backgroundColor: Colors.transparent,
//         buttonBackgroundColor: const Color(0xFF00163A),
//         animationCurve: Curves.easeInOut,
//         animationDuration: const Duration(seconds: 30),
//         items: const [
//           Icon(Icons.home, size: 30, color: Colors.white),
//           Icon(Icons.event_note, size: 30, color: Colors.white),
//           Icon(Icons.chat, size: 30, color: Colors.white),
//           Icon(Icons.person, size: 30, color: Colors.white),
//         ],
//         onTap: (index) {
//           if (index == 0) {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const HomeScreen()),
//             );
//           } else if (index == 1) {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => const Booking()),
//             );
//           } else if (index == 2) {
//             // Navigate to chat screen
//           } else if (index == 3) {
//             // Navigate to profile screen
//           }
//         },
//       ),
    );
  }
}

// // Removed legacy CustomBottomNavBar; using CurvedNavigationBar instead.
