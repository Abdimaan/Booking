import 'package:flutter/material.dart';

class custom extends StatelessWidget {
  final VoidCallback Onpress;
  final String title;
  final IconData icon;

  const custom({
    super.key,
    required this.Onpress,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: Onpress,
        child: Container(
          width: screenWidth * 0.2,
          height: screenHeight * 0.15,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class custom2 extends StatelessWidget {
  final String imagePath;
  final String title;
  const custom2({super.key, required this.imagePath, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 5.0),
      child: Container(
        width: 120, // FIXED WIDTH for consistent look across devices
        margin: const EdgeInsets.only(right: 12), // fixed gap between items
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                imagePath,
                height: 90,
                width: 120,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final List<custom2> categories = [
  custom2(imagePath: "images/cont.jpg", title: 'Content\n Creator'),
  custom2(imagePath: "images/plumber.jpg", title: 'Plumber'),
  custom2(imagePath: "images/computer.jpg", title: 'IT Support'),
  custom2(imagePath: "images/electricty.jpg", title: 'Electrician'),
  custom2(imagePath: "images/cont.jpg", title: 'Content\n Creator'),
  custom2(imagePath: "images/plumber.jpg", title: 'Plumber'),
  custom2(imagePath: "images/computer.jpg", title: 'IT Support'),
  custom2(imagePath: "images/electricty.jpg", title: 'Electrician'),
  custom2(imagePath: "images/cont.jpg", title: 'Content\n Creator'),
  custom2(imagePath: "images/plumber.jpg", title: 'Plumber'),
  custom2(imagePath: "images/computer.jpg", title: 'IT Support'),
  custom2(imagePath: "images/electricty.jpg", title: 'Electrician'),
];
