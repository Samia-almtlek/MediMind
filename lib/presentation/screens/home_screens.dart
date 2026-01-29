import 'package:flutter/material.dart';
import '../../domain/models/medication.dart';
import '../../utils/app_colors.dart';

// Home screen displaying today's medication schedule
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /* Sample medication data
  final List<Medication> dailyMeds = [
    Medication(name: "Paracetamol", dosage: "500 mg", time: "08:00 AM"),
    Medication(name: "Insulin Glargine", dosage: "Target dose", time: "09:30 AM", isTaken: true),
    Medication(name: "Vitamin D", dosage: "2000 IU", time: "12:00 PM"),
  ];*/

  DateTime selectedDate = DateTime.now(); // day the user is viewing
  DateTime today = DateTime.now();
  //dit is nu een lege lijst om later te vullen via de API of db
  List<Medication> activeMeds = [];

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
    // Simuleer het inladen van data (straks komt dit uit Firestore)
    setState(() {
      activeMeds = [
        Medication(name: "Paracetamol", dosage: "500 mg", time: "08:00 AM"),
        Medication(
          name: "Insulin Glargine",
          dosage: "Target dose",
          time: "09:30 AM",
          isTaken: true,
        ),
      ];
    });
  }

  // Filters medications for the selected date,wil eck if medication's start/end date matches selectedDate
  // For now: Returns empty list to show "No medication" view
  List<Medication> _getListForSelectedDate() {
    return activeMeds.where((med) {
      // TODO: Add logic to check if 'med' is active on 'selectedDate'
      return false; // Forces the "No medication" view
    }).toList();
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.backgroundWhite,
    appBar: AppBar(
      title: Text("Today", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      centerTitle: true,
      backgroundColor: AppColors.backgroundWhite,
      elevation: 0,
      actions: [
        IconButton(icon: Icon(Icons.more_horiz, color: Colors.black), onPressed: () {})
      ],
    ),
    body: Column( // <--- HIER BEGINT DE COLUMN
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. De Maand-indicator (NIEUW)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Text(
            _getMonthName(selectedDate),
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold, 
              color: AppColors.iconGrey
            ),
          ),
        ),

        // 2. De Kalender
        _buildHorizontalCalendar(),

        // 3. De Dynamische Titel (Vandaag of Geselecteerde Datum)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Text(
            DateUtils.isSameDay(selectedDate, today) 
                ? "Today's Schedule" 
                : "Schedule for ${selectedDate.day} ${_getMonthName(selectedDate).split(' ')[0]}", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
          ),
        ),

        // 4. De Lijst (of Empty State)
        Expanded(
          child: _getListForSelectedDate().isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 50, color: Colors.grey),
                      SizedBox(height: 10),
                      Text("No medication scheduled for this day.", 
                          style: TextStyle(color: Colors.grey)),
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
    return Container(
      height: 100,
      child: ListView.builder(
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
                // Hier filteren we later de data uit  database
              });
            },
            child: Container(
              width: 60,
              margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
      padding: EdgeInsets.only(bottom: 20),
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final med = meds[index];
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightTeal,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(Icons.alarm, color: AppColors.iconGrey, size: 28),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.time,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "${med.name} ${med.dosage}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: 1.3,
                child: Checkbox(
                  value: med.isTaken,
                  activeColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (val) {
                    setState(() => med.isTaken = val!);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
