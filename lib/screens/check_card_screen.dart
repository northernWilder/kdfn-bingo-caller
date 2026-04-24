import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/bingo_card.dart';
import '../services/audio_service.dart';
import 'package:confetti/confetti.dart';


class CheckCardScreen extends StatefulWidget {
  const CheckCardScreen({super.key});

  @override
  State<CheckCardScreen> createState() => _CheckCardScreenState();
}

class _CheckCardScreenState extends State<CheckCardScreen> {
  final _ctrl = TextEditingController();
  int? _cardNum;
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confetti.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _check(BuildContext context) {
    final n = int.tryParse(_ctrl.text);
    final game = context.read<GameState>();
    if (n == null || n < 1 || n > game.allCards.length) return;
    setState(() => _cardNum = n);
    final hasBingo = game.checkCard(n);
    final audio = context.read<AudioService>();
    if (hasBingo) {
      audio.playBingo();
      _confetti.play();
      game.recordBingo(n);
    } else {
      audio.playNoBingo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Check a Card',
            style: TextStyle(color: Color(0xFFE8B84B))),
        iconTheme: const IconThemeData(color: Color(0xFFE8B84B)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSearch(context, game),
                const SizedBox(height: 20),
                if (_cardNum != null) _buildCardDisplay(context, game),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                Color(0xFFE8B84B), Colors.white, Color(0xFF1B5E7B),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context, GameState game) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Enter card number (1–${game.allCards.length})',
              hintStyle: const TextStyle(color: Color(0xFF555577)),
              filled: true,
              fillColor: const Color(0xFF16213E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0F3460)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF0F3460)),
              ),
            ),
            onSubmitted: (_) => _check(context),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => _check(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8B84B),
            foregroundColor: const Color(0xFF1A1A2E),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          child: const Text('CHECK'),
        ),
      ],
    );
  }

  Widget _buildCardDisplay(BuildContext context, GameState game) {
    final cardNum = _cardNum!;
    final card = game.allCards[cardNum - 1];
    final hasBingo = game.checkCard(cardNum);
    final pattern = card.winningPattern(game.drawnValues, game.currentRound);

    return Column(
      children: [
        // Result banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasBingo
                ? const Color(0xFFE8B84B).withValues(alpha: 0.15)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: hasBingo ? const Color(0xFFE8B84B) : Colors.redAccent),
          ),
          child: Column(
            children: [
              Text(
                hasBingo ? '🎉  BINGO!' : '❌  No Bingo',
                style: TextStyle(
                  color: hasBingo ? const Color(0xFFE8B84B) : Colors.redAccent,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasBingo && pattern != null) ...[
                const SizedBox(height: 4),
                Text(
                  pattern,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'Card #$cardNum  ·  Round: ${game.currentRound.displayName}',
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Card grid
        _buildGrid(card, game),
      ],
    );
  }

  Widget _buildGrid(BingoCard card, GameState game) {
    final colKeys = game.columnPools.keys.toList();
    final colW = (MediaQuery.of(context).size.width - 40) / 5;
    const hdrH = 44.0;
    const cellH = 48.0;

    return Column(
      children: [
        // Header row
        Row(
          children: List.generate(colKeys.length, (ci) {
            final colKey = ci < colKeys.length ? colKeys[ci] : '';
            final colColour = Color(game.colourForColumn(colKey));
            return Container(
              width: colW,
              height: hdrH,
              decoration: BoxDecoration(
                color: colColour,
                border: Border.all(color: Colors.black26, width: 0.5),
              ),
              child: Center(
                child: Text(
                  game.labelForColumn(colKey),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          }),
        ),
        // Cell rows
        ...List.generate(5, (ri) {
          return Row(
            children: List.generate(colKeys.length, (ci) {
              final isFree = ci == 2 && ri == 2;
              final val = isFree ? 'FREE' : card.columns[ci][ri];
              final marked = card.isCellMarked(ci, ri, game.drawnValues);
              final colKey = ci < colKeys.length ? colKeys[ci] : '';
              final colColour = Color(game.colourForColumn(colKey));
              final freeColKey = colKeys.length > 2 ? colKeys[2] : colKey;
              final freeColour = Color(game.colourForColumn(freeColKey));

              Color bg;
              Color textColor;
              if (isFree) {
                bg = freeColour.withValues(alpha: 0.7);
                textColor = Colors.white;
              } else if (marked) {
                bg = colColour.withValues(alpha: 0.6);
                textColor = Colors.white;
              } else {
                bg = ri.isEven ? const Color(0xFF1E1E3A) : const Color(0xFF1A1A2E);
                textColor = const Color(0xFF888899);
              }

              return Container(
                width: colW,
                height: cellH,
                decoration: BoxDecoration(
                  color: bg,
                  border: Border.all(color: const Color(0xFF2A2A4A), width: 0.5),
                ),
                child: Center(
                  child: isFree
                      ? Image.asset(game.logoPath,
                          width: 32, height: 32)
                      : Text(
                          val,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: marked
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: val.length > 3 ? 13 : 16,
                          ),
                        ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}
