import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../utils/app_colors.dart';
import '../../utils/global_data.dart';
import 'package:intl/intl.dart';
import '../../domain/models/medication.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final GlobalKey _keyTitle = GlobalKey();
  final GlobalKey _keyMonth = GlobalKey();
  final GlobalKey _keyCard = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTour();
    });
  }

  Future<void> _checkAndShowTour() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('schedule_tour_seen') ?? false;
    if (seen || !mounted) return;
    _showTutorial();
    await prefs.setBool('schedule_tour_seen', true);
  }

  void _showTutorial() {
    final targets = <TargetFocus>[];

    targets.add(_buildTarget(
      identify: 'schedule_title',
      key: _keyTitle,
      title: 'Treatment Plan',
      message: 'This page groups your medications by month and shows each planned intake time.',
      align: ContentAlign.bottom,
    ));

    if (_keyMonth.currentContext != null) {
      targets.add(_buildTarget(
        identify: 'schedule_month',
        key: _keyMonth,
        title: 'Monthly groups',
        message: 'Each section represents a month to help you review your treatment timeline.',
        align: ContentAlign.bottom,
      ));
    }

    if (_keyCard.currentContext != null) {
      targets.add(_buildTarget(
        identify: 'schedule_card',
        key: _keyCard,
        title: 'Medication card',
        message: 'Here you can see medication name, dosage, planned time, and status (Active/Finished).',
        align: ContentAlign.top,
      ));
    }

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
        title: Text(
          key: _keyTitle,
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
                key: index == 0 ? _keyMonth : null,
                month,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.iconGrey),
              ),
            ),
            ...medsInMonth.asMap().entries.map(
              (entry) => _buildTreatmentCard(
                entry.value,
                itemKey: (index == 0 && entry.key == 0) ? _keyCard : null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTreatmentCard(Medication med, {Key? itemKey}) {
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
      key: itemKey,
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
