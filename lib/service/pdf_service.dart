import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final stockBox = Hive.box('medication_stock');
    final rawStockItems = stockBox.get('items', defaultValue: []);
    final stockData = (rawStockItems as List)
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();

    final now = DateTime.now();
    final monthRef = reportMonth ?? now;
    final monthStart = DateTime(monthRef.year, monthRef.month, 1);
    final monthEnd = DateTime(monthRef.year, monthRef.month + 1, 0);
    final formattedDate =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final formattedMonth = '${_monthName(monthRef.month)} ${monthRef.year}';

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
      final monthCompletedDates = med.completedDates
          .where((d) => d.year == monthRef.year && d.month == monthRef.month)
          .toList();
      final takenCount = monthCompletedDates.length;
      monthlyTakenByMed[med.name] =
          (monthlyTakenByMed[med.name] ?? 0) + takenCount;
      totalTaken += takenCount;

      for (final date in monthCompletedDates) {
        final week = ((date.day - 1) ~/ 7) + 1;
        weeklyTaken[week] = (weeklyTaken[week] ?? 0) + 1;
      }

      final frequencyPerDay = _parseFrequencyPerDay(med.frequency);
      final activeDays = _activeDaysInRange(
        med.startDate,
        med.endDate,
        monthStart,
        monthEnd,
      );
      totalScheduled += activeDays * frequencyPerDay;
    }

    final adherenceRate =
        totalScheduled > 0 ? (totalTaken / totalScheduled).clamp(0.0, 1.0) : 0.0;

    // take data of medical id screen
    final bloodType = medicalBox.get('bloodType', defaultValue: 'Unknown');
    final allergies = List<String>.from(medicalBox.get('allergies', defaultValue: []));
    final contactName = medicalBox.get('contactName', defaultValue: 'Not set');
    final contactPhone = medicalBox.get('phone', defaultValue: 'Not set');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(formattedDate),
          pw.Divider(thickness: 2, color: PdfColors.blueGrey),
          pw.SizedBox(height: 20),

          _buildPatientInfo(user, bloodType, allergies),
          pw.SizedBox(height: 20),

          // Med Tabel
          pw.Text("Current Medication Plan", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
            headers: ['Medication', 'Dosage', 'Frequency'],
            data: medications
                .map((m) => [m.name, m.dosage, m.frequency])
                .toList(),
          ),
          pw.SizedBox(height: 24),

          // Medication Stock
          pw.Text("Medication Cabinet (Stock)", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
            headers: ['Medication', 'Remaining Stock', 'Refill Alert'],
            data: stockData.isEmpty 
              ? [['No stock data found', '-', '-']]
              : stockData.map((s) {
                  final current = s['currentStock'] ?? 0;
                  final min = s['minStock'] ?? 0;
                  return [
                    s['name'] ?? 'Unknown',
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
          pw.SizedBox(height: 25),

          _buildMonthlyTakenTable(
            monthLabel: formattedMonth,
            monthlyTakenByMed: monthlyTakenByMed,
          ),
          pw.SizedBox(height: 24),

          _buildFAQSection(faqQuestions),
          pw.SizedBox(height: 20),
          _buildDoctorReferralSection(doctorReferralInsights),
          pw.SizedBox(height: 20),

          _buildEmergencyFooter(contactName, contactPhone),
        ],
      ),
    );

    // this opens the preview 
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
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
    return end.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
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
        pw.Text("Date: $date", style: const pw.TextStyle(color: PdfColors.grey)),
      ],
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
        pw.Text(
          "Patient Information",
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
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

  static pw.Widget _buildEmergencyFooter(String name, String phone) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            "Emergency Contact Info",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text("Contact: $name | Phone: $phone"),
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
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
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
        pw.Text(
          'Taken medications in $monthLabel',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
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

  static pw.Widget _buildFAQSection(List<String> faqQuestions) {
    final displayItems = faqQuestions.take(5).toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Frequently asked questions by the user',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        if (displayItems.isEmpty)
          pw.Bullet(text: 'No chatbot questions found for this user yet.')
        else
          ...displayItems.map((q) => pw.Bullet(text: q)),
      ],
    );
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
        pw.Text(
          'Weekly intake stats - $monthLabel',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
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
                  color: PdfColors.blueGrey700,
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

  static pw.Widget _buildDoctorReferralSection(List<String> insights) {
    final items = insights.take(5).toList();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'AI advised to consult a doctor',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.orange50,
            border: pw.Border.all(color: PdfColors.orange200),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Escalation count: ${items.length}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              if (items.isEmpty)
                pw.Text(
                  'No doctor-referral AI answers found yet for this user.',
                  style: const pw.TextStyle(fontSize: 10),
                )
              else
                ...items.map((item) => pw.Bullet(text: item)),
            ],
          ),
        ),
      ],
    );
  }
}