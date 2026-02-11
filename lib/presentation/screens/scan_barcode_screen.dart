import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../utils/app_colors.dart';
import 'treatment_duration_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanBarcodeScreen extends StatefulWidget {
  @override
  _ScanBarcodeScreenState createState() => _ScanBarcodeScreenState();
}

class _ScanBarcodeScreenState extends State<ScanBarcodeScreen> {
  final MobileScannerController nameController = MobileScannerController();
  final MobileScannerController controller = MobileScannerController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isScanning = true;
  bool isTorchOn = false;

  // Placeholder ID until you add Firebase Auth
  final String currentUserId = "5E4oT7RrhVZyN1RYMDZEQVMzuI13";

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // --- FIREBASE LOGIC ---

  Future<void> _fetchAndShowData(String barcode) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    _logScan(barcode);

    try {
      // Use .where() to search for the barcode field inside any document
      QuerySnapshot querySnapshot = await _firestore
          .collection('product')
          .where('barcode', isEqualTo: barcode)
          .limit(1) // Optimization: stop searching after the first match
          .get();

      if (!mounted) return;
      Navigator.pop(context);

      // Check if the query returned any documents
      if (querySnapshot.docs.isNotEmpty) {
        // Get the data from the first document found
        var doc = querySnapshot.docs.first;
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        String name = data['naam'] ?? "Naam onbekend";
        String dosage = data['dosering'] ?? "Geen dosering info";

        _logSearchHistory(barcode);
        _showResultSheet(barcode, name, dosage, isFound: true);
      } else {
        _showResultSheet(
          barcode,
          "Niet Gevonden",
          "Dit product staat nog niet in de database van MediMind.",
          isFound: false,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showResultSheet(barcode, "Fout", "Database error: $e", isFound: false);
    }
  }

  Future<void> _logScan(String barcode) async {
    try {
      await _firestore.collection('scan_logs').add({
        "gebruikerId": currentUserId,
        "barcode": barcode,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Log failed: $e");
    }
  }

  Future<void> _logSearchHistory(String barcode) async {
    try {
      await _firestore.collection('search_history').add({
        "gebruikerId": currentUserId,
        "barcode": barcode,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("History failed: $e");
    }
  }

  // --- UI COMPONENTS ---

  void _showResultSheet(String code, String title, String subtitle,
      {required bool isFound}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.6,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(25),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                isFound ? "PRODUCT GEVONDEN" : "ONBEKEND PRODUCT",
                style: TextStyle(
                  color: isFound ? Colors.green[800] : Colors.red[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text("Barcode: $code",
                  style: const TextStyle(color: Colors.grey)),
              const Divider(height: 40),
              Text(subtitle, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: isFound ? Colors.blue : Colors.grey,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => isScanning = true);
                },
                child: const Text("VOLGENDE SCANNEN",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MediMind Scanner"),
        actions: [
          IconButton(
            icon: Icon(isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              controller.toggleTorch();
              setState(() => isTorchOn = !isTorchOn);
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          if (isScanning && capture.barcodes.isNotEmpty) {
            final code = capture.barcodes.first.rawValue;
            if (code != null) {
              setState(() => isScanning = false);
              _fetchAndShowData(code);
            }
          }
        },
      ),
    );
  }
}
