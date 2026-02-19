import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

class PdfService {
  static Future<void> generateHealthReport(List<Map<String, dynamic>> medications) async {
    final pdf = pw.Document();
    final user = FirebaseAuth.instance.currentUser;
    final medicalBox = Hive.box('medical_id_data');

    // take data of medical id screen
    final bloodType = medicalBox.get('bloodType', defaultValue: 'Unknown');
    final allergies = List<String>.from(medicalBox.get('allergies', defaultValue: []));
    final contactName = medicalBox.get('contactName', defaultValue: 'Not set');
    final contactPhone = medicalBox.get('phone', defaultValue: 'Not set');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("MediMind Health Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
              pw.Text("Date: 19/02/2026", style: const pw.TextStyle(color: PdfColors.grey)),
            ],
          ),
          pw.Divider(thickness: 2, color: PdfColors.blueGrey),
          pw.SizedBox(height: 20),

          // Patiënt Informatie
          pw.Text("Patient Information", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Bullet(text: "Name: ${user?.displayName ?? 'User'}"),
          pw.Bullet(text: "Email: ${user?.email ?? 'N/A'}"),
          pw.Bullet(text: "Blood Type: $bloodType"),
          pw.SizedBox(height: 20),

          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(color: PdfColors.red100, borderRadius: pw.BorderRadius.circular(10)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Allergies & Risks", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                pw.Text(allergies.isEmpty ? "No known allergies" : allergies.join(", ")),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Med Tabel
          pw.Text("Current Medication Stock", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey700),
            headers: ['Medication', 'Dosage', 'Stock Level'],
            data: medications.map((m) => [
              m['name'],
              m['dosage'],
              "${m['currentStock']} / ${m['maxStock']}"
            ]).toList(),
          ),

          pw.SizedBox(height: 30),
          
          // Emergency Contact
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(10)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Emergency Contact Info", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text("Contact Name: $contactName"),
                pw.Text("Phone: $contactPhone"),
              ],
            ),
          ),
        ],
      ),
    );

    // this opens the preview 
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}