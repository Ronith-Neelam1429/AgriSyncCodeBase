import 'package:flutter/material.dart';

class ToolTile extends StatelessWidget {
  final String title;
  final Widget icon; // Using a widget for the icon instead of an image URL
  final Function onTap;

  const ToolTile({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(), // Fires off whatever action we pass in
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0), // Little space on the sides
        width: 90, // Fixed width to keep tiles neat
        child: Card(
          elevation: 3, // Gives it a slight lift off the screen
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Rounded corners for style
          ),
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center everything vertically
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1), // Light background for the icon
                    shape: BoxShape.circle, // Makes it a nice circle
                  ),
                  child: icon, // Stick the icon in here
                ),
                const SizedBox(height: 8), // Space between icon and text
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center, // Keep the title centered
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}