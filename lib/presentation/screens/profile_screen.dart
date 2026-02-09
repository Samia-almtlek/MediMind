import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0),
      body: ListView(
        children: [
          ListTile(leading: Icon(Icons.person), title: Text("User Name"), subtitle: Text("Personal Details")),
          ListTile(leading: Icon(Icons.settings), title: Text("Settings")),
          ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text("Logout", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}