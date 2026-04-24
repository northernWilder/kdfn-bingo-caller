import 'dart:math';
import 'package:flutter/foundation.dart';
import 'bingo_card.dart';

// The full sequence of rounds for a game night
const List<GameType> kRoundSequence = [
  GameType.singleLine,
  GameType.twoLines,
  GameType.corners,
  GameType.tShape,
  GameType.fullHouse,
];

class DrawnAddress {
  final String column;
  final String value;
  final String fullAddress;
  final bool isWild;

  const DrawnAddress({
    required this.column,
    required this.value,
    required this.fullAddress,
    required this.isWild,
  });
}

class GameState with ChangeNotifier {
  // ── Game metadata ──────────────────────────────────────────────────────────
  String gameId = '';
  String gameName = '';
  String gameSubtitle = '';
  String logoPath = 'assets/images/ebs-logo-dark.png';

  // ── Card data ──────────────────────────────────────────────────────────────
  List<BingoCard> allCards = [];
  Map<String, List<String>> columnPools = {};
  String wildCard = '';

  // Address lookup: column → value → full address string
  // Loaded from JSON — no longer hardcoded in Dart.
  Map<String, Map<String, String>> addressLookup = {};

  // Extra draw slips (e.g. collision addresses that share a square)
  List<Map<String, String>> extraSlips = [];

  // UI helpers loaded from JSON
  Map<String, String> columnLabels = {};   // col key → display label
  Map<String, String> columnColours = {};  // col key → hex colour

  // ── Draw state ─────────────────────────────────────────────────────────────
  List<DrawnAddress> _drawBag = [];
  List<DrawnAddress> drawnAddresses = [];
  Set<String> drawnValues = {};

  // ── Round state ────────────────────────────────────────────────────────────
  int currentRoundIndex = 0;
  bool gameStarted = false;
  bool roundInProgress = false;
  List<List<int>> bingosPerRound =
      List.generate(kRoundSequence.length, (_) => []);

  // ── Computed getters ───────────────────────────────────────────────────────
  bool get allDrawn => _drawBag.isEmpty;
  bool get isLoaded => allCards.isNotEmpty;
  GameType get currentRound => kRoundSequence[currentRoundIndex];
  bool get isLastRound => currentRoundIndex >= kRoundSequence.length - 1;
  DrawnAddress? get lastDrawn =>
      drawnAddresses.isEmpty ? null : drawnAddresses.last;
  int get remaining => _drawBag.length;
  double get drawProgress => drawnAddresses.isEmpty
      ? 0.0
      : drawnAddresses.length /
          (drawnAddresses.length + _drawBag.length);

  // ── Load from pre-decoded JSON map ─────────────────────────────────────────
  /// Called by GameSelectScreen after access code is verified.
  void loadFromData(Map<String, dynamic> data, {String logoAssetPath = ''}) {
    gameId = data['game_id'] as String? ?? '';
    gameName = data['game_name'] as String? ?? '';
    gameSubtitle = data['game_subtitle'] as String? ?? '';
    if (logoAssetPath.isNotEmpty) logoPath = logoAssetPath;

    allCards = (data['cards'] as List)
        .map((j) => BingoCard.fromJson(j as Map<String, dynamic>))
        .toList();

    final pools = data['column_pools'] as Map<String, dynamic>;
    columnPools = {};
    for (final entry in pools.entries) {
      columnPools[entry.key] =
          (entry.value as List).map((v) => v.toString()).toList();
    }

    wildCard = data['wild_card'] as String? ?? '';

    // Address lookup — keyed col → value → full address
    addressLookup = {};
    final rawLookup = data['address_lookup'] as Map<String, dynamic>?;
    if (rawLookup != null) {
      for (final colEntry in rawLookup.entries) {
        final inner = colEntry.value as Map<String, dynamic>;
        addressLookup[colEntry.key] =
            inner.map((k, v) => MapEntry(k, v as String));
      }
    }

    // Extra slips
    extraSlips = [];
    final rawExtra = data['extra_slips'] as List?;
    if (rawExtra != null) {
      for (final s in rawExtra) {
        final m = s as Map<String, dynamic>;
        extraSlips.add({
          'column': m['column'] as String,
          'value': m['value'] as String,
          'address': m['address'] as String,
        });
      }
    }

    // UI helpers
    columnLabels = {};
    final rawLabels = data['column_labels'] as Map<String, dynamic>?;
    if (rawLabels != null) {
      columnLabels = rawLabels.map((k, v) => MapEntry(k, v as String));
    }

    columnColours = {};
    final rawColours = data['column_colours'] as Map<String, dynamic>?;
    if (rawColours != null) {
      columnColours = rawColours.map((k, v) => MapEntry(k, v as String));
    }

    _buildDrawBag();
    notifyListeners();
  }

