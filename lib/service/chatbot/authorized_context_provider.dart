import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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
      final tokens = _extractCandidateTokens(normalizedQuestion);
      final normalizedQuestionCompact = _normalizeForMatch(normalizedQuestion);

      for (final token in tokens) {
        final direct = await _lookupByExactName(token);
        if (direct != null) {
          _debug('Direct Firestore hit for token "$token"');
          return _buildContext(direct);
        }
      }

      final snapshot = await _firestore
          .collection('product')
          .limit(maxProductsToScan)
          .get();

      Map<String, dynamic>? bestMatch;
      int bestScore = -1;

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

        final normalizedNameCompact = _normalizeForMatch(normalizedName);

        int score = 0;
        if (normalizedQuestion.contains(normalizedName) ||
            normalizedQuestionCompact.contains(normalizedNameCompact)) {
          score += 100;
        }

        for (final token in tokens) {
          final compactToken = _normalizeForMatch(token);
          if (normalizedName.contains(token) ||
              token.contains(normalizedName) ||
              normalizedNameCompact.contains(compactToken) ||
              compactToken.contains(normalizedNameCompact)) {
            score += 10;
          }
        }

        if (score > bestScore) {
          bestScore = score;
          bestMatch = data;
        }
      }

      if (bestMatch != null && bestScore > 0) {
        _debug('Scored Firestore hit with score $bestScore');
        return _buildContext(bestMatch);
      }
    } catch (_) {
      _debug('Firestore context lookup failed, using fallback provider');
      return _buildFallback(question);
    }

    _debug('No Firestore match found, using fallback provider');
    return _buildFallback(question);
  }

  Set<String> _extractCandidateTokens(String normalizedQuestion) {
    return normalizedQuestion
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length >= 2)
        .toSet();
  }

  String _normalizeForMatch(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  Future<Map<String, dynamic>?> _lookupByExactName(String token) async {
    final byLower = await _firestore
        .collection('product')
        .where('name_lower', isEqualTo: token)
        .limit(1)
        .get();
    if (byLower.docs.isNotEmpty) {
      return byLower.docs.first.data();
    }

    final candidates = <String>{
      token,
      token.toLowerCase(),
      _titleCase(token),
      token.toUpperCase(),
    };

    for (final candidate in candidates) {
      final byName = await _firestore
          .collection('product')
          .where('name', isEqualTo: candidate)
          .limit(1)
          .get();
      if (byName.docs.isNotEmpty) {
        return byName.docs.first.data();
      }
    }

    return null;
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
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

    final name = asTrimmedString(data['name']) ?? asTrimmedString(data['Name']);
    final dosage =
        asTrimmedString(data['dosage']) ?? asTrimmedString(data['dose']);
    final description =
        asTrimmedString(data['description']) ?? asTrimmedString(data['Description']);
    final instructions = asTrimmedString(data['instructions']);
    final indication = asTrimmedString(data['indication']) ??
        asTrimmedString(data['indications']);

    final lines = <String>[
      if (name != null) 'DRUG: $name',
      if (dosage != null) 'DOSAGE: $dosage',
      if (description != null) 'DESCRIPTION: $description',
      if (instructions != null) 'INSTRUCTIONS: $instructions',
      if (indication != null) 'INDICATION: $indication',
    ];

    return lines.join('\n');
  }

  void _debug(String message) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[AuthorizedContext] $message');
  }
}

class LocalDrugListContextProvider implements AuthorizedContextProvider {
  static const String _assetPath = 'assets/drugs_clean.json';
  static const int _maxMatches = 10;

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
