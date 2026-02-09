import 'package:flutter/material.dart';

class CategoryTags extends StatelessWidget {
  final Function(String?) onCategorySelected;

  const CategoryTags({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> tags = [
      {'title': 'All', 'section': 'All'},
      {'title': "Men's", 'section': 'Men'},
      {'title': "Women's", 'section': 'Women'},
      {'title': "Kid's", 'section': 'Kids'},
      {'title': "Wedding Dresses", 'section': 'Wedding'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: tags.map((tag) {
          return GestureDetector(
            onTap: () {
              if (tag['section'] == 'All') {
                onCategorySelected(null); // null = show all
              } else {
                onCategorySelected(tag['section']);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag['title']!,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
