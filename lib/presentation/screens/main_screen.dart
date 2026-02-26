import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screens.dart';
import 'add_choice_screen.dart';
import '../../utils/app_colors.dart';
import 'package:medimind/data/local_db/drug_loader.dart';
import 'schedule_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  
  int _selectedIndex = 0;
  final GlobalKey _keyHomeTab = GlobalKey();
  final GlobalKey _keyScheduleTab = GlobalKey();
  final GlobalKey _keyChatTab = GlobalKey();
  final GlobalKey _keyProfileTab = GlobalKey();
  final GlobalKey _keyAddFab = GlobalKey();

  // different screens for bottom navigation of the whole app
  final List<Widget> _screens = [
    const HomeScreen(), 
    const ScheduleScreen(), 
    const ChatScreen(),
    const ProfileScreen(),
  ];
@override
void initState() {
  super.initState();

 
  WidgetsBinding.instance.addPostFrameCallback((_) {
    DrugLoader.loadDrugsIfNeeded();
    _checkAndShowMainTour();
  });
}

Future<void> _checkAndShowMainTour() async {
  final prefs = await SharedPreferences.getInstance();
  final seen = prefs.getBool('main_tour_seen') ?? false;
  if (seen || !mounted) return;

  _showMainTour();
  await prefs.setBool('main_tour_seen', true);
}

void _showMainTour() {
  final targets = <TargetFocus>[
    _buildTarget(
      identify: 'home_tab',
      key: _keyHomeTab,
      title: 'Home',
      message: 'See today\'s medication schedule and quickly check doses as taken.',
      align: ContentAlign.top,
    ),
    _buildTarget(
      identify: 'schedule_tab',
      key: _keyScheduleTab,
      title: 'Schedule',
      message: 'Browse your treatment plan by month and track progress.',
      align: ContentAlign.top,
    ),
    _buildTarget(
      identify: 'chat_tab',
      key: _keyChatTab,
      title: 'Chat',
      message: 'Ask MediMind questions about medications and health guidance.',
      align: ContentAlign.top,
    ),
    _buildTarget(
      identify: 'profile_tab',
      key: _keyProfileTab,
      title: 'Profile',
      message: 'Manage your account, privacy, and medical preferences.',
      align: ContentAlign.top,
    ),
    _buildTarget(
      identify: 'add_button',
      key: _keyAddFab,
      title: 'Add medication',
      message: 'Use this button to add a new medication by scan or manual input.',
      align: ContentAlign.left,
    ),
  ];

  TutorialCoachMark(
    targets: targets,
    colorShadow: AppColors.primaryBlue,
    opacityShadow: 0.78,
    alignSkip: Alignment.topLeft,
    skipWidget: SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 14, top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite.withOpacity(0.18),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.lightTeal.withOpacity(0.9)),
        ),
        child: const Text(
          'SKIP',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ),
    paddingFocus: 8,
  ).show(context: context);
}

TargetFocus _buildTarget({
  required String identify,
  required GlobalKey key,
  required String title,
  required String message,
  required ContentAlign align,
}) {
  return TargetFocus(
    identify: identify,
    keyTarget: key,
    contents: [
      TargetContent(
        align: align,
        builder: (_, __) => Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.iconGrey.withOpacity(0.95),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.lightTeal.withOpacity(0.75)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: Colors.white, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

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
        key: _keyAddFab,
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        onPressed: () {

  Navigator.push(
    context, 
    MaterialPageRoute(builder: (context) => const AddChoiceScreen())
  ) .then ((_) {
    setState(() {}); // Refresh the state when returning from AddChoiceScreen
  });

},
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.backgroundWhite,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled, key: _keyHomeTab),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month, key: _keyScheduleTab),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline, key: _keyChatTab),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, key: _keyProfileTab),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}