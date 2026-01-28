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
  //dit is nu een lege lijst om later te vullen via de API of db
  List<Medication> activeMeds= [];

  @override 
  void intitState() {
    super.initState();
    _loadInitialData();
  }

 void _loadInitialData() {
    // Simuleer het inladen van data (straks komt dit uit Firestore)
    setState(() {
      activeMeds = [
        Medication(name: "Paracetamol", dosage: "500 mg", time: "08:00 AM"),
        Medication(name: "Insulin Glargine", dosage: "Target dose", time: "09:30 AM", isTaken: true),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text("Today", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        actions: [IconButton(icon: Icon(Icons.more_horiz, color: Colors.black), onPressed: () {})],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //hrizontal calendar showing the week
          _buildHorizontalCalendar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text("Today's Schedule", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: activeMeds.isEmpty
              ? Center(child: Text("No medication added yet. Click + to start!"))
              : _buildMedicationList(),
          ),
        ],
      ),
    );
  }
  // Builds a horizontal calendar for the current week
  Widget _buildHorizontalCalendar() {
    return Container(
      height: 90,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
          bool isSelected = index == 5; // Zaterdag geselecteerd zoals in prototype
          
          return Container(
            width: 55,
            margin: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(days[index], 
                    style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12)),
                SizedBox(height: 4),
                Text("${22 + index}", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, 
                    color: isSelected ? Colors.white : Colors.black)),
              ],
            ),
          );
        },
      ),
    );
  }

  // Builds the list of medications for the day

  Widget _buildMedicationList() {
    return ListView.builder(
      padding: EdgeInsets.only(bottom: 20),
      itemCount: activeMeds.length,
      itemBuilder: (context, index) {
        final med = activeMeds[index];
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
                    Text(med.time, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    Text("${med.name} ${med.dosage}", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Transform.scale(
                scale: 1.3,
                child: Checkbox(
                  value: med.isTaken,
                  activeColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) {
                    setState(() => med.isTaken = val!);
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}