  // ── Draw bag construction ──────────────────────────────────────────────────
  void _buildDrawBag() {
    _drawBag = [];

    for (final entry in columnPools.entries) {
      final col = entry.key;
      final colLookup = addressLookup[col];
      for (final val in entry.value) {
        final fullAddress = colLookup?[val] ?? '$val $col';
        _drawBag.add(DrawnAddress(
          column: col,
          value: val,
          fullAddress: fullAddress,
          isWild: false,
        ));
      }
    }

    for (final slip in extraSlips) {
      _drawBag.add(DrawnAddress(
        column: slip['column']!,
        value: slip['value']!,
        fullAddress: slip['address']!,
        isWild: false,
      ));
    }

    if (wildCard.isNotEmpty) {
      _drawBag.add(DrawnAddress(
        column: 'WILD',
        value: wildCard,
        fullAddress: wildCard,
        isWild: true,
      ));
    }

    _drawBag.shuffle(Random());
  }

  // ── Game lifecycle ─────────────────────────────────────────────────────────
  void startGame() {
    gameStarted = true;
    roundInProgress = true;
    drawnAddresses.clear();
    drawnValues.clear();
    currentRoundIndex = 0;
    bingosPerRound = List.generate(kRoundSequence.length, (_) => []);
    _buildDrawBag();
    notifyListeners();
  }

  DrawnAddress? drawNext() {
    if (_drawBag.isEmpty) return null;
    final drawn = _drawBag.removeAt(0);
    drawnAddresses.add(drawn);
    if (!drawn.isWild) drawnValues.add(drawn.value);
    notifyListeners();
    return drawn;
  }

  bool checkCard(int cardNumber) {
    final card = allCards.firstWhere(
      (c) => c.cardNumber == cardNumber,
      orElse: () => allCards.isEmpty
          ? throw StateError('No cards loaded')
          : allCards.first,
    );
    if (card.cardNumber != cardNumber) return false;
    return card.hasBingo(drawnValues, currentRound);
  }

  void recordBingo(int cardNumber) {
    if (!bingosPerRound[currentRoundIndex].contains(cardNumber)) {
      bingosPerRound[currentRoundIndex].add(cardNumber);
      notifyListeners();
    }
  }

  bool advanceRound() {
    if (isLastRound) return false;
    currentRoundIndex++;
    roundInProgress = true;
    notifyListeners();
    return true;
  }

  List<int> currentBingoCards() {
    return allCards
        .where((c) => c.hasBingo(drawnValues, currentRound))
        .map((c) => c.cardNumber)
        .toList();
  }

  // ── Column UI helpers ──────────────────────────────────────────────────────
  String labelForColumn(String col) =>
      columnLabels[col] ?? col;

  /// Returns colour as a Flutter Color int from a hex string like '#1B5E7B'.
  int colourForColumn(String col) {
    final hex = columnColours[col] ?? '#444444';
    return int.parse('FF${hex.replaceFirst('#', '')}', radix: 16);
  }
}
