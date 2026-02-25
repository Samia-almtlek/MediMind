import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../utils/app_colors.dart';
import 'package:medimind/domain/models/medication.dart';

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
      message:
          'This page groups your medications by month and shows each planned intake time.',
      align: ContentAlign.bottom,
    ));

    if (_keyMonth.currentContext != null) {
      targets.add(_buildTarget(
        identify: 'schedule_month',
        key: _keyMonth,
        title: 'Monthly groups',
        message:
            'Each section represents a month to help you review your treatment timeline.',
        align: ContentAlign.bottom,
      ));
    }

    if (_keyCard.currentContext != null) {
      targets.add(_buildTarget(
        identify: 'schedule_card',
        key: _keyCard,
        title: 'Medication card',
        message:
            'Here you can see medication name, dosage, planned time, and status (Active/Finished).',
        align: ContentAlign.top,
      ));
    }

    TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.primaryBlue,
      opacityShadow: 0.78,
      textSkip: 'SKIP',
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
    }

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
      body: StreamBuilder<QuerySnapshot>(
        // Listen only to the current user's medications
        stream: FirebaseFirestore.instance
            .collection('user_medications')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Convert Firestore docs to Medication objects
          final List<Medication> rawMeds = snapshot.data!.docs
              .map((doc) => Medication.fromFirestore(doc))
              .toList();

          // Flatten the list (split multiple times into separate entries)
          final List<Medication> flattenedMeds =
              _getFlattenedMedicationList(rawMeds);

          // Group them by month for the UI
          final Map<String, List<Medication>> groupedMeds =
              _groupMedsByMonth(flattenedMeds);

          return _buildGroupedTreatmentList(groupedMeds);
        },
      ),
    );
  }

  List<Medication> _getFlattenedMedicationList(List<Medication> meds) {
    List<Medication> results = [];
    for (var med in meds) {
      // Logic matches TreatmentDurationScreen's storage format
      String timePart =
          med.instructions.split("Notes:")[0].replaceAll("Times: ", "").trim();
      List<String> allTimes = timePart
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (allTimes.isEmpty) {
        results.add(med);
      } else {
        for (String t in allTimes) {
          results.add(
            Medication(
              id: med.id,
              userId: med.userId,
              name: med.name,
              dosage: med.dosage,
              time: t,
              startDate: med.startDate,
              endDate: med.endDate,
              completedDoseIds: med.completedDoseIds,
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
    // Sort by date so months appear in order
    meds.sort((a, b) => b.endDate.compareTo(a.endDate));

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

    bool isActive = !todayDateOnly.isAfter(endDateOnly);

    // 1. Calculate Duration in days
    // We add 1 to include both the start and end days in the count
    final int durationDays = med.endDate.difference(med.startDate).inDays + 1;

    // 2. Format the Date Range (e.g., "Oct 12 - Oct 26, 2023")
    final String dateRange =
        "${DateFormat('MMM d').format(med.startDate)} - ${DateFormat('MMM d, yyyy').format(med.endDate)}";

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
      child: Column(
        // Changed to Column to allow for a multi-row layout if needed
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightTeal.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.medication, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      med.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Dosage: ${med.dosage}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(isActive),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Date Range and Time info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        dateRange,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: AppColors.primaryBlue),
                      const SizedBox(width: 6),
                      Text(
                        med.time,
                        style: const TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Duration Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$durationDays Days",
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        isActive ? "Active" : "Finished",
        style: TextStyle(
            color: isActive ? Colors.green : Colors.grey,
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
