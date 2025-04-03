import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/calendar/v3.dart' as googleCalendar;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class AddEventPage extends StatefulWidget {
  final GoogleSignIn? googleSignIn;
  final googleCalendar.CalendarApi? calendarApi;
  
  const AddEventPage({
    Key? key,
    this.googleSignIn,
    this.calendarApi,
  }) : super(key: key);

  @override
  _AddEventPageState createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>(); // Keeps track of the form
  final TextEditingController _titleController = TextEditingController(); // For the event title
  final TextEditingController _descriptionController = TextEditingController(); // For the event details
  DateTime _selectedDate = DateTime.now(); // Default to today
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0); // Default to 9:00 AM
  bool _isLoading = false; // Shows if we're saving
  bool _isGoogleCalendarConnected = false;

  @override
  void initState() {
    super.initState();
    _checkGoogleCalendarStatus();
  }
  
  void _checkGoogleCalendarStatus() {
    setState(() {
      _isGoogleCalendarConnected = widget.calendarApi != null;
    });
  }

  // Pops up a calendar to pick a date
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Past year
      lastDate: DateTime.now().add(const Duration(days: 365)), // Next year
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Pops up a clock to pick a time
  Future<void> _selectTime() async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  // Saves the event to Firestore
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return; // Stop if form's not good
    _formKey.currentState!.save();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // No user, no save
    setState(() {
      _isLoading = true; // Show spinner
    });

    DateTime eventDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute, // Combine date and time
    );

    try {
      // 1. Create Firestore event first
      String? googleCalendarEventId;
      
      // 2. If Google Calendar is connected, create event there
      if (widget.calendarApi != null) {
        try {
          final googleEvent = googleCalendar.Event();
          googleEvent.summary = _titleController.text.trim();
          googleEvent.description = _descriptionController.text.trim();
          
          // Correctly set start and end time
          final startDateTime = googleCalendar.EventDateTime();
          startDateTime.dateTime = eventDateTime.toUtc();
          startDateTime.timeZone = 'UTC';
          googleEvent.start = startDateTime;
          
          final endDateTime = googleCalendar.EventDateTime();
          endDateTime.dateTime = eventDateTime.toUtc().add(const Duration(hours: 1));
          endDateTime.timeZone = 'UTC';
          googleEvent.end = endDateTime;
          
          final createdEvent = await widget.calendarApi!.events.insert(googleEvent, 'primary');
          googleCalendarEventId = createdEvent.id;
        } catch (e) {
          print("Error creating Google Calendar event: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to add to Google Calendar: $e"))
          );
        }
      }

      // 3. Save to Firestore with Google Calendar ID if available
      await FirebaseFirestore.instance
          .collection('farmActivities')
          .doc(user.uid)
          .collection('events')
          .add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': Timestamp.fromDate(eventDateTime),
        'createdAt': FieldValue.serverTimestamp(), // Timestamp for sorting
        'googleCalendarEventId': googleCalendarEventId,
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(googleCalendarEventId != null 
            ? "Event added and synced to Google Calendar" 
            : "Event added successfully"))
      );
      Navigator.pop(context); // Back to previous screen
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error saving event: $e")));
    } finally {
      setState(() {
        _isLoading = false; // Hide spinner
      });
    }
  }

  // Reusable styling for text fields
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Event', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator()) // Spinner while saving
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isGoogleCalendarConnected)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.cloud_done, color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "This event will be synced to Google Calendar",
                                style: TextStyle(color: Colors.green, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('Title'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a title';
                        return null; // Make sure title's not empty
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration('Description'),
                      maxLines: 3, // Room for more text
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _selectDate,
                            child: Text("Select Date: ${_selectedDate.toLocal().toString().split(' ')[0]}", style: const TextStyle(color: Colors.black)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _selectTime,
                            child: Text("Select Time: ${_selectedTime.format(context)}", style: const TextStyle(color: Colors.black)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveEvent, // Hit this to save
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255,66,192,201),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Save Event', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}