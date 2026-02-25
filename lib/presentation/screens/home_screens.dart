import 'package:flutter/material.dart';
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
  List<Medication> allUserMeds = [];

  // Keeps your original scroll offset
  final ScrollController _scrollController =
      ScrollController(initialScrollOffset: 500 * 68.0 - 150);

  StreamSubscription? _medSubscription;

  @override
  void initState() {
    super.initState();
    _listenToMedications();
  }

  // Listen to the user_medications collection (Synced with Treatment Screen)
  void _listenToMedications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _medSubscription = FirebaseFirestore.instance
        .collection('user_medications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        allUserMeds =
            snapshot.docs.map((doc) => Medication.fromFirestore(doc)).toList();
      });
    });
  }

  @override
  void dispose() {
    _medSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

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

  // Logic to determine which doses appear on the selected calendar day
  List<Medication> _getFlattenedDosesForDate() {
    List<Medication> dailyDoses = [];
    DateTime dateOnly =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

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

  Widget _buildHorizontalCalendar() {
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
                  value: isTaken,
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
