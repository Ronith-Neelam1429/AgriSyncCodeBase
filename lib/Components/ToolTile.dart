import 'package:flutter/material.dart';

class ToolTile extends StatelessWidget {
  final String title;
  final Widget icon; // Changed from imageUrl to icon
  final Function onTap;

  const ToolTile({
    Key? key,
    required this.title,
    required this.icon, // Updated parameter
    required this.onTap,
  }) : super(key: key);

  // In ToolTile class, modify the build method
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Wrap with GestureDetector
      onTap: () => onTap(), // Call the onTap function
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        width: 90,
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: icon,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
