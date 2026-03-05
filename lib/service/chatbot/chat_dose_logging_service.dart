import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medimind/data/repositories_impl/dose_log_repository_impl.dart';
import 'package:medimind/service/database/firestore_service.dart';

class ParsedDoseAmount {
  const ParsedDoseAmount({
    required this.value,
    required this.unit,
  });

  final double value;
  final String unit;
}

class ParsedDoseIntake {
  const ParsedDoseIntake({
    required this.medicationName,
    this.amount,
  });

  final String medicationName;
  final ParsedDoseAmount? amount;

  bool get hasAmount => amount != null;
}

class MedicationOption {
  const MedicationOption({
    required this.id,
    required this.name,
    this.dosage = '',
    this.productId = '',
    this.isFromProduct = false,
  });

  final String id;
  final String name;
  final String dosage;
  final String productId;
  final bool isFromProduct;
}

class MedicationResolveResult {
  const MedicationResolveResult({
    this.matched,
    this.ambiguousOptions = const <MedicationOption>[],
  });

  final MedicationOption? matched;
  final List<MedicationOption> ambiguousOptions;

  bool get isMatched => matched != null;
  bool get isAmbiguous => matched == null && ambiguousOptions.isNotEmpty;
}

class DoseLogWriteResult {
  const DoseLogWriteResult({
    required this.linkedToPlannedDose,
  });

  final bool linkedToPlannedDose;
}

