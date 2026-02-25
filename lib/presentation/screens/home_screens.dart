import 'package:flutter/material.dart';
import 'dart:async';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/medication.dart';
import '../../utils/app_colors.dart';
import '../../utils/global_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../utils/app_colors.dart';
import 'package:medimind/domain/models/medication.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();
  DateTime today = DateTime.now();
  //dit is nu een lege lijst om later te vullen via de API of db
  List<Medication> activeMeds = [];
  List<TargetFocus> targets = [];
  final GlobalKey keyMenu = GlobalKey();
  final GlobalKey keyCalendar = GlobalKey();
  final GlobalKey keyCheckmark = GlobalKey();

  final ScrollController _scrollController = ScrollController(
    initialScrollOffset: 500 * 68.0 - 150,
  );
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _medicationsSubscription;

  String _getMonthName(DateTime date) {
    List<String> months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return "${months[date.month - 1]} ${date.year}";
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    Future.delayed(const Duration(milliseconds: 500), () {
      _checkFirstTime();
    });
  }

  void _loadInitialData() {
    _medicationsSubscription = FirebaseFirestore.instance
        .collection('user_medications')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        print(
            "Firestore Data: ${doc.data()}"); // Check your debug console for this!
      }
      if (!mounted) return;
      setState(() {
        userAddedMeds =
            snapshot.docs.map((doc) => Medication.fromFirestore(doc)).toList();
      });
    });
  }

  @override
  void dispose() {
    _medicationsSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('home_tour_seen') ?? false;
    if (!mounted || seen) return;
    showTutorial();
    await prefs.setBool('home_tour_seen', true);
  }

  void showTutorial() {
    if (!mounted) return;
    targets = [];

    targets.add(
      TargetFocus(
        identify: "Target Menu",
        keyTarget: keyMenu,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialCard(
                title: "Manage your meds",
                message: "Click here to delete or edit medications.",
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "Target Calendar",
        keyTarget: keyCalendar,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialCard(
                title: "Pick a day",
                message:
                    "Use this horizontal calendar to navigate through your medication schedule.",
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "Target Checkmark",
        keyTarget: keyCheckmark,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialCard(
                title: "Mark as taken",
                message:
                    "Check this box when you have taken your medication for the selected date.",
              );
            },
          ),
        ],
      ),
    );

    TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.primaryBlue,
      textSkip: "SKIP",
      paddingFocus: 6,
      opacityShadow: 0.78,
      onFinish: () => print("Tour finished"),
    ).show(context: context);
  }

  Widget _buildTutorialCard({
    required String title,
    required String message,
  }) {
    return Container(
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
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // Filters medications for the selected date,wil eck if medication's start/end date matches selectedDate
  // For now: Returns empty list to show "No medication" view
  List<Medication> _getListForSelectedDate() {
    List<Medication> filteredMeds = [];

    for (var med in allUserMeds) {
      DateTime start =
          DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
      DateTime end =
          DateTime(med.endDate.year, med.endDate.month, med.endDate.day);

      // Check if med is active on this day
      if (!dateOnly.isBefore(start) && !dateOnly.isAfter(end)) {
        // Split times from: "Times: 8:00 AM, 4:00 PM. Notes: ..."
        String timePart = med.instructions
            .split("Notes:")[0]
            .replaceAll("Times: ", "")
            .trim();
        List<String> times =
            timePart.split(", ").where((t) => t.isNotEmpty).toList();

        for (String t in times) {
          dailyDoses.add(Medication(
            id: med.id,
            name: med.name,
            dosage: med.dosage,
            time: t, // Each time gets its own card
            frequency: med.frequency,
            startDate: med.startDate,
            endDate: med.endDate,
            instructions: med.instructions,
            completedDoseIds: med.completedDoseIds,
          ));
        }
      }
    }
    // Sort by time
    dailyDoses.sort((a, b) => a.time.compareTo(b.time));
    return dailyDoses;
  }

  // Unique ID to track if a specific time on a specific day was checked
  String _getDoseId(DateTime date, String time) {
    return "${date.year}-${date.month}-${date.day}_$time";
  }

  Future<void> _toggleDose(Medication med, String time, bool isTaken) async {
    String doseId = _getDoseId(selectedDate, time);
    List<String> updatedHistory = List<String>.from(med.completedDoseIds);

    if (isTaken) {
      if (!updatedHistory.contains(doseId)) updatedHistory.add(doseId);
    } else {
      updatedHistory.remove(doseId);
    }

    await FirebaseFirestore.instance
        .collection('user_medications')
        .doc(med.id)
        .update({'completedDoseIds': updatedHistory});
  }

  @override
  Widget build(BuildContext context) {
    final dosesForDay = _getFlattenedDosesForDate();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          "Today",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        actions: [
          IconButton(
            key: keyMenu,
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: _showMoreActions,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              _getMonthName(selectedDate),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.iconGrey,
              ),
            ),
          ),
          _buildHorizontalCalendar(),
          _buildHorizontalCalendar(calendarTileKey: keyCalendar),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              DateUtils.isSameDay(selectedDate, today)
                  ? "Today's Schedule"
                  : "Schedule for ${selectedDate.day} ${_getMonthName(selectedDate).split(' ')[0]}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: dosesForDay.isEmpty
                ? const Center(
                    child: Text(
                      "No medication scheduled for this day.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : _buildDoseList(dosesForDay),
          ),
        ],
      ),
    );
  }

  // Builds a horizontal calendar automatically
  Widget _buildHorizontalCalendar({Key? calendarTileKey}) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          DateTime dateToShow = today.add(Duration(days: index - 500));
          bool isSelected = DateUtils.isSameDay(dateToShow, selectedDate);
          bool isToday = DateUtils.isSameDay(dateToShow, today);

          List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
          String dayName = days[dateToShow.weekday - 1];

          return GestureDetector(
            onTap: () => setState(() => selectedDate = dateToShow),
            child: Container(
              key: index == 500 ? calendarTileKey : null,
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.backgroundWhite,
                borderRadius: BorderRadius.circular(15),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primaryBlue, width: 2)
                    : Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayName,
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12)),
                  Text("${dateToShow.day}",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoseList(List<Medication> doses) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: doses.length,
      itemBuilder: (context, index) {
        final med = doses[index];
        final doseId = _getDoseId(selectedDate, med.time);
        final bool isTaken = med.completedDoseIds.contains(doseId);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightTeal.withOpacity(0.4),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(med.time,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue)),
                  const Text("Scheduled",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      med.dosage,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  key: index == 0 ? keyCheckmark : null,
                  //check if the current date (at midnight) is in the completedDates list for this medication
                  value: med.completedDates
                      .any((d) => DateUtils.isSameDay(d, selectedDate)),
                  activeColor: AppColors.primaryBlue,
                  onChanged: (value) =>
                      _toggleDose(med, med.time, value ?? false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
