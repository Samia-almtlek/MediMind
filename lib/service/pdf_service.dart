import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:medimind/domain/models/medication.dart';

class PdfService {
  static Future<void> generateHealthReport(
    List<Medication> medications, {
    List<String> faqQuestions = const [],
    List<String> doctorReferralInsights = const [],
    DateTime? reportMonth,
  }) async {
    final pdf = pw.Document();
    final user = FirebaseAuth.instance.currentUser;
    final medicalBox = Hive.box('medical_id_data');
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

    // Data from Medical ID
    final bloodType = medicalBox.get('bloodType', defaultValue: 'Unknown');
    final allergies =
        List<String>.from(medicalBox.get('allergies', defaultValue: []));
    final contactName = medicalBox.get('contactName', defaultValue: 'Not set');
    final contactPhone = medicalBox.get('phone', defaultValue: 'Not set');

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
          _buildPatientInfo(user, bloodType, allergies),
          pw.SizedBox(height: 20),
          pw.Text("Current Medication Plan",
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.blueGrey700),
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
          _buildAdherenceCard(
            monthLabel: formattedMonth,
            rate: adherenceRate,
            taken: totalTaken,
            scheduled: totalScheduled,
          ),
          pw.SizedBox(height: 15),
          _buildWeeklyTakenChart(
              monthLabel: formattedMonth, weeklyTaken: weeklyTaken),
          pw.SizedBox(height: 25),
          _buildMonthlyTakenTable(
              monthLabel: formattedMonth, monthlyTakenByMed: monthlyTakenByMed),
          pw.SizedBox(height: 24),
          _buildFAQSection(faqQuestions),
          pw.SizedBox(height: 20),
          _buildDoctorReferralSection(doctorReferralInsights),
          pw.SizedBox(height: 20),
          _buildEmergencyFooter(contactName, contactPhone),
        ],
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<_DoseStats> _computeDoseStatsFromLogs({
    required List<Medication> medications,
    required DateTime monthRef,
  }) async {
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
      totalScheduled += scheduledFromLogs;

      int takenCountForMedication = 0;

      for (final doseDoc in scheduledSnapshot.docs) {
        final data = doseDoc.data();
        if (data['status'] != 'taken') continue;

        takenCountForMedication++;
        totalTaken++;

        final plannedTs = data['geplandeTijd'];
        if (plannedTs is Timestamp) {
          final plannedDate = plannedTs.toDate();
          final week = ((plannedDate.day - 1) ~/ 7) + 1;
          weeklyTaken[week] = (weeklyTaken[week] ?? 0) + 1;
        }
      }

      if (scheduledFromLogs == 0) {
        final activeDays = _activeDaysInRange(
          med.startDate,
          med.endDate,
          monthStart,
          monthEndInclusive,
        );
        final fallbackScheduled = activeDays * frequencyPerDay;

        final monthCompletedDates = med.completedDates
            .where((d) => d.year == monthRef.year && d.month == monthRef.month)
            .toList();
        final fallbackTaken = monthCompletedDates.length * frequencyPerDay;

        totalScheduled += fallbackScheduled;
        takenCountForMedication += fallbackTaken;
        totalTaken += fallbackTaken;

        for (final date in monthCompletedDates) {
          final week = ((date.day - 1) ~/ 7) + 1;
          weeklyTaken[week] = (weeklyTaken[week] ?? 0) + frequencyPerDay;
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

  static int _activeDaysInRange(DateTime medStart, DateTime medEnd,
      DateTime rangeStart, DateTime rangeEnd) {
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
      'December'
    ];
    return months[month - 1];
  }

  static pw.Widget _buildHeader(String date) {
    return pw.Column(children: [
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text("MediMind Health Report",
            style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey800)),
        pw.Text("Date: $date",
            style: const pw.TextStyle(color: PdfColors.grey)),
      ]),
      pw.Divider(thickness: 1.5, color: PdfColors.blueGrey),
      pw.SizedBox(height: 10),
    ]);
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
    );
  }

  static pw.Widget _buildPatientInfo(
      User? user, String bloodType, List<String> allergies) {
    return pw
        .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text("Patient Information",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      pw.Bullet(text: "Name: ${user?.displayName ?? 'User'}"),
      pw.Bullet(text: "Email: ${user?.email ?? 'N/A'}"),
      pw.Bullet(text: "Blood Type: $bloodType"),
      pw.SizedBox(height: 6),
      pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
            color: PdfColors.red50, borderRadius: pw.BorderRadius.circular(5)),
        child: pw.Text(
            "Allergies: ${allergies.isEmpty ? "None" : allergies.join(", ")}",
            style: const pw.TextStyle(color: PdfColors.red900, fontSize: 10)),
      ),
    ]);
  }

  static pw.Widget _buildAdherenceCard(
      {required String monthLabel,
      required double rate,
      required int taken,
      required int scheduled}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
          color: PdfColors.blueGrey50,
          borderRadius: pw.BorderRadius.circular(10)),
      child: pw.Row(children: [
        pw.Expanded(
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
              pw.Text('Adherence - $monthLabel',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 13)),
              pw.Text('Doses taken: $taken'),
              pw.Text('Doses scheduled: $scheduled'),
            ])),
        pw.Text('${(rate * 100).toStringAsFixed(1)}%',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 26,
                color: PdfColors.blueGrey800)),
      ]),
    );
  }

  static pw.Widget _buildWeeklyTakenChart(
      {required String monthLabel, required Map<int, int> weeklyTaken}) {
    final values = weeklyTaken.values.toList();
    final maxValue = values.isEmpty
        ? 1
        : values.reduce((a, b) => a > b ? a : b).clamp(1, 1000000);
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Weekly intake - $monthLabel',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: List.generate(5, (index) {
              final week = index + 1;
              final value = weeklyTaken[week] ?? 0;
              final height = (value / maxValue) * 50.0;
              return pw.Column(children: [
                pw.Text('$value', style: const pw.TextStyle(fontSize: 8)),
                pw.Container(
                    width: 20,
                    height: height < 2 ? 2 : height,
                    color: PdfColors.blueGrey700),
                pw.Text('W$week', style: const pw.TextStyle(fontSize: 8)),
              ]);
            }),
          ),
        ]);
  }

  static pw.Widget _buildMonthlyTakenTable(
      {required String monthLabel,
      required Map<String, int> monthlyTakenByMed}) {
    final rows = monthlyTakenByMed.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return pw
        .Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Detailed intake $monthLabel',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold, color: PdfColors.white),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
        headers: ['Medication', 'Doses Taken'],
        data: rows.isEmpty
            ? [
                ['No intake recorded', '0']
              ]
            : rows.map((e) => [e.key, e.value.toString()]).toList(),
      ),
    ]);
  }

  static pw.Widget _buildFAQSection(List<String> faqQuestions) {
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Recent Chatbot Inquiries',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 6),
          if (faqQuestions.isEmpty)
            pw.Bullet(text: 'No recorded questions.')
          else
            ...faqQuestions.take(5).map((q) => pw.Bullet(text: q)),
        ]);
  }

  static pw.Widget _buildDoctorReferralSection(List<String> insights) {
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('AI Medical Escalations',
              style:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 6),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                border: pw.Border.all(color: PdfColors.orange200)),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (insights.isEmpty)
                    pw.Text('No doctor-referral flags raised.',
                        style: const pw.TextStyle(fontSize: 10))
                  else
                    ...insights.take(3).map((item) => pw.Bullet(text: item)),
                ]),
          ),
        ]);
  }

  static pw.Widget _buildEmergencyFooter(String name, String phone) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(10)),
      child: pw
          .Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text("Emergency Contact: $name",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.Text("Phone: $phone",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      ]),
    );
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
