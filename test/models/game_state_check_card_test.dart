import 'package:flutter_test/flutter_test.dart';
import 'package:kdfn_bingo_caller/models/bingo_card.dart';
import 'package:kdfn_bingo_caller/models/game_state.dart';

void main() {
  group('GameState.checkCard', () {
    test('uses cardNumber identity, not list position', () {
      final card1 = _buildCard(1, 'A');
      final card2 = _buildCard(2, 'B');
      final game = GameState()
        ..allCards = [card2, card1] // Intentionally out of numeric order
        ..currentRoundIndex = kRoundSequence.indexOf(GameType.singleLine)
        ..drawnValues = _drawnFor(card2, [for (int c = 0; c < 5; c++) [c, 0]]);

      expect(game.checkCard(2), isTrue);
      expect(game.checkCard(1), isFalse);
    });

    test('returns false for invalid or missing card numbers', () {
      final game = GameState()..allCards = [_buildCard(1, 'A')];

      expect(game.checkCard(0), isFalse);
      expect(game.checkCard(-1), isFalse);
      expect(game.checkCard(999), isFalse);
    });

    test('correctly assesses each round for a specific card number', () {
      final card1 = _buildCard(1, 'A');
      final card2 = _buildCard(2, 'B');
      final game = GameState()
        ..allCards = [card1, card2];

      final roundCases = <GameType, Map<String, Set<String>>>{
        GameType.singleLine: {
          'win': _drawnFor(card2, [for (int c = 0; c < 5; c++) [c, 1]]),
          'nearMiss': _drawnFor(card2, const [
            [0, 1],
            [1, 1],
            [2, 1],
            [3, 1],
          ]),
        },
        GameType.twoLines: {
          'win': _drawnFor(card2, [
            for (int c = 0; c < 5; c++) [c, 0],
            for (int r = 0; r < 5; r++) [0, r],
          ]),
          'nearMiss': _drawnFor(card2, [
            for (int c = 0; c < 5; c++) [c, 0],
            [0, 1],
            [0, 2],
            [0, 3],
          ]),
        },
        GameType.corners: {
          'win': _drawnFor(card2, const [
            [0, 0],
            [4, 0],
            [0, 4],
            [4, 4],
          ]),
          'nearMiss': _drawnFor(card2, const [
            [0, 0],
            [4, 0],
            [0, 4],
          ]),
        },
        GameType.tShape: {
          'win': _drawnFor(card2, [
            for (int c = 0; c < 5; c++) [c, 0],
            for (int r = 0; r < 5; r++) [2, r],
          ]),
          'nearMiss': _drawnFor(card2, [
            for (int c = 0; c < 5; c++) [c, 0],
            [2, 1],
            [2, 2],
            [2, 3],
          ]),
        },
        GameType.fullHouse: {
          'win': _allNonFreeDraws(card2),
          'nearMiss': Set<String>.from(_allNonFreeDraws(card2))
            ..remove(card2.columns[4][4]),
        },
      };

      for (final roundCase in roundCases.entries) {
        final roundIndex = kRoundSequence.indexOf(roundCase.key);
        expect(roundIndex, isNot(-1));
        game.currentRoundIndex = roundIndex;

        game.drawnValues = roundCase.value['nearMiss']!;
        expect(
          game.checkCard(2),
          isFalse,
          reason: 'Card 2 should not bingo on near miss for ${roundCase.key}',
        );

        game.drawnValues = roundCase.value['win']!;
        expect(
          game.checkCard(2),
          isTrue,
          reason: 'Card 2 should bingo in ${roundCase.key}',
        );
        expect(
          game.checkCard(1),
          isFalse,
          reason: 'Card 1 should not false-positive in ${roundCase.key}',
        );
      }
    });
  });
}

BingoCard _buildCard(int cardNumber, String prefix) {
  return BingoCard(
    cardNumber: cardNumber,
    columns: List<List<String>>.generate(
      5,
      (col) => List<String>.generate(5, (row) => '$prefix-C$col-R$row'),
    ),
  );
}

Set<String> _drawnFor(BingoCard card, List<List<int>> cells) {
  final out = <String>{};
  for (final cell in cells) {
    final col = cell[0];
    final row = cell[1];
    if (col == 2 && row == 2) {
      continue;
    }
    out.add(card.columns[col][row]);
  }
  return out;
}

Set<String> _allNonFreeDraws(BingoCard card) {
  final out = <String>{};
  for (int col = 0; col < 5; col++) {
    for (int row = 0; row < 5; row++) {
      if (col == 2 && row == 2) {
        continue;
      }
      out.add(card.columns[col][row]);
    }
  }
  return out;
}
