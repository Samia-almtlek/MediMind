import 'package:flutter/material.dart';
import 'home_screens.dart';
import '../../utils/app_colors.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  
  int _selectedIndex = 0;

  // different screens for bottom navigation of the whole app
  final List<Widget> _screens = [
    HomeScreen(), 
    Center(child: Text("Schedule Page")), 
    Center(child: Text("Chat Page")), 
    Center(child: Text("Profile Page")),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      // The Floating Action Button (The Plus Sign)
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        child: Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () {
          // this is to navigate later to AddMedicationChoiceScreen
          print("Add medication clicked");
        },
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}