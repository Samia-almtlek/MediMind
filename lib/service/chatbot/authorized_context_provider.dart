import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

abstract class AuthorizedContextProvider {
  Future<String> buildAuthorizedContext(String question);
}

class FirestoreProductDescriptionContextProvider
    implements AuthorizedContextProvider {
  FirestoreProductDescriptionContextProvider(
    this._firestore, {
    this.fallbackProvider,
    this.maxProductsToScan = 150,
  });

  final FirebaseFirestore _firestore;
  final AuthorizedContextProvider? fallbackProvider;
  final int maxProductsToScan;

  @override
  Future<String> buildAuthorizedContext(String question) async {
    final normalizedQuestion = question.toLowerCase().trim();
    if (normalizedQuestion.isEmpty) {
      return '';
    }

    try {
      final snapshot = await _firestore
          .collection('product')
          .limit(maxProductsToScan)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final rawName = data['name'];
        final rawDescription = data['description'];

        if (rawName is! String || rawDescription is! String) {
          continue;
        }

        final normalizedName = rawName.toLowerCase().trim();
        if (normalizedName.isEmpty) {
          continue;
        }

        if (normalizedQuestion.contains(normalizedName)) {
          return _buildContext(data);
        }
      }
    } catch (_) {
      return _buildFallback(question);
    }

    return _buildFallback(question);
  }

  Future<String> _buildFallback(String question) async {
    if (fallbackProvider == null) {
      return '';
    }
    return fallbackProvider!.buildAuthorizedContext(question);
  }

  String _buildContext(Map<String, dynamic> data) {
    String? asTrimmedString(dynamic value) {
      if (value is! String) {
        return null;
      }
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return trimmed;
    }

    final name = asTrimmedString(data['name']);
    final dosage = asTrimmedString(data['dosage']);
    final description = asTrimmedString(data['description']);

    final lines = <String>[
      if (name != null) 'DRUG: $name',
      if (dosage != null) 'DOSAGE: $dosage',
      if (description != null) 'DESCRIPTION: $description',
    ];

    return lines.join('\n');
  }
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
