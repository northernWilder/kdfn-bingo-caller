import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../models/game_state.dart';
import '../models/bingo_card.dart';
import '../models/educational_draw.dart';
import '../services/audio_service.dart';
import 'check_card_screen.dart';
import 'round_summary_screen.dart';
import 'educational_draw_screen.dart';

class CallerScreen extends StatefulWidget {
  final EduSettings eduSettings;

  const CallerScreen({super.key, required this.eduSettings});

  @override
  State<CallerScreen> createState() => _CallerScreenState();
}

class _CallerScreenState extends State<CallerScreen> {
  bool _drawing = false;
  late ConfettiController _confetti;
  final TextEditingController _cardCheckCtrl = TextEditingController();

  // Educational draw state
  List<EducationalDraw> _eduDraws = [];
  int _eduIndex = 0;          // advances through each draw once per game
  int _drawsSinceLastEdu = 0; // tracks draws since last edu card

  bool get _hasRemainingEduDraws => _eduIndex < _eduDraws.length;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _loadEduDraws();
  }

  Future<void> _loadEduDraws() async {
    final draws = await EducationalDraw.loadAll();
    draws.shuffle(); // randomise order each game
    if (mounted) setState(() => _eduDraws = draws);
  }

  @override
  void dispose() {
    _confetti.dispose();
    _cardCheckCtrl.dispose();
    super.dispose();
  }

  // ── Draw logic ──────────────────────────────────────────────────────────────

  Future<void> _draw(BuildContext context) async {
    if (_drawing) return;
    final game = context.read<GameState>();
    final audio = context.read<AudioService>();
    if (game.allDrawn) return;

    setState(() => _drawing = true);
    await audio.playDrawSequence();
    game.drawNext();
    _drawsSinceLastEdu++;
    setState(() => _drawing = false);

    // Check everyN trigger after state update
    if (_hasRemainingEduDraws &&
        widget.eduSettings.shouldShowAfterDraw(_drawsSinceLastEdu)) {
      await _showEduDraw();
    }
  }

  Future<void> _showEduDraw() async {
    if (!_hasRemainingEduDraws) return;
    final draw = _eduDraws[_eduIndex];
    _eduIndex++;
    _drawsSinceLastEdu = 0;

    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => EducationalDrawScreen(
          draw: draw,
          onDismiss: () => Navigator.pop(context),
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  // ── Card check ──────────────────────────────────────────────────────────────

  void _checkCard(BuildContext context, int cardNum) {
    final game = context.read<GameState>();
    final audio = context.read<AudioService>();
    final hasBingo = game.checkCard(cardNum);
    if (hasBingo) {
      audio.playBingo();
      _confetti.play();
      game.recordBingo(cardNum);
    } else {
      audio.playNoBingo();
    }
    _showBingoResult(context, cardNum, hasBingo, game);
  }

  void _showBingoResult(BuildContext ctx, int cardNum, bool hasBingo, GameState game) {
    final card = game.allCards[cardNum - 1];
    final pattern = card.winningPattern(game.drawnValues, game.currentRound);

    showDialog(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          hasBingo ? '🎉 BINGO! Card #$cardNum' : '❌ No Bingo — Card #$cardNum',
          style: TextStyle(
            color: hasBingo ? const Color(0xFFE8B84B) : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          hasBingo
              ? 'Winning pattern: $pattern'
              : 'Card #$cardNum does not yet have a bingo for ${game.currentRound.displayName}.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK', style: TextStyle(color: Color(0xFFE8B84B))),
          ),
        ],
      ),
    );
  }

  // ── End round ───────────────────────────────────────────────────────────────

  void _endRound(BuildContext context) {
    final game = context.read<GameState>();
    final audio = context.read<AudioService>();
    audio.playRoundComplete();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoundSummaryScreen(
          roundIndex: game.currentRoundIndex,
          bingos: game.bingosPerRound[game.currentRoundIndex],
          drawnCount: game.drawnAddresses.length,
          onNext: game.isLastRound
              ? null
              : () async {
                  game.advanceRound();
                  Navigator.pop(context);
                  // Between-rounds edu trigger
                  if (_hasRemainingEduDraws &&
                      widget.eduSettings.shouldShowOnRoundStart()) {
                    await _showEduDraw();
                  }
                },
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, game),
                _buildRoundBadge(game),
                Expanded(child: _buildDrawArea(context, game)),
                _buildDrawnHistory(game),
                _buildBottomBar(context, game),
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
                Color(0xFF2E7D5E), Color(0xFFB54A1A),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, GameState game) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(bottom: BorderSide(color: Color(0xFF0F3460))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFE8B84B)),
            onPressed: () => Navigator.pop(context),
          ),
          const Text('Caller',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(
            '${game.drawnAddresses.length} drawn  ·  ${game.remaining} left',
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
          ),
          const SizedBox(width: 8),
          // Edu draw indicator chip
          if (widget.eduSettings.mode != EduTriggerMode.off)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D5E).withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2E7D5E).withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb_outline, size: 12, color: Color(0xFF7DC9A8)),
                  const SizedBox(width: 4),
                  Text(
                    widget.eduSettings.mode == EduTriggerMode.everyN
                        ? 'Edu: every ${widget.eduSettings.everyN}'
                        : 'Edu: rounds',
                    style: const TextStyle(color: Color(0xFF7DC9A8), fontSize: 11),
                  ),
                ],
              ),
            ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('Check Card'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F3460),
              foregroundColor: const Color(0xFFE8B84B),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              textStyle: const TextStyle(fontSize: 12),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckCardScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundBadge(GameState game) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF0F3460),
      child: Column(
        children: [
          Text(
            'Round ${game.currentRoundIndex + 1} of ${kRoundSequence.length}  —  ${game.currentRound.displayName}',
            style: const TextStyle(
                color: Color(0xFFE8B84B),
                fontWeight: FontWeight.bold,
                fontSize: 14),
            textAlign: TextAlign.center,
          ),
          Text(
            game.currentRound.description,
            style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawArea(BuildContext context, GameState game) {
    final last = game.lastDrawn;

    return GestureDetector(
      onTap: _drawing ? null : () => _draw(context),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 280,
              minHeight: 340,
              maxWidth: 440,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [Color(0xFF0F3460), Color(0xFF16213E)],
                  radius: 0.8,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8B84B), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8B84B).withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: last == null
                  ? _buildTapToStart()
                  : _buildLastDraw(last, game),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTapToStart() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.touch_app, color: Color(0xFFE8B84B), size: 64),
        SizedBox(height: 16),
        Text(
          'TAP TO DRAW',
          style: TextStyle(
            color: Color(0xFFE8B84B),
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'First address will be drawn',
          style: TextStyle(color: Color(0xFFAAAAAA)),
        ),
      ],
    );
  }

  Widget _buildLastDraw(DrawnAddress drawn, GameState game) {
    final game = context.read<GameState>();
    final colour = drawn.isWild
        ? const Color(0xFFE8B84B)
        : Color(game.colourForColumn(drawn.column));
    final colName = drawn.isWild
        ? 'WILD CARD'
        : game.labelForColumn(drawn.column);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: colour,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            colName,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          drawn.value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 72,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
        const SizedBox(height: 8),
        Text(
          drawn.fullAddress,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 18),
        ),
        if (drawn.isWild) ...[
          const SizedBox(height: 8),
          const Text(
            'Mark any unclaimed square!',
            style: TextStyle(
                color: Color(0xFFE8B84B),
                fontStyle: FontStyle.italic),
          ),
        ],
        const SizedBox(height: 20),
        if (!game.allDrawn)
          const Text(
            'TAP to draw next',
            style: TextStyle(color: Color(0xFF555577), fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildDrawnHistory(GameState game) {
    if (game.drawnAddresses.isEmpty) return const SizedBox.shrink();
    final history = game.drawnAddresses.reversed.skip(1).take(8).toList();
    if (history.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: history.length,
        itemBuilder: (_, i) {
          final d = history[i];
          final game = context.read<GameState>();
          final col = d.isWild
              ? const Color(0xFFE8B84B)
              : Color(game.colourForColumn(d.column));
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: col.withValues(alpha: 0.6)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(d.value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, GameState game) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Color(0xFF16213E),
        border: Border(top: BorderSide(color: Color(0xFF0F3460))),
      ),
      child: Row(
        children: [
          // Quick card check
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _cardCheckCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Card #',
                      hintStyle: const TextStyle(color: Color(0xFF555577)),
                      filled: true,
                      fillColor: const Color(0xFF0F3460),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final num = int.tryParse(_cardCheckCtrl.text);
                    if (num != null && num >= 1 && num <= game.allCards.length) {
                      _checkCard(context, num);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3460),
                    foregroundColor: const Color(0xFFE8B84B),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  child: const Text('CHECK'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.flag, size: 16),
            label: Text(game.isLastRound ? 'End Game' : 'End Round'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8B84B),
              foregroundColor: const Color(0xFF1A1A2E),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onPressed: () => _endRound(context),
          ),
        ],
      ),
    );
  }
}
