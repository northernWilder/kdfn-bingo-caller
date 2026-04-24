import 'package:flutter/material.dart';
import '../models/bingo_card.dart';
import '../models/game_state.dart';

class RoundSummaryScreen extends StatelessWidget {
  final int roundIndex;
  final List<int> bingos;
  final int drawnCount;
  final VoidCallback? onNext;

  const RoundSummaryScreen({
    super.key,
    required this.roundIndex,
    required this.bingos,
    required this.drawnCount,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final roundType = kRoundSequence[roundIndex];
    final isLast = onNext == null;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Trophy / round icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3460),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8B84B), width: 2),
                  ),
                  child: const Center(
                    child: Text('🏆', style: TextStyle(fontSize: 40)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Round ${roundIndex + 1} Complete',
                style: const TextStyle(
                  color: Color(0xFFE8B84B),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                roundType.displayName,
                style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              _statRow('Addresses drawn', '$drawnCount'),
              _statRow('Winners this round', '${bingos.length}'),
              const SizedBox(height: 20),
              if (bingos.isNotEmpty) ...[
                const Text(
                  'Winning Cards',
                  style: TextStyle(
                      color: Color(0xFFE8B84B),
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: bingos.map((n) => _cardChip(n)).toList(),
                ),
              ] else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'No bingos were recorded for this round.',
                    style: TextStyle(color: Color(0xFFAAAAAA)),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Spacer(),
              if (!isLast) ...[
                Text(
                  'Next: Round ${roundIndex + 2}  —  ${kRoundSequence[roundIndex + 1].displayName}',
                  style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                Text(
                  kRoundSequence[roundIndex + 1].description,
                  style: const TextStyle(color: Color(0xFF666688), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8B84B),
                    foregroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                      'Start Round ${roundIndex + 2}: ${kRoundSequence[roundIndex + 1].displayName}'),
                ),
              ] else ...[
                const Text(
                  'Game Night Complete! 🎉',
                  style: TextStyle(
                      color: Color(0xFFE8B84B),
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Pop back to home
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8B84B),
                    foregroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home'),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Caller',
                    style: TextStyle(color: Color(0xFF666688))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFAAAAAA))),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFFE8B84B), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _cardChip(int n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8B84B)),
      ),
      child: Text(
        'Card #$n',
        style: const TextStyle(
            color: Color(0xFFE8B84B), fontWeight: FontWeight.bold),
      ),
    );
  }
}
