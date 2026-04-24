import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
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
  final String column;   // e.g. 'MURPHY'
  final String value;    // e.g. '66' or '56A'
  final String fullAddress; // e.g. '66 Murphy Rd'
  final bool isWild;

  const DrawnAddress({
    required this.column,
    required this.value,
    required this.fullAddress,
    required this.isWild,
  });
}

class GameState {
  List<BingoCard> allCards = [];
  Map<String, List<String>> columnPools = {};
  String wildCard = '77 Long Lake Rd';

  // Draw bag — all address slips, shuffled
  List<DrawnAddress> _drawBag = [];
  List<DrawnAddress> drawnAddresses = [];

  // The set of plain values drawn so far (for card checking)
  Set<String> drawnValues = {};

  int currentRoundIndex = 0;
  bool gameStarted = false;
  bool roundInProgress = false;

  // Bingos recorded per round: list of card numbers that called bingo
  List<List<int>> bingosPerRound = List.generate(kRoundSequence.length, (_) => []);

  bool get allDrawn => _drawBag.isEmpty;

  GameType get currentRound => kRoundSequence[currentRoundIndex];

  bool get isLastRound => currentRoundIndex >= kRoundSequence.length - 1;

  DrawnAddress? get lastDrawn => drawnAddresses.isEmpty ? null : drawnAddresses.last;

  Future<void> loadCards() async {
    final raw = await rootBundle.loadString('assets/data/bingo_cards.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;

    allCards = (data['cards'] as List)
        .map((j) => BingoCard.fromJson(j as Map<String, dynamic>))
        .toList();

    final pools = data['column_pools'] as Map<String, dynamic>;
    for (final entry in pools.entries) {
      columnPools[entry.key] =
          (entry.value as List).map((v) => v.toString()).toList();
    }

    wildCard = data['wild_card'] as String;
    _buildDrawBag();
  }

  static const Map<String, String> _colStreetLabel = {
    'MURPHY': 'Murphy Rd',
    'HANNA': 'Hanna Cr',
    'McCANDLESS': 'McCandless Cr',
    'SWAN_CROW_OBRIEN': 'Swan/Crow/O\'Brien',
    'MC_STREETS': 'McCrimmon/McClennan/McIntyre',
  };

  // Extra slips: O'Brien Pl #3 and O'Brien Rd #5 share squares with Swan/Crow
  static const List<Map<String, String>> _extraSlips = [
    {'column': 'SWAN_CROW_OBRIEN', 'value': '3', 'address': '3 O\'Brien Pl'},
    {'column': 'SWAN_CROW_OBRIEN', 'value': '5', 'address': '5 O\'Brien Rd'},
  ];

  void _buildDrawBag() {
    _drawBag = [];

    for (final entry in columnPools.entries) {
      final col = entry.key;
      final street = _colStreetLabel[col] ?? col;
      for (final val in entry.value) {
        _drawBag.add(DrawnAddress(
          column: col,
          value: val,
          fullAddress: '$val $street',
          isWild: false,
        ));
      }
    }

    // Extra collision slips
    for (final slip in _extraSlips) {
      _drawBag.add(DrawnAddress(
        column: slip['column']!,
        value: slip['value']!,
        fullAddress: slip['address']!,
        isWild: false,
      ));
    }

    // Wild card
    _drawBag.add(DrawnAddress(
      column: 'WILD',
      value: wildCard,
      fullAddress: wildCard,
      isWild: true,
    ));

    _drawBag.shuffle(Random());
  }

  void startGame() {
    gameStarted = true;
    roundInProgress = true;
    drawnAddresses.clear();
    drawnValues.clear();
    currentRoundIndex = 0;
    bingosPerRound = List.generate(kRoundSequence.length, (_) => []);
    _drawBag.shuffle(Random());
  }

  // Draw the next address. Returns null if bag is empty.
  DrawnAddress? drawNext() {
    if (_drawBag.isEmpty) return null;
    final drawn = _drawBag.removeAt(0);
    drawnAddresses.add(drawn);
    if (!drawn.isWild) {
      drawnValues.add(drawn.value);
    }
    return drawn;
  }

  // Check a specific card for bingo in the current round
  bool checkCard(int cardNumber) {
    if (cardNumber < 1 || cardNumber > allCards.length) return false;
    final card = allCards[cardNumber - 1];
    return card.hasBingo(drawnValues, currentRound);
  }

  // Record a bingo for the current round
  void recordBingo(int cardNumber) {
    if (!bingosPerRound[currentRoundIndex].contains(cardNumber)) {
      bingosPerRound[currentRoundIndex].add(cardNumber);
    }
  }

  // Advance to the next round (draws carry over, free space stays)
  bool advanceRound() {
    if (isLastRound) return false;
    currentRoundIndex++;
    roundInProgress = true;
    return true;
  }

  // Cards that currently have bingo in the active round (for live display)
  List<int> currentBingoCards() {
    return allCards
        .where((c) => c.hasBingo(drawnValues, currentRound))
        .map((c) => c.cardNumber)
        .toList();
  }

  // How many addresses remain
  int get remaining => _drawBag.length;

  // Percent of bag drawn
  double get drawProgress =>
      drawnAddresses.isEmpty ? 0.0 : drawnAddresses.length / (drawnAddresses.length + _drawBag.length);
}
