import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/global_data.dart';
import 'package:intl/intl.dart';
import '../../domain/models/medication.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Process the global list to split multiple times into individual entries
    final List<Medication> flattenedMeds =
        _getFlattenedMedicationList(userAddedMeds);
    final Map<String, List<Medication>> groupedMeds =
        _groupMedsByMonth(flattenedMeds);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          "Treatment Plan",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: flattenedMeds.isEmpty
          ? _buildEmptyState()
          : _buildGroupedTreatmentList(groupedMeds),
    );
  }

  /// NEW: Helper to turn 1 Medication with 3 times into 3 Medication entries for display
  List<Medication> _getFlattenedMedicationList(List<Medication> meds) {
    List<Medication> results = [];
    for (var med in meds) {
      // Extract times from: "Times: 8:00 AM, 4:00 PM. Notes: ..."
      String timePart =
          med.instructions.split("Notes:")[0].replaceAll("Times: ", "").trim();

      // Split by comma and clean up whitespace
      List<String> allTimes = timePart
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (allTimes.isEmpty) {
        results.add(med); // Fallback if parsing fails
      } else {
        for (String t in allTimes) {
          results.add(
            Medication(
              id: med.id,
              name: med.name,
              dosage: med.dosage,
              time: t, // Set the specific time for this card
              startDate: med.startDate,
              endDate: med.endDate,
              completedDates: med.completedDates,
              instructions: med.instructions,
              frequency: med.frequency,
            ),
          );
        }
      }
    }
    return results;
  }

  Map<String, List<Medication>> _groupMedsByMonth(List<Medication> meds) {
    Map<String, List<Medication>> groups = {};
    for (var med in meds) {
      String monthKey = DateFormat('MMMM yyyy').format(med.endDate);
      if (groups[monthKey] == null) groups[monthKey] = [];
      groups[monthKey]!.add(med);
    }
    return groups;
  }

  Widget _buildGroupedTreatmentList(Map<String, List<Medication>> groupedMeds) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedMeds.keys.length,
      itemBuilder: (context, index) {
        String month = groupedMeds.keys.elementAt(index);
        List<Medication> medsInMonth = groupedMeds[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
              child: Text(
                month,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.iconGrey),
              ),
            ),
            ...medsInMonth.map((med) => _buildTreatmentCard(med)),
          ],
        );
      },
    );
  }

  Widget _buildTreatmentCard(Medication med) {
    final DateTime today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final DateTime endDateOnly =
        DateTime(med.endDate.year, med.endDate.month, med.endDate.day);

    bool isDatePassed = today.isAfter(endDateOnly);
    // Note: If you want specific completion for specific times,
    // you'll eventually need to store completed times in Firestore too.
    bool isFullyCompleted =
        med.completedDates.any((d) => DateUtils.isSameDay(d, endDateOnly));
    final bool isActive = !isDatePassed && !isFullyCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightTeal.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time_filled, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Dosage: ${med.dosage}",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  "Scheduled for: ${med.time}",
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        isActive ? "Active" : "Finished",
        style: TextStyle(
            color: isActive ? Colors.green : Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "No active treatment plans",
            style: TextStyle(
                fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
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
