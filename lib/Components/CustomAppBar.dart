import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final String name;
  final String profileImageUrl;

  const CustomAppBar({
    super.key,
    required this.name,
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Profile Picture and Greeting Section
          Expanded(
            child: Row(
              children: [
                // Profile Picture with error handling
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(profileImageUrl),
                  onBackgroundImageError: (exception, stackTrace) {
                    // Fallback to default avatar if image loading fails
                    debugPrint('Error loading profile image: $exception');
                  },
                  child: profileImageUrl.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                // Greeting and Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '👋',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Rest of your AppBar content remains the same
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(Icons.sunny, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 12),
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Icon(Icons.notifications_outlined,
                        color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}