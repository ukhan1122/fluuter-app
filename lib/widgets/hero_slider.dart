import 'package:flutter/material.dart';

class HeroSlider extends StatelessWidget {
  const HeroSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD71208), // Red background
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Left: Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Sell What You Don’t Wear.\nShop What You Love.",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "Turn your wardrobe into earnings — sell your pre-loved or brand-new clothes easily and find stylish deals that don’t break the bank.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Right: Hanger image
          Expanded(
            child: Container(
              height: 200,
              margin: const EdgeInsets.only(left: 20),
              child: Image.asset(
                'assets/CLOTHES-HANGERS.png', // Your hanger image
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
