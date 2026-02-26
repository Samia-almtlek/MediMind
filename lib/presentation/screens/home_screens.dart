import 'package:flutter/material.dart';
import 'dart:async';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/medication.dart';
import '../../utils/app_colors.dart';
import '../../utils/global_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medimind/service/pdf_service.dart';
import 'manual_input_screen.dart';

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
  List<TargetFocus> targets = [];
  final GlobalKey keyMenu = GlobalKey();
  final GlobalKey keyCalendar = GlobalKey();
  final GlobalKey keyCheckmark = GlobalKey();

  final ScrollController _scrollController = ScrollController(
    initialScrollOffset: 500 * 68.0 - 150,
  );
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _medicationsSubscription;

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

    Future.delayed(const Duration(milliseconds: 500), () {
      _checkFirstTime();
    });
  }

  void _loadInitialData() {
    _medicationsSubscription = FirebaseFirestore.instance
        .collection('user_medications')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        print(
            "Firestore Data: ${doc.data()}"); // Check your debug console for this!
      }
      if (!mounted) return;
      setState(() {
        userAddedMeds =
            snapshot.docs.map((doc) => Medication.fromFirestore(doc)).toList();
      });
    });
  }

  @override
  void dispose() {
    _medicationsSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('home_tour_seen') ?? false;
    if (!mounted || seen) return;
    showTutorial();
    await prefs.setBool('home_tour_seen', true);
  }

  void showTutorial() {
    if (!mounted) return;
    targets = [];

    targets.add(
      TargetFocus(
        identify: "Target Menu",
        keyTarget: keyMenu,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialCard(
                title: "Manage your meds",
                message: "Click here to delete, edit medications or export your medical data.",
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "Target Calendar",
        keyTarget: keyCalendar,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return _buildTutorialCard(
                title: "Pick a day",
                message:
                    "Use this horizontal calendar to navigate through your medication schedule.",
              );
            },
          ),
        ],
      ),
    );

    targets.add(
      TargetFocus(
        identify: "Target Checkmark",
        keyTarget: keyCheckmark,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return _buildTutorialCard(
                title: "Mark as taken",
                message:
                    "Check this box when you have taken your medication for the selected date.",
              );
            },
          ),
        ],
      ),
    );

    TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.primaryBlue,
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
      paddingFocus: 6,
      opacityShadow: 0.78,
      onFinish: () => print("Tour finished"),
    ).show(context: context);
  }

  Widget _buildTutorialCard({
    required String title,
    required String message,
  }) {
    return Container(
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
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 19,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
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

  Future<void> _deleteMedication(Medication med) async {
    if (med.id.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('user_medications')
        .doc(med.id)
        .delete();

    setState(() {
      userAddedMeds.removeWhere((item) => item.id == med.id);
    });
  }

  Future<List<Medication>> _loadUserMedicationsForReport(String uid) async {
    final snapshotByUser = await FirebaseFirestore.instance
        .collection('user_medications')
        .where('userId', isEqualTo: uid)
        .get();

    final snapshotLegacyNoUserId = await FirebaseFirestore.instance
        .collection('user_medications')
        .where('userId', isNull: true)
        .get();

    final mergedDocsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in snapshotByUser.docs) {
      mergedDocsById[doc.id] = doc;
    }
    for (final doc in snapshotLegacyNoUserId.docs) {
      mergedDocsById[doc.id] = doc;
    }

    return mergedDocsById.values.map((doc) => Medication.fromFirestore(doc)).toList();
  }

  Future<List<String>> _loadFaqQuestionsForReport(String uid) async {
    try {
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('chat_sessions')
          .where('userId', isEqualTo: uid)
          .get();

      final sessionIds = sessionsSnapshot.docs.map((doc) => doc.id).toList();
      if (sessionIds.isEmpty) return const [];

      final List<Map<String, dynamic>> questions = [];
      for (final sessionId in sessionIds.take(3)) {
        final msgSnapshot = await FirebaseFirestore.instance
            .collection('chat_messages')
            .where('sessionId', isEqualTo: sessionId)
            .where('sender', isEqualTo: 'user')
            .orderBy('timestamp', descending: true)
            .limit(2)
            .get();

        for (final doc in msgSnapshot.docs) {
          final data = doc.data();
          questions.add({
            'content': (data['content'] ?? '').toString(),
            'timestamp': data['timestamp'],
          });
        }
      }

      questions.sort((a, b) {
        final ta = a['timestamp'];
        final tb = b['timestamp'];
        if (ta is Timestamp && tb is Timestamp) {
          return tb.compareTo(ta);
        }
        return 0;
      });

      return questions
          .map((q) => q['content'] as String)
          .where((q) => q.trim().isNotEmpty)
          .toSet()
          .take(5)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> _loadDoctorReferralInsightsForReport(String uid) async {
    const referralKeywords = [
      'consult',
      'doctor',
      'physician',
      'medical professional',
      'seek medical advice',
      'contact your doctor',
      'ask your doctor',
      'see a doctor',
    ];

    try {
      final sessionsSnapshot = await FirebaseFirestore.instance
          .collection('chat_sessions')
          .where('userId', isEqualTo: uid)
          .get();

      final sessionIds = sessionsSnapshot.docs.map((doc) => doc.id).toList();
      if (sessionIds.isEmpty) return const [];

      final List<Map<String, dynamic>> candidateReplies = [];

      for (final sessionId in sessionIds.take(5)) {
        final msgSnapshot = await FirebaseFirestore.instance
            .collection('chat_messages')
            .where('sessionId', isEqualTo: sessionId)
            .where('sender', isEqualTo: 'bot')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get();

        for (final doc in msgSnapshot.docs) {
          final data = doc.data();
          final content = (data['content'] ?? '').toString();
          final lower = content.toLowerCase();
          final isReferral = referralKeywords.any(lower.contains);

          if (isReferral && content.trim().isNotEmpty) {
            candidateReplies.add({
              'content': content,
              'timestamp': data['timestamp'],
            });
          }
        }
      }

      candidateReplies.sort((a, b) {
        final ta = a['timestamp'];
        final tb = b['timestamp'];
        if (ta is Timestamp && tb is Timestamp) {
          return tb.compareTo(ta);
        }
        return 0;
      });

      return candidateReplies
          .map((entry) => entry['content'] as String)
          .toSet()
          .take(5)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _generateHealthReportFromHome() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to export your report.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final meds = await _loadUserMedicationsForReport(user.uid);
      final faqQuestions = await _loadFaqQuestionsForReport(user.uid);
      final doctorReferralInsights = await _loadDoctorReferralInsightsForReport(user.uid);

      await PdfService.generateHealthReport(
        meds,
        faqQuestions: faqQuestions,
        doctorReferralInsights: doctorReferralInsights,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _toggleMedicationCompletion(Medication med, bool isChecked) async {
    if (med.id.isEmpty) return;

    final targetDate = _normalizeDate(selectedDate);
    final updatedDates = List<DateTime>.from(med.completedDates);

    if (isChecked) {
      if (!updatedDates.any((d) => DateUtils.isSameDay(d, targetDate))) {
        updatedDates.add(targetDate);
      }
    } else {
      updatedDates.removeWhere((d) => DateUtils.isSameDay(d, targetDate));
    }

    setState(() {
      final sourceIndex = userAddedMeds.indexWhere((item) => item.id == med.id);
      if (sourceIndex != -1) {
        userAddedMeds[sourceIndex].completedDates
          ..clear()
          ..addAll(updatedDates);
      }
    });

    await FirebaseFirestore.instance
        .collection('user_medications')
        .doc(med.id)
        .update({
      'completedDates': updatedDates.map((d) => Timestamp.fromDate(_normalizeDate(d))).toList(),
    });
  }

  void _showMoreActions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Manage Medications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.lightTeal.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.lightTeal.withOpacity(0.8)),
              ),
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primaryBlue),
                title: const Text(
                  "Generate Health Report (PDF)",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text("Same export as Right of Access"),
                onTap: () async {
                  Navigator.pop(context);
                  await _generateHealthReportFromHome();
                },
              ),
            ),
            Flexible(
              child: userAddedMeds.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("No medications active", style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: userAddedMeds.length,
                      itemBuilder: (context, index) {
                        final med = userAddedMeds[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.grey.withOpacity(0.1)),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.medication_rounded, color: AppColors.primaryBlue),
                            title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(med.dosage),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ManualInputScreen(medicationToEdit: med),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                  onPressed: () => _confirmDeletion(med),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmDeletion(Medication med) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove Medication?"),
        content: Text("This will permanently delete ${med.name} from your schedule and database."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              await _deleteMedication(med);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text("${med.name} deleted"),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.black87,
                ),
              );
            },
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
          Container(
            key: keyMenu,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: AppColors.lightTeal.withOpacity(0.28),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.lightTeal),
            ),
            child: IconButton(
              tooltip: 'Manage medications',
              icon: const Icon(Icons.more_horiz, color: AppColors.primaryBlue),
              onPressed: _showMoreActions,
            ),
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

          _buildHorizontalCalendar(calendarTileKey: keyCalendar),

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
  Widget _buildHorizontalCalendar({Key? calendarTileKey}) {
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
              key: index == 500 ? calendarTileKey : null,
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
                  key: index == 0 ? keyCheckmark : null,
                  //check if the current date (at midnight) is in the completedDates list for this medication
                  value: med.completedDates
                      .any((d) => DateUtils.isSameDay(d, selectedDate)),
                  activeColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5)),
                  onChanged: (bool? value) async {
                    await _toggleMedicationCompletion(med, value ?? false);
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
