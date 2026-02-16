import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

class DrugLoader {
  /// Loads drug names from a local JSON file
  /// and stores them in Hive.
  ///
  /// ✅ Runs ONLY ONCE
  /// ✅ Uses batch insert (putAll) for performance
  /// ✅ Normalizes names to lowercase for autocomplete
  static Future<void> loadDrugsIfNeeded() async {
    final box = Hive.box<String>('drugs');

    // ⛔ If data already exists, skip loading
    if (box.isNotEmpty) {
      print('✅ Drugs already loaded (${box.length})');
      return;
    }

    print('📥 Loading drugs from JSON...');

    // 📄 Load JSON from assets
    final String jsonString =
        await rootBundle.loadString('assets/drugs_clean.json');

    final List<dynamic> jsonList = json.decode(jsonString);

    // 🗂 Prepare data for batch insert
    final Map<String, String> drugMap = {};

    for (final item in jsonList) {
      final String? name = item['name'];

      if (name != null && name.isNotEmpty) {
        final normalizedName = name.toLowerCase().trim();
        drugMap[normalizedName] = normalizedName;
      }
    }

    // 🚀 Fast batch insert
    await box.putAll(drugMap);

    print('✅ Loaded ${box.length} drugs into Hive');
  }
}
