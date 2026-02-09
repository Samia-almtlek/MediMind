import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Treatments", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0),
      body: Center(child: Text("Treatment history and long-term schedule will appear here.")),
    );
  }
}