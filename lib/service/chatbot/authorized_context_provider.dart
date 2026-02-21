import 'dart:convert';

import 'package:flutter/services.dart';

abstract class AuthorizedContextProvider {
  Future<String> buildAuthorizedContext(String question);
}

class LocalDrugListContextProvider implements AuthorizedContextProvider {
  static const String _assetPath = 'assets/drugs_clean.json';
  static const int _maxMatches = 20;

  List<String>? _cachedDrugNames;

  @override
  Future<String> buildAuthorizedContext(String question) async {
    final normalizedQuestion = question.toLowerCase().trim();
    if (normalizedQuestion.isEmpty) {
      return '';
    }

    final drugs = await _loadDrugNames();
    final tokens = normalizedQuestion
        .split(RegExp(r'[^a-zA-Z0-9]+'))
        .where((token) => token.length >= 4)
        .toList();

    final matches = <String>[];

    for (final drug in drugs) {
      final lowerDrug = drug.toLowerCase();
      final isDirectMention = normalizedQuestion.contains(lowerDrug);
      final hasTokenMatch =
          tokens.any((token) => lowerDrug.contains(token) || token.contains(lowerDrug));

      if (isDirectMention || hasTokenMatch) {
        matches.add(drug);
        if (matches.length >= _maxMatches) {
          break;
        }
      }
    }

    if (matches.isEmpty) {
      return '';
    }

    return matches.map((drug) => '- $drug').join('\n');
  }

  Future<List<String>> _loadDrugNames() async {
    final cachedDrugNames = _cachedDrugNames;
    if (cachedDrugNames != null) {
      return cachedDrugNames;
    }

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw);

    final names = <String>[];
    if (decoded is List) {
      for (final item in decoded) {
        if (item is String && item.trim().isNotEmpty) {
          names.add(item.trim());
        } else if (item is Map<String, dynamic>) {
          final name = item['name'];
          if (name is String && name.trim().isNotEmpty) {
            names.add(name.trim());
          }
        }
      }
    }

    _cachedDrugNames = names;
    return names;
  }
}
