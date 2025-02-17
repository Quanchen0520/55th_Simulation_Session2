import 'package:flutter/material.dart';
import 'TaskStorage.dart';

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final data = await TaskStorage.loadTasks();
    setState(() {
      tasks = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("任務清單")),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text("工作: ${task['workMinutes']} 分鐘"),
            subtitle: Text("休息: ${task['restMinutes']} 分鐘"),
          );
        },
      ),
    );
  }
}