class ChatDoseLoggingService {
  ChatDoseLoggingService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    DoseLogRepositoryImpl? doseLogRepository,
  })  : _firestore = firestore,
        _auth = auth,
        _doseLogRepository =
            doseLogRepository ?? DoseLogRepositoryImpl(FirestoreService());

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final DoseLogRepositoryImpl _doseLogRepository;

  static const int _maxProductsToScan = 500;

  static final RegExp _intentRegex = RegExp(
    r'\b(i\s+(?:just\s+)?took|i\s+have\s+taken|just\s+took|took)\b',
    caseSensitive: false,
  );

  static final RegExp _amountRegex = RegExp(
    r'(\d+(?:[\.,]\d+)?)\s*(mg|g|ml|mcg|μg|ug|tablet(?:s)?|pill(?:s)?|capsule(?:s)?)\b',
    caseSensitive: false,
  );

  static final RegExp _schedulePhraseRegex = RegExp(
    r'\badd(?:\s+(?:this|it))?\s+to\s+(?:my\s+)?(?:schedule|plan|planner)\b',
    caseSensitive: false,
  );

  static final RegExp _scheduleVerbRegex = RegExp(
    r'\bschedule(?:\s+(?:this|it))?\b',
    caseSensitive: false,
  );

  ParsedDoseIntake? parseDoseIntakeStatement(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || !_intentRegex.hasMatch(trimmed)) {
      return null;
    }

    final amountMatch = _amountRegex.firstMatch(trimmed);
    ParsedDoseAmount? parsedAmount;
    if (amountMatch != null) {
      final rawValue = amountMatch.group(1)?.replaceAll(',', '.');
      final parsedValue = rawValue == null ? null : double.tryParse(rawValue);
      final rawUnit = amountMatch.group(2);
      if (parsedValue != null && rawUnit != null) {
        parsedAmount = ParsedDoseAmount(
          value: parsedValue,
          unit: _normalizeUnit(rawUnit),
        );
      }
    }

    final medicationName = _extractMedicationName(trimmed, amountMatch);
    if (medicationName.isEmpty) {
      return null;
    }

    return ParsedDoseIntake(
      medicationName: medicationName,
      amount: parsedAmount,
    );
  }

  ParsedDoseAmount? parseDoseAmount(String text) {
    final match = _amountRegex.firstMatch(text.trim());
    if (match == null) {
      return null;
    }

    final rawValue = match.group(1)?.replaceAll(',', '.');
    final parsedValue = rawValue == null ? null : double.tryParse(rawValue);
    final rawUnit = match.group(2);
    if (parsedValue == null || rawUnit == null) {
      return null;
    }

    return ParsedDoseAmount(
      value: parsedValue,
      unit: _normalizeUnit(rawUnit),
    );
  }

  ParsedDoseAmount? parseOptionDosage(MedicationOption option) {
    if (option.dosage.trim().isEmpty) {
      return null;
    }
    return parseDoseAmount(option.dosage);
  }

  String normalizeMedicationName(String value) {
    return _normalizeName(value);
  }

  Future<MedicationResolveResult> resolveMedication(String requestedName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || requestedName.trim().isEmpty) {
      return const MedicationResolveResult();
    }

    final normalizedRequested = _normalizeName(requestedName);
    if (normalizedRequested.isEmpty) {
      return const MedicationResolveResult();
    }

    final snapshot = await _firestore
        .collection('user_medications')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    if (snapshot.docs.isEmpty) {
      return const MedicationResolveResult();
    }

    final scored = <({MedicationOption option, int score})>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final name = (data['name'] as String?)?.trim() ?? '';
      final dosage = (data['dosage'] as String?)?.trim() ?? '';
      final productId = (data['productId'] as String?)?.trim() ?? '';
      if (name.isEmpty) {
        continue;
      }

      final normalizedName = _normalizeName(name);
      final score = _scoreMatch(normalizedRequested, normalizedName);
      if (score <= 0) {
        continue;
      }

      scored.add((
        option: MedicationOption(
          id: doc.id,
          name: name,
          dosage: dosage,
          productId: productId,
          isFromProduct: false,
        ),
        score: score,
      ));
    }

    if (scored.isEmpty) {
      return const MedicationResolveResult();
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final bestScore = scored.first.score;
    final bestMatches = scored
        .where((entry) => entry.score == bestScore)
        .map((entry) => entry.option)
        .toList();

    if (bestMatches.length == 1) {
      return MedicationResolveResult(matched: bestMatches.first);
    }

    return MedicationResolveResult(ambiguousOptions: bestMatches.take(4).toList());
  }

  Future<MedicationResolveResult> resolveMedicationOrProduct(
    String requestedName,
  ) async {
    final userResult = await resolveMedication(requestedName);
    if (userResult.isMatched || userResult.isAmbiguous) {
      return userResult;
    }

    return _resolveProductMatches(requestedName);
  }

  Future<MedicationOption> ensureUserMedication(
    MedicationOption option,
  ) async {
    if (!option.isFromProduct) {
      return option;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw StateError('No authenticated user is available.');
    }

    final now = DateTime.now();
    final nowTimestamp = Timestamp.fromDate(now);
    final timeLabel =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final newId = _firestore.collection('user_medications').doc().id;

    await _firestore.collection('user_medications').doc(newId).set({
      'userId': userId,
      'productId': option.productId,
      'name': option.name,
      'dosage': option.dosage,
      'frequencyPerDay': 1,
      'startDate': nowTimestamp,
      'endDate': null,
      'instructions': 'Added via chat',
      'intakeTimes': <String>[timeLabel],
      'isActive': true,
      'aangemaaktViaOCR': false,
      'initialStock': 0,
      'currentStock': 0,
      'lowStockThresholdDays': 3,
      'lastStockAlertAt': null,
    });

    return MedicationOption(
      id: newId,
      name: option.name,
      dosage: option.dosage,
      productId: option.productId,
      isFromProduct: false,
    );
  }

  Future<void> updateMedicationStock({
    required String medicationId,
    required int stockCount,
  }) async {
    await _firestore.collection('user_medications').doc(medicationId).update({
      'initialStock': stockCount,
      'currentStock': stockCount,
    });
  }

  Future<DoseLogWriteResult> logTakenDose({
    required MedicationOption medication,
    required ParsedDoseAmount amount,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw StateError('No authenticated user is available.');
    }

    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final medicationRef =
        _firestore.collection('user_medications').doc(medication.id);

    final pendingTodaySnapshot = await medicationRef
        .collection('dose_logs')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .where('geplandeTijd', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('geplandeTijd', isLessThan: Timestamp.fromDate(dayEnd))
        .get();

    QueryDocumentSnapshot<Map<String, dynamic>>? nearestPending;
    Duration? nearestDistance;
    for (final doc in pendingTodaySnapshot.docs) {
      final data = doc.data();
      final plannedTs = data['geplandeTijd'];
      if (plannedTs is! Timestamp) {
        continue;
      }

      final plannedTime = plannedTs.toDate();
      final distance = now.isAfter(plannedTime)
          ? now.difference(plannedTime)
          : plannedTime.difference(now);

      if (nearestDistance == null || distance < nearestDistance) {
        nearestDistance = distance;
        nearestPending = doc;
      }
    }

    if (nearestPending != null &&
        nearestDistance != null &&
        nearestDistance <= const Duration(hours: 2)) {
      await _doseLogRepository.markAsTaken(medication.id, nearestPending.id);
      await nearestPending.reference.update(
        {
          'takenAmountValue': amount.value,
          'takenAmountUnit': amount.unit,
          'takenAmountText': _buildAmountText(amount),
          'source': 'chat',
        },
      );
      return const DoseLogWriteResult(linkedToPlannedDose: true);
    }

    final manualDoseRef = medicationRef.collection('dose_logs').doc();

    await manualDoseRef.set(
      {
        'userId': userId,
        'medicatieId': medication.id,
        'medicatieNaam': medication.name,
        'geplandeTijd': Timestamp.fromDate(now),
        'ingenomenTijd': null,
        'status': 'pending',
        'reminderCount': 0,
        'escalatieVerzonden': false,
        'escalatieTijd': null,
        'scheduledNotificationIds': <int>[],
        'source': 'chat',
      },
    );

    await _doseLogRepository.markAsTaken(medication.id, manualDoseRef.id);
    await manualDoseRef.update(
      {
        'takenAmountValue': amount.value,
        'takenAmountUnit': amount.unit,
        'takenAmountText': _buildAmountText(amount),
        'source': 'chat',
      },
    );

    return const DoseLogWriteResult(linkedToPlannedDose: false);
  }

  String _extractMedicationName(String input, RegExpMatch? amountMatch) {
    final intentMatch = _intentRegex.firstMatch(input);
    if (intentMatch == null) {
      return '';
    }

    var tail = input.substring(intentMatch.end).trim();

    tail = tail.replaceAll(_schedulePhraseRegex, ' ');
    tail = tail.replaceAll(_scheduleVerbRegex, ' ');

    if (amountMatch != null) {
      final amountText = amountMatch.group(0)?.trim() ?? '';
      if (amountText.isNotEmpty) {
        tail = tail.replaceFirst(RegExp(RegExp.escape(amountText), caseSensitive: false), '').trim();
      }
    }

    tail = tail.replaceFirst(RegExp(r'^of\s+', caseSensitive: false), '');
    tail = tail.replaceFirst(RegExp(r'^(a|an|the|my)\s+', caseSensitive: false), '');
    tail = tail.replaceAll(RegExp(r'[.!?]'), ' ');
    tail = tail.replaceAll(
      RegExp(
        r'\b(now|today|already|just|please|thanks|thank\s+you)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    tail = tail.replaceAll(RegExp(r'\s+'), ' ').trim();
    return tail;
  }

  String _normalizeName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _scoreMatch(String requested, String candidate) {
    if (requested == candidate) {
      return 100;
    }
    if (candidate.startsWith(requested)) {
      return 90;
    }
    if (candidate.contains(requested)) {
      return 80;
    }

    final requestedTokens = requested.split(' ').where((e) => e.isNotEmpty).toList();
    final candidateTokens = candidate.split(' ').where((e) => e.isNotEmpty).toSet();
    var tokenHits = 0;
    for (final token in requestedTokens) {
      if (candidateTokens.contains(token)) {
        tokenHits++;
      }
    }

    if (tokenHits == 0) {
      return 0;
    }

    if (tokenHits == requestedTokens.length) {
      return 70;
    }

    return 40;
  }

  Future<MedicationResolveResult> _resolveProductMatches(
    String requestedName,
  ) async {
    final normalizedRequested = _normalizeName(requestedName);
    if (normalizedRequested.isEmpty) {
      return const MedicationResolveResult();
    }

    final directSnapshot = await _firestore
        .collection('product')
        .where('name_lower', isEqualTo: normalizedRequested)
        .limit(4)
        .get();

    if (directSnapshot.docs.isNotEmpty) {
      final options = directSnapshot.docs
          .map((doc) => _productDocToOption(doc.id, doc.data()))
          .where((option) => option != null)
          .cast<MedicationOption>()
          .toList();

      if (options.length == 1) {
        return MedicationResolveResult(matched: options.first);
      }

      if (options.isNotEmpty) {
        return MedicationResolveResult(ambiguousOptions: options.take(4).toList());
      }
    }

    final snapshot = await _firestore
        .collection('product')
        .limit(_maxProductsToScan)
        .get();

    final scored = <({MedicationOption option, int score})>[];

    for (final doc in snapshot.docs) {
      final option = _productDocToOption(doc.id, doc.data());
      if (option == null) {
        continue;
      }

      final normalizedName = _normalizeName(option.name);
      final score = _scoreMatch(normalizedRequested, normalizedName);
      if (score <= 0) {
        continue;
      }

      scored.add((option: option, score: score));
    }

    if (scored.isEmpty) {
      return const MedicationResolveResult();
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final bestScore = scored.first.score;
    final bestMatches = scored
        .where((entry) => entry.score == bestScore)
        .map((entry) => entry.option)
        .toList();

    if (bestMatches.length == 1) {
      return MedicationResolveResult(matched: bestMatches.first);
    }

    return MedicationResolveResult(ambiguousOptions: bestMatches.take(4).toList());
  }

  MedicationOption? _productDocToOption(
    String docId,
    Map<String, dynamic> data,
  ) {
    final name = (data['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      return null;
    }

    final dosageRaw = (data['dosage'] as String?)?.trim() ??
        (data['dose'] as String?)?.trim() ??
        '';

    return MedicationOption(
      id: docId,
      name: name,
      dosage: dosageRaw,
      productId: docId,
      isFromProduct: true,
    );
  }

  String _normalizeUnit(String rawUnit) {
    final normalized = rawUnit.trim().toLowerCase();
    switch (normalized) {
      case 'μg':
      case 'ug':
        return 'mcg';
      case 'tablets':
        return 'tablet';
      case 'pills':
        return 'pill';
      case 'capsules':
        return 'capsule';
      default:
        return normalized;
    }
  }

  String _buildAmountText(ParsedDoseAmount amount) {
    final valueString = amount.value % 1 == 0
        ? amount.value.toStringAsFixed(0)
        : amount.value.toString();
    return '$valueString ${amount.unit}';
  }
}