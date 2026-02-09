import 'package:flutter/material.dart';
import 'home_screens.dart';
import 'add_choice_screen.dart';
import '../../utils/app_colors.dart';
import 'schedule_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  
  int _selectedIndex = 0;

  // different screens for bottom navigation of the whole app
  final List<Widget> _screens = [
    HomeScreen(), 
    ScheduleScreen(), 
    ChatScreen(),
    ProfileScreen(),
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
      // The Floating Action Button
      floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
        backgroundColor: AppColors.primaryBlue,
        child: Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () {
  Navigator.push(
    context, 
    MaterialPageRoute(builder: (context) => AddChoiceScreen())
  );
},
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.backgroundWhite,
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