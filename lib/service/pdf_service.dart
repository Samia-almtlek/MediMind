import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medimind/domain/models/medication.dart';

class PdfService {
  static const PdfColor _primaryColor = PdfColors.blueGrey700;
  static const PdfColor _sectionBg = PdfColors.blueGrey50;

  static Future<void> generateHealthReport(
    List<Medication> medications, {
    List<String> faqQuestions = const [],
    List<String> doctorReferralInsights = const [],
    DateTime? reportMonth,
  }) async {
    final pdf = pw.Document();
    final user = FirebaseAuth.instance.currentUser;
    final medicalBox = Hive.box('medical_id_data');
    final medicalData = await _loadMedicalIdData(user, medicalBox);
    final stockData = await _loadStockDataFromFirestore(medications);

    final now = DateTime.now();
    final monthRef = reportMonth ?? now;
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final formattedMonth = '${_monthName(monthRef.month)} ${monthRef.year}';

    final doseStats = await _computeDoseStatsFromLogs(
      medications: medications,
      monthRef: monthRef,
    );

    final totalTaken = doseStats.totalTaken;
    final totalScheduled = doseStats.totalScheduled;
    final monthlyTakenByMed = doseStats.monthlyTakenByMed;
    final weeklyTaken = doseStats.weeklyTaken;

    final adherenceRate = totalScheduled > 0
        ? (totalTaken / totalScheduled).clamp(0.0, 1.0)
        : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Column(
          children: [
            _buildHeader(formattedDate),
            pw.Divider(thickness: 1.5, color: PdfColors.blueGrey),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (context) => [
          _buildPatientInfo(user, medicalData.bloodType, medicalData.allergies),
          pw.SizedBox(height: 18),
          _buildSectionTitle("Current Medication Plan"),
          pw.SizedBox(height: 10),
          _buildDataTable(
            headers: ['Medication', 'Dosage', 'Frequency'],
            data: medications.isEmpty
                ? [
                    ['No medication data found', '-', '-'],
                  ]
                : medications
                    .map((m) => [m.name, m.dosage, m.frequency])
                    .toList(),
          ),
          pw.SizedBox(height: 24),
          _buildSectionTitle("Medication Cabinet (Stock)"),
          pw.SizedBox(height: 8),
          _buildDataTable(
            headers: ['Medication', 'Remaining Stock', 'Refill Alert'],
            data: stockData.isEmpty
                ? [
                    ['No stock data found', '-', '-']
                  ]
                : stockData.map((s) {
                    final current = s['currentStock'] ?? 0;
                    final min = s['minStock'] ?? 0;
                    return [
                      (s['name'] ?? 'Unknown').toString(),
                      "$current units",
                      current <= min ? "REFILL NEEDED" : "OK"
                    ];
                  }).toList(),
          ),
          pw.SizedBox(height: 25),
          _buildAdherenceCard(
            monthLabel: formattedMonth,
            rate: adherenceRate,
            taken: totalTaken,
            scheduled: totalScheduled,
          ),
          pw.SizedBox(height: 15),
          _buildWeeklyTakenChart(
            monthLabel: formattedMonth,
            weeklyTaken: weeklyTaken,
          ),
          pw.SizedBox(height: 22),
          _buildMonthlyTakenTable(
            monthLabel: formattedMonth,
            monthlyTakenByMed: monthlyTakenByMed,
          ),
          pw.SizedBox(height: 20),
          ..._buildFAQSection(faqQuestions),
          pw.SizedBox(height: 20),
          ..._buildDoctorReferralSection(doctorReferralInsights),
          pw.SizedBox(height: 20),
          _buildEmergencyFooter(
            name: medicalData.contactName,
            relation: medicalData.contactRelation,
            email: medicalData.contactEmail,
          ),
        ],
      ),
    );

    // this opens the preview
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<_DoseStats> _computeDoseStatsFromLogs({
    required List<Medication> medications,
    required DateTime monthRef,
  }) async {
    final now = DateTime.now();
    final nowDateOnly = DateTime(now.year, now.month, now.day);
    final isCurrentMonth = monthRef.year == nowDateOnly.year &&
        monthRef.month == nowDateOnly.month;

    final monthStart = DateTime(monthRef.year, monthRef.month, 1);
    final monthEndInclusive = DateTime(monthRef.year, monthRef.month + 1, 0);
    final monthEndExclusive = DateTime(monthRef.year, monthRef.month + 1, 1);
    final startTs = Timestamp.fromDate(monthStart);
    final endTs = Timestamp.fromDate(monthEndExclusive);

    int totalTaken = 0;
    int totalScheduled = 0;
    final Map<String, int> monthlyTakenByMed = {};
    final Map<int, int> weeklyTaken = {
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
    };

    for (final med in medications) {
      if (med.id.isEmpty) continue;

      final frequencyPerDay = _parseFrequencyPerDay(med.frequency);

      final scheduledSnapshot = await FirebaseFirestore.instance
          .collection('user_medications')
          .doc(med.id)
          .collection('dose_logs')
          .where('geplandeTijd', isGreaterThanOrEqualTo: startTs)
          .where('geplandeTijd', isLessThan: endTs)
          .get();

      final scheduledFromLogs = scheduledSnapshot.docs.length;

      int takenCountForMedication = 0;

      for (final doseDoc in scheduledSnapshot.docs) {
        final data = doseDoc.data();
        final plannedTs = data['geplandeTijd'];
        final status = (data['status'] as String?) ?? '';

        DateTime? plannedDate;
        if (plannedTs is Timestamp) {
          final dt = plannedTs.toDate();
          plannedDate = DateTime(
              dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
        }

        final isDueInReport = plannedDate == null
            ? true
            : (!isCurrentMonth || !plannedDate.isAfter(now));

        if (!isDueInReport) {
          continue;
        }

        totalScheduled++;

        final bool isTakenByRule = plannedDate != null
            ? (!plannedDate.isAfter(now) || status == 'taken')
            : status == 'taken';

        if (!isTakenByRule) continue;

        takenCountForMedication++;
        totalTaken++;

        if (plannedDate != null) {
          final week = ((plannedDate.day - 1) ~/ 7) + 1;
          weeklyTaken[week] = (weeklyTaken[week] ?? 0) + 1;
        }
      }

      if (scheduledFromLogs == 0) {
        final dueRangeEnd = isCurrentMonth
            ? (nowDateOnly.isBefore(monthEndInclusive)
                ? nowDateOnly
                : monthEndInclusive)
            : monthEndInclusive;

        final dueDays = _activeDaysInRange(
          med.startDate,
          med.endDate,
          monthStart,
          dueRangeEnd,
        );
        final fallbackScheduled = dueDays * frequencyPerDay;
        final fallbackTaken = fallbackScheduled;

        totalScheduled += fallbackScheduled;
        takenCountForMedication += fallbackTaken;
        totalTaken += fallbackTaken;

        if (dueDays > 0) {
          final startDay = med.startDate.isAfter(monthStart)
              ? DateTime(
                  med.startDate.year,
                  med.startDate.month,
                  med.startDate.day,
                )
              : monthStart;

          for (int i = 0; i < dueDays; i++) {
            final date = startDay.add(Duration(days: i));
            final week = ((date.day - 1) ~/ 7) + 1;
            weeklyTaken[week] = (weeklyTaken[week] ?? 0) + frequencyPerDay;
          }
        }
      }

      monthlyTakenByMed[med.name] =
          (monthlyTakenByMed[med.name] ?? 0) + takenCountForMedication;
    }

    return _DoseStats(
      totalTaken: totalTaken,
      totalScheduled: totalScheduled,
      monthlyTakenByMed: monthlyTakenByMed,
      weeklyTaken: weeklyTaken,
    );
  }

  static int _parseFrequencyPerDay(String frequency) {
    final match = RegExp(r'(\d+)').firstMatch(frequency);
    return int.tryParse(match?.group(1) ?? '1') ?? 1;
  }

  static int _activeDaysInRange(
    DateTime medStart,
    DateTime medEnd,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final start = medStart.isAfter(rangeStart) ? medStart : rangeStart;
    final end = medEnd.isBefore(rangeEnd) ? medEnd : rangeEnd;
    if (end.isBefore(start)) return 0;
    return end.difference(DateTime(start.year, start.month, start.day)).inDays +
        1;
  }

  static Future<List<Map<String, dynamic>>> _loadStockDataFromFirestore(
      List<Medication> medications) async {
    final List<Map<String, dynamic>> rows = [];

    for (final med in medications) {
      if (med.id.isEmpty) continue;

      final doc = await FirebaseFirestore.instance
          .collection('user_medications')
          .doc(med.id)
          .get();

      final data = doc.data() ?? const <String, dynamic>{};
      final current = data['currentStock'];
      final min = data['minStock'];

      final currentStock = current is num ? current.toInt() : 0;
      final minStock = min is num ? min.toInt() : 0;

      rows.add({
        'name': med.name,
        'currentStock': currentStock,
        'minStock': minStock,
      });
    }

    return rows;
  }

  static Future<_MedicalIdReportData> _loadMedicalIdData(
    User? user,
    Box medicalBox,
  ) async {
    String bloodType = _firstNonEmptyString([
      medicalBox.get('bloodType')?.toString(),
      medicalBox.get('blood_type')?.toString(),
      medicalBox.get('bloodGroup')?.toString(),
      medicalBox.get('blood_group')?.toString(),
    ], fallback: 'Unknown');

    List<String> allergies = _toStringList(
      medicalBox.get('allergies') ?? medicalBox.get('allergyList') ?? [],
    );

    String contactName = _firstNonEmptyString([
      medicalBox.get('contactName')?.toString(),
      medicalBox.get('emergencyContactName')?.toString(),
      medicalBox.get('caregiverName')?.toString(),
      medicalBox.get('primaryContactName')?.toString(),
    ], fallback: 'Not set');

    String contactEmail = _firstNonEmptyString([
      medicalBox.get('contactEmail')?.toString(),
      medicalBox.get('emergencyContactEmail')?.toString(),
      medicalBox.get('caregiverEmail')?.toString(),
    ], fallback: 'Not set');

    String contactRelation = _firstNonEmptyString([
      medicalBox.get('relation')?.toString(),
      medicalBox.get('contactRelation')?.toString(),
      medicalBox.get('emergencyContactRelation')?.toString(),
      medicalBox.get('caregiverRelation')?.toString(),
    ], fallback: 'Not set');

    if (user != null) {
      try {
        final medicalDoc = await FirebaseFirestore.instance
            .collection('medical_ids')
            .doc(user.uid)
            .get();

        if (medicalDoc.exists) {
          final data = medicalDoc.data() ?? const <String, dynamic>{};
          bloodType = _firstNonEmptyString([
            data['bloodType']?.toString(),
            data['blood_type']?.toString(),
            bloodType,
          ], fallback: 'Unknown');

          final remoteAllergies = _toStringList(
            data['allergies'] ?? data['allergyList'] ?? allergies,
          );
          allergies = remoteAllergies;
        }

        final caregiverDoc = await FirebaseFirestore.instance
            .collection('medical_ids')
            .doc(user.uid)
            .collection('caregivers')
            .doc('primary_contact')
            .get();

        if (caregiverDoc.exists) {
          final cData = caregiverDoc.data() ?? const <String, dynamic>{};
          contactName = _firstNonEmptyString([
            cData['name']?.toString(),
            contactName,
          ], fallback: 'Not set');
          contactEmail = _firstNonEmptyString([
            cData['email']?.toString(),
            contactEmail,
          ], fallback: 'Not set');
          contactRelation = _firstNonEmptyString([
            cData['relation']?.toString(),
            contactRelation,
          ], fallback: 'Not set');
        }
      } catch (_) {
        // Keep Hive fallback values when Firestore read fails.
      }
    }

    return _MedicalIdReportData(
      bloodType: bloodType,
      allergies: allergies,
      contactName: contactName,
      contactEmail: contactEmail,
      contactRelation: contactRelation,
    );
  }

  static String _firstNonEmptyString(
    List<String?> candidates, {
    required String fallback,
  }) {
    for (final value in candidates) {
      final text = (value ?? '').trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  static pw.Widget _buildHeader(String date) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          "MediMind Health Report",
          style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
          ),
        ),
        pw.Text("Date: $date",
            style: const pw.TextStyle(color: PdfColors.grey)),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _sectionBg,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey900,
        ),
      ),
    );
  }

  static pw.Widget _buildDataTable({
    required List<String> headers,
    required List<List<String>> data,
  }) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.black),
      headerDecoration: const pw.BoxDecoration(color: _primaryColor),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
      border: pw.TableBorder.all(color: PdfColors.blueGrey200, width: 0.6),
      headers: headers,
      data: data,
    );
  }

  static pw.Widget _buildPatientInfo(
    User? user,
    String bloodType,
    List<String> allergies,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Patient Information"),
        pw.SizedBox(height: 8),
        pw.Bullet(text: "Name: ${user?.displayName ?? 'User'}"),
        pw.Bullet(text: "Email: ${user?.email ?? 'N/A'}"),
        pw.Bullet(text: "Blood Type: $bloodType"),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.red50,
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Text(
            "Allergies: ${allergies.isEmpty ? "None" : allergies.join(", ")}",
            style: const pw.TextStyle(color: PdfColors.red900, fontSize: 10),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildEmergencyFooter({
    required String name,
    required String relation,
    required String email,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blueGrey300),
        borderRadius: pw.BorderRadius.circular(10),
        color: PdfColors.blueGrey50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Emergency Contact Info",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text("Name: $name"),
          pw.Text("Relation: $relation"),
          pw.Text("Email: $email"),
        ],
      ),
    );
  }

  static pw.Widget _buildAdherenceCard({
    required String monthLabel,
    required double rate,
    required int taken,
    required int scheduled,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Medication adherence - $monthLabel',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 13),
                ),
                pw.SizedBox(height: 6),
                pw.Text('Doses taken: $taken'),
                pw.Text('Doses scheduled: $scheduled'),
              ],
            ),
          ),
          pw.Text(
            '${(rate * 100).toStringAsFixed(1)}%',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 26,
              color: PdfColors.blueGrey800,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMonthlyTakenTable({
    required String monthLabel,
    required Map<String, int> monthlyTakenByMed,
  }) {
    final rows = monthlyTakenByMed.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Taken medications in $monthLabel'),
        pw.SizedBox(height: 8),
        _buildDataTable(
          headers: ['Medication', 'Taken doses'],
          data: rows.isEmpty
              ? [
                  ['No intake recorded this month', '0'],
                ]
              : rows
                  .map((entry) => [entry.key, entry.value.toString()])
                  .toList(),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildFAQSection(List<String> faqQuestions) {
    if (faqQuestions.isEmpty) {
      return [
        _buildSectionTitle('Frequently asked questions by the user'),
        pw.SizedBox(height: 8),
        pw.Bullet(text: 'No chatbot questions found for this user yet.'),
      ];
    }

    final rows = faqQuestions
        .asMap()
        .entries
        .map((entry) => ['Q${entry.key + 1}', entry.value])
        .toList();

    return [
      _buildSectionTitle('Frequently asked questions by the user'),
      pw.SizedBox(height: 8),
      _buildDataTable(headers: ['#', 'Question'], data: rows),
    ];
  }

  static pw.Widget _buildWeeklyTakenChart({
    required String monthLabel,
    required Map<int, int> weeklyTaken,
  }) {
    final values = weeklyTaken.values.toList();
    final maxValue = values.isEmpty
        ? 1
        : values.reduce((a, b) => a > b ? a : b).clamp(1, 1000000);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Weekly intake stats - $monthLabel'),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            final week = index + 1;
            final value = weeklyTaken[week] ?? 0;
            final height = (value / maxValue) * 58.0;
            return pw.Column(
              children: [
                pw.Text('$value', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 4),
                pw.Container(
                  width: 22,
                  height: height < 3 ? 3 : height,
                  color: _primaryColor,
                ),
                pw.SizedBox(height: 4),
                pw.Text('W$week', style: const pw.TextStyle(fontSize: 9)),
              ],
            );
          }),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildDoctorReferralSection(List<String> insights) {
    final rows = insights
        .asMap()
        .entries
        .map((entry) => ['${entry.key + 1}', entry.value])
        .toList();

    return [
      _buildSectionTitle('AI advised to consult a doctor'),
      pw.SizedBox(height: 8),
      pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.orange50,
          border: pw.Border.all(color: PdfColors.orange200),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(
          'Escalation count: ${insights.length}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 8),
      rows.isEmpty
          ? pw.Text(
              'No doctor-referral AI answers found yet for this user.',
              style: const pw.TextStyle(fontSize: 10),
            )
          : _buildDataTable(headers: ['#', 'Insight'], data: rows),
    ];
  }
}

class _DoseStats {
  final int totalTaken;
  final int totalScheduled;
  final Map<String, int> monthlyTakenByMed;
  final Map<int, int> weeklyTaken;

  const _DoseStats({
    required this.totalTaken,
    required this.totalScheduled,
    required this.monthlyTakenByMed,
    required this.weeklyTaken,
  });
}

class _MedicalIdReportData {
  final String bloodType;
  final List<String> allergies;
  final String contactName;
  final String contactEmail;
  final String contactRelation;

  const _MedicalIdReportData({
    required this.bloodType,
    required this.allergies,
    required this.contactName,
    required this.contactEmail,
    required this.contactRelation,
  });
}
