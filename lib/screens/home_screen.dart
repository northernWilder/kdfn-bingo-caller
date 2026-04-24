import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/bingo_card.dart';
import '../services/audio_service.dart';
import 'caller_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: game.allCards.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFE8B84B)),
                    )
                  : _buildContent(context, game),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F3460), Color(0xFF16213E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Image.asset('assets/images/kdfn-logo.png', height: 56),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Retrofit Bingo',
                style: TextStyle(
                  color: Color(0xFFE8B84B),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'KDFN Community Retrofit Initiative',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Consumer<AudioService>(
            builder: (ctx, audio, _) => IconButton(
              icon: Icon(
                audio.muted ? Icons.volume_off : Icons.volume_up,
                color: const Color(0xFFE8B84B),
              ),
              onPressed: () {
                audio.toggleMute();
                (ctx as Element).markNeedsBuild();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, GameState game) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _buildInfoCard(game),
          const SizedBox(height: 24),
          _buildRoundSelector(context, game),
          const SizedBox(height: 32),
          _buildStartButton(context, game),
          const SizedBox(height: 20),
          _buildRulesCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(GameState game) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0F3460)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('${game.allCards.length}', 'Cards in Play'),
          _divider(),
          _stat('${game.columnPools.values.fold(0, (a, b) => a + b.length) + 2}', 'Draw Slips'),
          _divider(),
          _stat('${kRoundSequence.length}', 'Rounds'),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Color(0xFFE8B84B),
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 11)),
        ],
      );

  Widget _divider() => Container(
        height: 40,
        width: 1,
        color: const Color(0xFF0F3460),
      );

  Widget _buildRoundSelector(BuildContext context, GameState game) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Round Sequence',
          style: TextStyle(
              color: Color(0xFFE8B84B),
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...kRoundSequence.asMap().entries.map((e) {
          final index = e.key;
          final type = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0F3460)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3460),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: Color(0xFFE8B84B),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type.displayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      Text(type.description,
                          style: const TextStyle(
                              color: Color(0xFFAAAAAA), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStartButton(BuildContext context, GameState game) {
    return ElevatedButton(
      onPressed: () {
        context.read<GameState>().startGame();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CallerScreen()),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8B84B),
        foregroundColor: const Color(0xFF1A1A2E),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle:
            const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      child: const Text('START GAME NIGHT'),
    );
  }

  Widget _buildRulesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF0F3460)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to Play',
              style: TextStyle(
                  color: Color(0xFFE8B84B),
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          SizedBox(height: 8),
          Text(
            '• Addresses are drawn one at a time from the hat\n'
            '• Players mark their card if the house number appears in the matching street column\n'
            '• Wild card (77 Long Lake Rd) — mark any unclaimed square\n'
            '• Drawn addresses carry over into each new round\n'
            '• Check a card number to instantly verify if it has bingo',
            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }
}
