// Model representing a single bingo card and its state during a game.

class BingoCard {
  final int cardNumber;
  // columns[colIndex][rowIndex] — matches JSON order
  final List<List<String>> columns;

  const BingoCard({required this.cardNumber, required this.columns});

  factory BingoCard.fromJson(Map<String, dynamic> json) {
    final cols = json['columns'] as Map<String, dynamic>;
    final colOrder = [
      'MURPHY',
      'HANNA',
      'McCANDLESS',
      'SWAN_CROW_OBRIEN',
      'MC_STREETS',
    ];
    final List<List<String>> columns = colOrder.map((key) {
      return (cols[key] as List).map((v) => v.toString()).toList();
    }).toList();
    return BingoCard(
      cardNumber: json['card_number'] as int,
      columns: columns,
    );
  }

  // Returns the value at [col][row], 'FREE' for centre
  String cellValue(int col, int row) {
    if (col == 2 && row == 2) return 'FREE';
    return columns[col][row];
  }

  // Check if a cell is marked given the set of drawn values and game type
  bool isCellMarked(int col, int row, Set<String> drawn) {
    if (col == 2 && row == 2) return true; // FREE always marked
    return drawn.contains(columns[col][row]);
  }

  // Check all winning patterns for the given game type
  bool hasBingo(Set<String> drawn, GameType gameType) {
    switch (gameType) {
      case GameType.singleLine:
        return _checkSingleLine(drawn);
      case GameType.twoLines:
        return _checkTwoLines(drawn);
      case GameType.corners:
        return _checkCorners(drawn);
      case GameType.tShape:
        return _checkTShape(drawn);
      case GameType.fullHouse:
        return _checkFullHouse(drawn);
      case GameType.coverAll:
        return _checkFullHouse(drawn);
    }
  }

  bool _marked(int col, int row, Set<String> drawn) =>
      isCellMarked(col, row, drawn);

  bool _checkRow(int row, Set<String> drawn) =>
      List.generate(5, (c) => _marked(c, row, drawn)).every((m) => m);

  bool _checkCol(int col, Set<String> drawn) =>
      List.generate(5, (r) => _marked(col, r, drawn)).every((m) => m);

  bool _checkDiagMain(Set<String> drawn) =>
      List.generate(5, (i) => _marked(i, i, drawn)).every((m) => m);

  bool _checkDiagAnti(Set<String> drawn) =>
      List.generate(5, (i) => _marked(i, 4 - i, drawn)).every((m) => m);

  bool _checkSingleLine(Set<String> drawn) {
    for (int r = 0; r < 5; r++) {
      if (_checkRow(r, drawn)) return true;
    }
    for (int c = 0; c < 5; c++) {
      if (_checkCol(c, drawn)) return true;
    }
    if (_checkDiagMain(drawn)) return true;
    if (_checkDiagAnti(drawn)) return true;
    return false;
  }

  bool _checkTwoLines(Set<String> drawn) {
    int lines = 0;
    for (int r = 0; r < 5; r++) {
      if (_checkRow(r, drawn)) lines++;
    }
    for (int c = 0; c < 5; c++) {
      if (_checkCol(c, drawn)) lines++;
    }
    if (_checkDiagMain(drawn)) lines++;
    if (_checkDiagAnti(drawn)) lines++;
    return lines >= 2;
  }

  bool _checkCorners(Set<String> drawn) =>
      _marked(0, 0, drawn) &&
      _marked(4, 0, drawn) &&
      _marked(0, 4, drawn) &&
      _marked(4, 4, drawn);

  bool _checkTShape(Set<String> drawn) {
    // Top row + middle column
    final topRow = List.generate(5, (c) => _marked(c, 0, drawn)).every((m) => m);
    final midCol = List.generate(5, (r) => _marked(2, r, drawn)).every((m) => m);
    return topRow && midCol;
  }

  bool _checkFullHouse(Set<String> drawn) {
    for (int c = 0; c < 5; c++) {
      for (int r = 0; r < 5; r++) {
        if (!_marked(c, r, drawn)) return false;
      }
    }
    return true;
  }

  // Returns a description of which winning pattern is completed
  String? winningPattern(Set<String> drawn, GameType gameType) {
    if (!hasBingo(drawn, gameType)) return null;
    switch (gameType) {
      case GameType.corners:
        return 'Four Corners';
      case GameType.tShape:
        return 'T-Shape';
      case GameType.fullHouse:
      case GameType.coverAll:
        return 'Full House';
      default:
        for (int r = 0; r < 5; r++) {
          if (_checkRow(r, drawn)) return 'Row ${r + 1}';
        }
        for (int c = 0; c < 5; c++) {
          if (_checkCol(c, drawn)) {
            return 'Column ${c + 1}';
          }
        }
        if (_checkDiagMain(drawn)) return 'Diagonal (↘)';
        if (_checkDiagAnti(drawn)) return 'Diagonal (↙)';
        return 'Bingo!';
    }
  }
}

enum GameType {
  singleLine,
  twoLines,
  corners,
  tShape,
  fullHouse,
  coverAll,
}

extension GameTypeInfo on GameType {
  String get displayName {
    switch (this) {
      case GameType.singleLine:
        return 'Single Line';
      case GameType.twoLines:
        return 'Two Lines';
      case GameType.corners:
        return 'Four Corners';
      case GameType.tShape:
        return 'T-Shape';
      case GameType.fullHouse:
        return 'Full House';
      case GameType.coverAll:
        return 'Cover All';
    }
  }

  String get description {
    switch (this) {
      case GameType.singleLine:
        return 'Any row, column, or diagonal';
      case GameType.twoLines:
        return 'Any two lines (rows, columns, or diagonals)';
      case GameType.corners:
        return 'All four corner squares';
      case GameType.tShape:
        return 'Top row + middle column';
      case GameType.fullHouse:
        return 'All 25 squares covered';
      case GameType.coverAll:
        return 'Every single square — the ultimate challenge';
    }
  }

  String get emoji {
    switch (this) {
      case GameType.singleLine:
        return '━';
      case GameType.twoLines:
        return '⊞';
      case GameType.corners:
        return '◻';
      case GameType.tShape:
        return 'T';
      case GameType.fullHouse:
        return '⬛';
      case GameType.coverAll:
        return '🏆';
    }
  }
}
