import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
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

class GameState with ChangeNotifier {
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
    notifyListeners();
  }

  // Full address lookup: (column, value) -> full street address
  // Each entry maps exactly to one real property in the Firebase dataset.
  // Collision values (SWAN_CROW_OBRIEN #3 and #5) have separate extra slips below.
  static const Map<String, Map<String, String>> _addressLookup = {
    'MURPHY': {
      '9': '9 Murphy Rd',
      '11': '11 Murphy Rd',
      '25': '25 Murphy Rd',
      '27': '27 Murphy Rd',
      '33': '33 Murphy Rd',
      '35': '35 Murphy Rd',
      '37': '37 Murphy Rd',
      '38': '38 Murphy Rd',
      '39': '39 Murphy Rd',
      '43': '43 Murphy Rd',
      '44': '44 Murphy Rd',
      '45': '45 Murphy Rd',
      '47': '47 Murphy Rd',
      '49': '49 Murphy Rd',
      '56A': '56A Murphy Rd',
      '56B': '56B Murphy Rd',
      '58': '58 Murphy Rd',
      '61': '61 Murphy Rd',
      '62': '62 Murphy Rd',
      '65': '65 Murphy Rd',
      '66': '66 Murphy Rd',
      '67': '67 Murphy Rd',
      '68': '68 Murphy Rd',
      '70': '70 Murphy Rd',
      '71': '71 Murphy Rd',
      '72': '72 Murphy Rd',
      '73': '73 Murphy Rd',
      '75': '75 Murphy Rd',
      '76': '76 Murphy Rd',
    },
    'HANNA': {
      '2': '2 Hanna Cr',
      '8': '8 Hanna Cr',
      '9': '9 Hanna Cr',
      '10': '10 Hanna Cr',
      '11': '11 Hanna Cr',
      '12': '12 Hanna Cr',
      '14': '14 Hanna Cr',
      '15': '15 Hanna Cr',
      '16': '16 Hanna Cr',
      '27': '27 Hanna Cr',
      '33A': '33A Hanna Cr',
      '33B': '33B Hanna Cr',
      '36': '36 Hanna Cr',
      '37': '37 Hanna Cr',
      '40': '40 Hanna Cr',
      '41': '41 Hanna Cr',
      '45': '45 Hanna Cr',
      '48': '48 Hanna Cr',
      '52': '52 Hanna Cr',
    },
    'McCANDLESS': {
      '3': '3 McCandless Cr',
      '9': '9 McCandless Cr',
      '14': '14 McCandless Cr',
      '15': '15 McCandless Cr',
      '16A': '16A McCandless Cr',
      '16B': '16B McCandless Cr',
      '26': '26 McCandless Cr',
      '28': '28 McCandless Cr',
      '30': '30 McCandless Cr',
      '32': '32 McCandless Cr',
      '36': '36 McCandless Cr',
      '38': '38 McCandless Cr',
      '39': '39 McCandless Cr',
      '40': '40 McCandless Cr',
      '41': '41 McCandless Cr',
      '44': '44 McCandless Cr',
      '46': '46 McCandless Cr',
    },
    'SWAN_CROW_OBRIEN': {
      '3': '3 Swan Dr',
      '4': '4 Crow St',
      '5': '5 Swan Dr',
      '6': '6 Crow St',
      '8': '8 Swan Dr',
      '9': '9 Swan Dr',
      '10': '10 Swan Dr',   // Firebase has "Swan St" — known data error, is Swan Dr
      '11': '11 Swan Dr',
      '13': '13 Swan Dr',
      '19': '19 Swan Dr',
      '23': "23 O'Brien Rd",
    },
    'MC_STREETS': {
      '14A': '14A McCrimmon Cr',
      '14B': '14B McCrimmon Cr',
      '19': '19 McCrimmon Cr',
      '21': '21 McCrimmon Cr',
      '24': '24 McCrimmon Cr',
      '26': '26 McCrimmon Cr',
      '28': '28 McCrimmon Cr',
      '29': '29 McCrimmon Cr',
      '41': '41 McCrimmon Cr',
      '57': '57 McIntyre Dr',
      '62': '62 McIntyre Dr',
      '64': '64 McIntyre Dr',
      '78': '78 McClennan Rd',
      '82': '82 McClennan Rd',
      '84': '84 McClennan Rd',
      '85': '85 McClennan Rd',
      '86': '86 McClennan Rd',
      '87': '87 McClennan Rd',
      '88': '88 McClennan Rd',
      '89': '89 McClennan Rd',
    },
  };

  // Extra collision slips: O'Brien Pl #3 and O'Brien Rd #5 are additional draw slips
  // that share squares with Swan Dr #3 and Swan Dr #5 on the bingo cards.
  static const List<Map<String, String>> _extraSlips = [
    {'column': 'SWAN_CROW_OBRIEN', 'value': '3', 'address': "3 O'Brien Pl"},
    {'column': 'SWAN_CROW_OBRIEN', 'value': '5', 'address': "5 O'Brien Rd"},
  ];

  void _buildDrawBag() {
    _drawBag = [];

    for (final entry in columnPools.entries) {
      final col = entry.key;
      final colLookup = _addressLookup[col];
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
    notifyListeners();
  }

  // Draw the next address. Returns null if bag is empty.
  DrawnAddress? drawNext() {
    if (_drawBag.isEmpty) return null;
    final drawn = _drawBag.removeAt(0);
    drawnAddresses.add(drawn);
    if (!drawn.isWild) {
      drawnValues.add(drawn.value);
    }
    notifyListeners();
    return drawn;
  }

  // Check a specific card for bingo in the current round
  bool checkCard(int cardNumber) {
    if (cardNumber < 1) return false;
    BingoCard? card;
    for (final c in allCards) {
      if (c.cardNumber == cardNumber) {
        card = c;
        break;
      }
    }
    if (card == null) return false;
    return card.hasBingo(drawnValues, currentRound);
  }

  // Record a bingo for the current round
  void recordBingo(int cardNumber) {
    if (!bingosPerRound[currentRoundIndex].contains(cardNumber)) {
      bingosPerRound[currentRoundIndex].add(cardNumber);
      notifyListeners();
    }
  }

  // Advance to the next round (draws carry over, free space stays)
  bool advanceRound() {
    if (isLastRound) return false;
    currentRoundIndex++;
    roundInProgress = true;
    notifyListeners();
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
