import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../utils/app_colors.dart';
import '../../data/models/user_medication_model.dart'; // 🔥 changed model
import '../../domain/models/medication.dart';
import '../../core/widgets/speaker_button.dart';

class ScheduleScreen extends StatelessWidget {
  String _buildScheduleSummary(List<Medication> meds) {
    if (meds.isEmpty) {
      return "You currently have no active treatment plans.";
    }

    String summary = "Your treatment plan includes ";

    for (var med in meds) {
      summary +=
          "${med.name}, dosage ${med.dosage}, scheduled at ${med.time}. ";
    }

<<<<<<< HEAD
    return summary;
=======
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
>>>>>>> feature/interactive_tour
  }

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

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
      body: uid == null
          ? _buildEmptyState()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('user_medications')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final List<UserMedicationModel> meds = snapshot.data!.docs
                    .map((doc) => UserMedicationModel.fromFirestore(doc))
                    .toList();

                return _buildGroupedTreatmentList(meds, context);
              },
            ),
    );
  }

  /// 🔥 GROUPING BY MONTH (based on endDate)
  Widget _buildGroupedTreatmentList(
      List<UserMedicationModel> meds, BuildContext context) {
    Map<String, List<UserMedicationModel>> groups = {};

    for (var med in meds) {
      String monthKey =
          DateFormat('MMMM yyyy').format(med.endDate ?? med.startDate);

      groups.putIfAbsent(monthKey, () => []);
      groups[monthKey]!.add(med);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: groups.keys.length,
      itemBuilder: (context, index) {
        String month = groups.keys.elementAt(index);
        List<UserMedicationModel> medsInMonth = groups[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                month,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.iconGrey,
                ),
              ),
            ),
            ...medsInMonth
                .map((med) => _buildTreatmentCard(med, context))
                .toList(),
          ],
        );
      },
    );
  }

  /// 🔥 CARD WITH STOCK + REFILL
  Widget _buildTreatmentCard(UserMedicationModel med, BuildContext context) {
    final DateTime today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final DateTime endDateOnly = DateTime(
        (med.endDate ?? med.startDate).year,
        (med.endDate ?? med.startDate).month,
        (med.endDate ?? med.startDate).day);

    bool isDatePassed = today.isAfter(endDateOnly);

    final bool isActive = !isDatePassed && med.isActive;

    final bool isLowStock = med.currentStock <= med.lowStockThresholdDays;

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
            child: Icon(Icons.access_time_filled, color: AppColors.primaryBlue),
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
                  "Times: ${med.intakeTimes.join(", ")}",
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                /// 🔥 STOCK DISPLAY
                Text(
                  "Stock left: ${med.currentStock}",
                  style: TextStyle(
                    color: isLowStock ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (isLowStock)
                  Text(
                    "Low stock — please refill",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),

                SizedBox(height: 6),

                /// 🔥 REFILL BUTTON
                ElevatedButton(
                  onPressed: () => _showRefillDialog(context, med),
                  child: Text("Refill"),
                ),
              ],
            ),
          ),
          _buildStatusBadge(isActive),
        ],
      ),
    );
  }

  /// 🔥 REFILL DIALOG
  void _showRefillDialog(BuildContext context, UserMedicationModel med) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Refill Medication"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Enter new quantity",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final int? newAmount = int.tryParse(controller.text);

                if (newAmount == null || newAmount <= 0) return;

                await FirebaseFirestore.instance
                    .collection('user_medications')
                    .doc(med.id)
                    .update({
                  'currentStock': FieldValue.increment(newAmount),
                  'initialStock': med.currentStock + newAmount,
                });

                Navigator.pop(context);
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Text(
        isActive ? "Active" : "Finished",
        style: TextStyle(
          color: isActive ? Colors.green : Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            "No active treatment plans",
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Text(
              "Your scheduled medications will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}
