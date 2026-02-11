import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/global_data.dart';
import 'package:intl/intl.dart';
import '../../domain/models/medication.dart';

class ScheduleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Map<String, List<Medication>> groupedMeds = _groupMedsByMonth(userAddedMeds);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          "Treatment Plan",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: userAddedMeds.isEmpty 
          ? _buildEmptyState() 
          : _buildGroupedTreatmentList(groupedMeds),
    );
  }

  // Helper function to build the list of treatments grouped by month
  Map<String, List<Medication>> _groupMedsByMonth(List<Medication> meds) {
    Map<String, List<Medication>> groups = {};
    for (var med in meds) {
      // Because our model currently doesn't have a DateTime, we use 'today'
      // In the future, replace this with med.startDate
      String monthKey = DateFormat('MMMM yyyy').format(med.endDate);
      if (groups[monthKey] == null) groups[monthKey] = [];
      groups[monthKey]!.add(med);
    }
    return groups;
  }

  Widget _buildGroupedTreatmentList(Map<String, List<Medication>> groupedMeds) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: groupedMeds.keys.length,
      itemBuilder: (context, index) {
        String month = groupedMeds.keys.elementAt(index);
        List<Medication> medsInMonth = groupedMeds[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic month header based on the medication's end date
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
              child: Text(
                month,
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold, 
                  color: AppColors.iconGrey
                ),
              ),
            ),
            // The cards for this specific month
            ...medsInMonth.map((med) => _buildTreatmentCard(med)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildTreatmentCard(Medication med) {
    // responsible for determining if the treatment is still active or has finished based on the end date
    final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final DateTime endDateOnly = DateTime(med.endDate.year, med.endDate.month, med.endDate.day);
    
    bool isDatePassed = today.isAfter(endDateOnly);
    bool isFullyCompleted = med.completedDates.any((d)=> DateUtils.isSameDay(d, endDateOnly));
    // Check if the current date is before the end date
    final bool isActive = !isDatePassed && !isFullyCompleted;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightTeal.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication, color: AppColors.primaryBlue),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Dosage: ${med.dosage}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 4),
                Text(
                  "Time: ${med.time}",
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(isActive),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
            width: 1,
          ),
      ),
      child: Text(
        isActive ? "Active" : "Inactive",
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red, 
          fontSize: 12, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  // Shown when no medications have been added yet
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            "No active treatment plans",
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Text(
              "Your scheduled medications and treatment history will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }

}