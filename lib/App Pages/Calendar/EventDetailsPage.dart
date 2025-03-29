import 'package:flutter/material.dart';
import 'package:agrisync/App%20Pages/Calendar/FarmCalendarPage.dart';

class EventDetailsPage extends StatelessWidget {
  final List<CalendarEvent> events;
  final DateTime selectedDate;

  const EventDetailsPage({Key? key, required this.events, required this.selectedDate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Events on ${selectedDate.toLocal().toString().split(' ')[0]}", style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: events.isEmpty
          ? const Center(child: Text("No events for this day.", style: TextStyle(color: Colors.black)))
          : ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(event.description, style: const TextStyle(color: Colors.black, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text("Scheduled for: ${event.date.toLocal().toString().split('.')[0]}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
