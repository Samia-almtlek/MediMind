import 'package:flutter/material.dart';
import '../../domain/models/medication.dart';
import '../../utils/app_colors.dart';
import '../../utils/global_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Home screen displaying today's medication schedule
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now(); // day the user is viewing
  DateTime today = DateTime.now();
  //dit is nu een lege lijst om later te vullen via de API of db
  List<Medication> activeMeds = [];

  final ScrollController _scrollController = ScrollController(
    initialScrollOffset: 500 * 68.0 - 150,
  );

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
  }

  void _loadInitialData() {
    FirebaseFirestore.instance
        .collection('user_medications')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        print(
            "Firestore Data: ${doc.data()}"); // Check your debug console for this!
      }
      setState(() {
        userAddedMeds =
            snapshot.docs.map((doc) => Medication.fromFirestore(doc)).toList();
      });
    });
  }

  // Filters medications for the selected date,wil eck if medication's start/end date matches selectedDate
  // For now: Returns empty list to show "No medication" view
  List<Medication> _getListForSelectedDate() {
    List<Medication> filteredMeds = [];

    for (var med in userAddedMeds) {
      // 1. Date Check
      DateTime start =
          DateTime(med.startDate.year, med.startDate.month, med.startDate.day);
      DateTime end =
          DateTime(med.endDate.year, med.endDate.month, med.endDate.day);
      DateTime current =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

      if (!current.isBefore(start) && !current.isAfter(end)) {
        // 2. Split the instructions string into individual times
        // Extracts "8:00 AM, 4:00 PM, 12:00 AM" from "Times: 8:00 AM... Notes:"
        String timePart = med.instructions
            .split("Notes:")[0]
            .replaceAll("Times: ", "")
            .trim();
        List<String> allTimes = timePart.split(", ");

        for (String individualTime in allTimes) {
          // Create a temporary copy for the UI to display each time separately
          filteredMeds.add(
            Medication(
              id: med.id,
              name: med.name,
              dosage: med.dosage,
              time: individualTime, // Now "8:00 AM", then "4:00 PM", etc.
              completedDates: med.completedDates,
              startDate: med.startDate,
              endDate: med.endDate,
              instructions: med.instructions,
              frequency: med.frequency,
            ),
          );
        }
      }
    }
    return filteredMeds;
  }

  /// Adds a new medication to the active medications list
  void _addNewMedication(Medication newMed) {
    setState(() {
      activeMeds.add(newMed);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // De Maand-indicator
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

          //  Lijst (of Empty State)
          Expanded(
            child: _getListForSelectedDate().isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "No medication scheduled for this day.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _buildMedicationList(_getListForSelectedDate()),
          ),
        ],
      ),
    );
  }

  // Builds a horizontal calendar automatically
  Widget _buildHorizontalCalendar() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          //  berekent de datum voor elke kaart relatief aan vandaag
          // index 500 is vandaag, lager is verleden, hoger is toekomst
          DateTime dateToShow = today.add(Duration(days: index - 500));
          bool isSelected = DateUtils.isSameDay(dateToShow, selectedDate);
          bool isToday = DateUtils.isSameDay(dateToShow, today);

          List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
          String dayName = days[dateToShow.weekday - 1];

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = dateToShow;
                // Hier filteren we later de data uit database
              });
            },
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
                  Text(
                    dayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "${dateToShow.day}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Builds the list of medications for the day
  Widget _buildMedicationList(List<Medication> meds) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final med = meds[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightTeal.withOpacity(0.4),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              // Time on the left side
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
              // Medication name and dosage
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(med.dosage, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              // Checkbox from prototype
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  //check if the current date (at midnight) is in the completedDates list for this medication
                  value: med.completedDates
                      .any((d) => DateUtils.isSameDay(d, selectedDate)),
                  activeColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        med.completedDates.add(selectedDate);
                      } else {
                        med.completedDates.removeWhere(
                            (d) => DateUtils.isSameDay(d, selectedDate));
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dit zorgt ervoor dat telkens wanneer we terugkomen op dit scherm (bijvoorbeeld na Navigator.pop of switch in navbar), de UI ververst.
    setState(() {});
  }
}
