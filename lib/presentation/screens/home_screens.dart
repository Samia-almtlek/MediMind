import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../domain/entities/dose_log_entity.dart';
import '../../data/models/dose_log_model.dart';
import '../../data/repositories_impl/dose_log_repository_impl.dart';
import '../../service/database/firestore_service.dart';
import '../../core/widgets/speaker_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selectedDate = DateTime.now();
  DateTime today = DateTime.now();

  List<DoseLogEntity> allDoses = [];

  final ScrollController _scrollController =
      ScrollController(initialScrollOffset: 500 * 68.0 - 150);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _doseSubscription;

  @override
  void initState() {
    super.initState();
    _loadDoseStream();
  }

  void _loadDoseStream() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    _doseSubscription = FirebaseFirestore.instance
        .collectionGroup('dose_logs')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      final tempList = snapshot.docs
          .where((doc) => doc.data() != null)
          .map((doc) => DoseLogModel.fromFirestore(doc))
          .toList();

      setState(() {
        allDoses = tempList;
      });
    });
  }

  @override
  void dispose() {
    _doseSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

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

  List<DoseLogEntity> _getDosesForSelectedDate() {
    return allDoses.where((dose) {
      return DateUtils.isSameDay(dose.geplandeTijd, selectedDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dosesForDay = _getDosesForSelectedDate();

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          "Today",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              _getMonthName(selectedDate),
              style: TextStyle(
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: dosesForDay.isEmpty
                ? Center(
                    child: Text(
                      "No medication scheduled for this day.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : _buildDoseList(dosesForDay),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    return Container(
      height: 100,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          DateTime dateToShow = today.add(Duration(days: index - 500));

          bool isSelected = DateUtils.isSameDay(dateToShow, selectedDate);
          bool isToday = DateUtils.isSameDay(dateToShow, today);

          List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

          String dayName = days[dateToShow.weekday - 1];

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = dateToShow;
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
                  Text(dayName,
                      style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12)),
                  Text("${dateToShow.day}",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoseList(List<DoseLogEntity> doses) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: doses.length,
      itemBuilder: (context, index) {
        final dose = doses[index];

        String formattedTime =
            "${dose.geplandeTijd.hour.toString().padLeft(2, '0')}:"
            "${dose.geplandeTijd.minute.toString().padLeft(2, '0')}";

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightTeal.withOpacity(0.4),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(formattedTime,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue)),
                  Text("Scheduled",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              SizedBox(width: 20),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('user_medications')
                      .doc(dose.medicatieId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Text("Loading...");
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return Text(
                        "Deleted medication",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      );
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>;

                    return Text(
                      data['name'] ?? "Unknown",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: dose.status == 'taken',
                  activeColor: AppColors.primaryBlue,
                  onChanged: (value) async {
                    final repository =
                        DoseLogRepositoryImpl(FirestoreService());

                    if (value == true) {
                      await repository.markAsTaken(dose.medicatieId, dose.id);
                    } else {
                      await repository.markAsPending(dose.medicatieId, dose.id);
                    }
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
