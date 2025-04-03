import 'package:flutter/material.dart';

class TaskScheduler extends StatefulWidget {
  const TaskScheduler({super.key});

  @override
  _TaskSchedulerState createState() => _TaskSchedulerState();
}

class _TaskSchedulerState extends State<TaskScheduler> {
  // Starting task list with some defaults
  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Water Crops', 'completed': false},
    {'title': 'Apply Fertilizer', 'completed': false},
  ];
  final TextEditingController _taskController = TextEditingController(); // For new task input

  // Adds a new task to the list
  void _addTask() {
    if (_taskController.text.isNotEmpty) { // Only add if there’s text
      setState(() {
        _tasks.add({'title': _taskController.text, 'completed': false});
        _taskController.clear(); // Clear the input after adding
      });
    }
  }

  // Toggles a task’s completed status
  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['completed'] = !_tasks[index]['completed'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme for the page
      appBar: AppBar(
        title: const Text(
          'Task Scheduler',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 27, 94, 32),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage Your Farm Tasks',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      hintText: 'Add new task...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: const Color.fromARGB(255, 39, 39, 39),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTask, // Hit this to add the task
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 46, 125, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    color: const Color.fromARGB(255, 39, 39, 39),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Checkbox(
                        value: _tasks[index]['completed'],
                        onChanged: (_) => _toggleTask(index), // Toggle task when checked
                        activeColor: const Color.fromARGB(255, 87, 189, 179),
                      ),
                      title: Text(
                        _tasks[index]['title'],
                        style: TextStyle(
                          fontSize: 16,
                          color: _tasks[index]['completed']
                              ? Colors.grey
                              : Colors.white, // Grey out if done
                          decoration: _tasks[index]['completed']
                              ? TextDecoration.lineThrough
                              : null, // Strike through if completed
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose(); // Clean up the controller
    super.dispose();
  }
}