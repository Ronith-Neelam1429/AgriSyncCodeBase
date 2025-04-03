import 'package:flutter/material.dart';
import 'package:agrisync/App%20Pages/Calendar/FarmCalendarPage.dart';

class EventDetailsPage extends StatelessWidget {
  final List<CalendarEvent> events; // List of events for the selected day
  final DateTime selectedDate; // The day we’re looking at

  const EventDetailsPage({Key? key, required this.events, required this.selectedDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Events on ${selectedDate.toLocal().toString().split(' ')[0]}", // Show the date in a nice format
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: events.isEmpty
          ? const Center(
              child: Text(
                "No events for this day.",
                style: TextStyle(color: Colors.black),
              ),
            ) // Message if nothing’s planned
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index]; // Grab the current event
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Space around each card
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // Rounded edges for style
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                        ), // Event title stands out
                        const SizedBox(height: 8),
                        Text(
                          event.description,
                          style: const TextStyle(color: Colors.black, fontSize: 16),
                        ), // Details below
                        const SizedBox(height: 8),
                        Text(
                          "Scheduled for: ${event.date.toLocal().toString().split('.')[0]}", // Show the full date and time
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}