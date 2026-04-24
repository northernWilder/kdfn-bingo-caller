import 'package:flutter_test/flutter_test.dart';
import 'package:kdfn_bingo_caller/models/bingo_card.dart';

void main() {
  group('BingoCard.hasBingo', () {
    final card = _buildDeterministicCard();

    test('singleLine: detects all rows, columns, and diagonals', () {
      final lines = <List<List<int>>>[
        // Rows
        for (int row = 0; row < 5; row++) [for (int col = 0; col < 5; col++) [col, row]],
        // Columns
        for (int col = 0; col < 5; col++) [for (int row = 0; row < 5; row++) [col, row]],
        // Diagonals
        [for (int i = 0; i < 5; i++) [i, i]],
        [for (int i = 0; i < 5; i++) [i, 4 - i]],
      ];

      for (final line in lines) {
        final drawn = _drawnFor(card, line);
        expect(
          card.hasBingo(drawn, GameType.singleLine),
          isTrue,
          reason: 'Expected a bingo for line $line',
        );
      }
    });

    test('singleLine: does not report bingo for near-miss lines', () {
      final nearMisses = <List<List<int>>>[
        // Row near miss: 4/5, missing [4,0]
        [
          [0, 0],
          [1, 0],
          [2, 0],
          [3, 0],
        ],
        // Column near miss: 4/5, missing [0,4]
        [
          [0, 0],
          [0, 1],
          [0, 2],
          [0, 3],
        ],
        // Main diagonal near miss: missing [4,4]
        [
          [0, 0],
          [1, 1],
          [2, 2],
          [3, 3],
        ],
        // Anti-diagonal near miss: missing [0,4]
        [
          [4, 0],
          [3, 1],
          [2, 2],
          [1, 3],
        ],
      ];

      for (final cells in nearMisses) {
        final drawn = _drawnFor(card, cells);
        expect(
          card.hasBingo(drawn, GameType.singleLine),
          isFalse,
          reason: 'Unexpected single-line bingo for near miss $cells',
        );
      }
    });

    test('twoLines: requires at least two completed lines', () {
      final oneLineOnly = _drawnFor(card, [for (int col = 0; col < 5; col++) [col, 0]]);
      expect(card.hasBingo(oneLineOnly, GameType.twoLines), isFalse);

      final twoLines = _drawnFor(card, [
        for (int col = 0; col < 5; col++) [col, 0],
        for (int row = 0; row < 5; row++) [0, row],
      ]);
      expect(card.hasBingo(twoLines, GameType.twoLines), isTrue);

      final oneLinePlusNearMiss = _drawnFor(card, [
        for (int col = 0; col < 5; col++) [col, 1],
        [0, 2],
        [1, 2],
        [2, 2],
        [3, 2],
      ]);
      expect(card.hasBingo(oneLinePlusNearMiss, GameType.twoLines), isFalse);
    });

    test('corners: only true when all four corners are marked', () {
      final allCorners = _drawnFor(card, const [
        [0, 0],
        [4, 0],
        [0, 4],
        [4, 4],
      ]);
      expect(card.hasBingo(allCorners, GameType.corners), isTrue);

      final threeCornersPlusNoise = _drawnFor(card, [
        const [0, 0],
        const [4, 0],
        const [0, 4],
        // Extra marks that should not count as corner completion
        const [1, 1],
        const [2, 1],
        const [3, 1],
        const [2, 2],
      ]);
      expect(card.hasBingo(threeCornersPlusNoise, GameType.corners), isFalse);
    });

    test('tShape: requires top row and middle column together', () {
      final tShape = _drawnFor(card, [
        for (int col = 0; col < 5; col++) [col, 0],
        for (int row = 0; row < 5; row++) [2, row],
      ]);
      expect(card.hasBingo(tShape, GameType.tShape), isTrue);

      final topRowOnly = _drawnFor(card, [for (int col = 0; col < 5; col++) [col, 0]]);
      expect(card.hasBingo(topRowOnly, GameType.tShape), isFalse);

      final topRowPlusPartialMid = _drawnFor(card, [
        for (int col = 0; col < 5; col++) [col, 0],
        [2, 1],
        [2, 2],
        [2, 3],
      ]);
      expect(card.hasBingo(topRowPlusPartialMid, GameType.tShape), isFalse);
    });

    test('fullHouse: true only when every non-free cell is marked', () {
      final fullHouse = _allNonFreeDraws(card);
      expect(card.hasBingo(fullHouse, GameType.fullHouse), isTrue);

      final missingOne = Set<String>.from(fullHouse)
        ..remove(card.columns[4][4]);
      expect(card.hasBingo(missingOne, GameType.fullHouse), isFalse);
    });

    test('round sequence validation: each round has explicit pass/fail scenario', () {
      final cases = <GameType, Map<String, Set<String>>>{
        GameType.singleLine: {
          'pass': _drawnFor(card, [for (int col = 0; col < 5; col++) [col, 4]]),
          'fail': _drawnFor(card, const [
            [0, 4],
            [1, 4],
            [2, 4],
            [3, 4],
          ]),
        },
        GameType.twoLines: {
          'pass': _drawnFor(card, [
            for (int col = 0; col < 5; col++) [col, 3],
            for (int row = 0; row < 5; row++) [4, row],
          ]),
          'fail': _drawnFor(card, [for (int col = 0; col < 5; col++) [col, 3]]),
        },
        GameType.corners: {
          'pass': _drawnFor(card, const [
            [0, 0],
            [4, 0],
            [0, 4],
            [4, 4],
          ]),
          'fail': _drawnFor(card, const [
            [0, 0],
            [4, 0],
            [0, 4],
          ]),
        },
        GameType.tShape: {
          'pass': _drawnFor(card, [
            for (int col = 0; col < 5; col++) [col, 0],
            for (int row = 0; row < 5; row++) [2, row],
          ]),
          'fail': _drawnFor(card, [
            for (int col = 0; col < 5; col++) [col, 0],
            [2, 1],
            [2, 2],
            [2, 3],
          ]),
        },
        GameType.fullHouse: {
          'pass': _allNonFreeDraws(card),
          'fail': Set<String>.from(_allNonFreeDraws(card))..remove(card.columns[0][1]),
        },
      };

      for (final entry in cases.entries) {
        expect(
          card.hasBingo(entry.value['pass']!, entry.key),
          isTrue,
          reason: 'Expected pass case for ${entry.key}',
        );
        expect(
          card.hasBingo(entry.value['fail']!, entry.key),
          isFalse,
          reason: 'Expected fail case for ${entry.key}',
        );
      }
    });
  });
}

BingoCard _buildDeterministicCard() {
  final columns = List<List<String>>.generate(
    5,
    (col) => List<String>.generate(5, (row) => 'C$col-R$row'),
  );
  return BingoCard(cardNumber: 1, columns: columns);
}

Set<String> _drawnFor(BingoCard card, List<List<int>> cells) {
  final drawn = <String>{};
  for (final cell in cells) {
    final col = cell[0];
    final row = cell[1];
    if (col == 2 && row == 2) {
      continue;
    }
    drawn.add(card.columns[col][row]);
  }
  return drawn;
}

Set<String> _allNonFreeDraws(BingoCard card) {
  final drawn = <String>{};
  for (int col = 0; col < 5; col++) {
    for (int row = 0; row < 5; row++) {
      if (col == 2 && row == 2) {
        continue;
      }
      drawn.add(card.columns[col][row]);
    }
  }
  return drawn;
}
