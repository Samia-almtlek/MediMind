import 'package:flutter/material.dart';
import '../../domain/models/medication.dart';

/// Home screen displaying today's medication schedule
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Sample medication data
  final List<Medication> dailyMeds = [
    Medication(name: "Paracetamol", dosage: "500 mg", time: "08:00 AM"),
    Medication(name: "Insulin Glargine", dosage: "Target dose", time: "09:30 AM", isTaken: true),
    Medication(name: "Vitamin D", dosage: "2000 IU", time: "12:00 PM"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Today", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [IconButton(icon: Icon(IconData(0xe3b3, fontFamily: 'MaterialIcons'), color: Colors.black), onPressed: () {})],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //hrizontal calendar showing the week
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                bool isSelected = index == 5;
                return Container(
                  width: 60,
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Color(0xFF7B96B2) : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Day", style: TextStyle(color: isSelected ? Colors.white : Colors.grey)),
                      Text("${22 + index}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black)),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Today's Schedule", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),

          // Medication list displaying scheduled meds
          Expanded(
            child: ListView.builder(
              itemCount: dailyMeds.length,
              itemBuilder: (context, index) {
                final med = dailyMeds[index];
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFC5E0DC),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alarm, color: Color(0xFF5A7D8A)),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(med.time, style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("${med.name} ${med.dosage}", style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                      //the check box for medication 
                      Checkbox(
                        value: med.isTaken,
                        onChanged: (val) {
                          setState(() {
                            med.isTaken = val!;
                          });
                        },
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}