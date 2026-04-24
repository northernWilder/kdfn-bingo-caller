import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_definition.dart';
import '../models/game_state.dart';
import '../services/game_loader.dart';
import 'home_screen.dart';

/// Entry point shown before the home screen.
/// Loads the game registry, checks persistence, and gates access with a code.
class GameSelectScreen extends StatefulWidget {
  const GameSelectScreen({super.key});

  @override
  State<GameSelectScreen> createState() => _GameSelectScreenState();
}

class _GameSelectScreenState extends State<GameSelectScreen> {
  List<GameDefinition> _games = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final games = await GameLoader.loadRegistry();

      // Auto-unlock any games already persisted on this device
      for (final g in games) {
        if (await GameLoader.isUnlocked(g.gameId)) {
          await _loadGame(g, skipCodePrompt: true);
          return; // jump straight in if exactly one game is already unlocked
        }
      }

      if (mounted) setState(() { _games = games; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadGame(GameDefinition def, {bool skipCodePrompt = false}) async {
    if (!skipCodePrompt) {
      final entered = await _promptCode(def);
      if (entered == null) return; // user cancelled

      final data = await GameLoader.verifyAndLoad(def, entered);
      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect access code. Please try again.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      await GameLoader.persistUnlock(def.gameId);
      if (mounted) {
        context.read<GameState>().loadFromData(data);
        _navigateToHome();
      }
    } else {
      // Already unlocked — load without re-verifying code
      try {
        final data = await GameLoader.loadGameData(def);
        if (mounted) {
          context.read<GameState>().loadFromData(data);
          _navigateToHome();
        }
      } catch (_) {
        // Asset missing or corrupt — fall back to code prompt
        await GameLoader.revokeUnlock(def.gameId);
        if (mounted) setState(() { _games = [def]; _loading = false; });
      }
    }
  }

  Future<String?> _promptCode(GameDefinition def) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          def.gameName,
          style: const TextStyle(
              color: Color(0xFFE8B84B), fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              def.gameSubtitle,
              style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter access code to continue:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              autofocus: true,
              obscureText: true,
              style: const TextStyle(color: Colors.white, letterSpacing: 2),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: const TextStyle(color: Color(0xFF555577)),
                filled: true,
                fillColor: const Color(0xFF0F3460),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              onSubmitted: (_) => Navigator.pop(ctx, ctrl.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFFAAAAAA))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8B84B),
              foregroundColor: const Color(0xFF1A1A2E),
            ),
            child: const Text('Unlock', fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildGameList(),
      ),
    );
  }

  Widget _buildLoading() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFE8B84B)),
            SizedBox(height: 20),
            Text('Loading...', style: TextStyle(color: Color(0xFFAAAAAA))),
          ],
        ),
      );

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Failed to load game registry:\n$_error',
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );

  Widget _buildGameList() {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F3460), Color(0xFF16213E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/images/kdfn-logo.png', height: 52),
              const SizedBox(height: 20),
              const Text(
                'Retrofit Bingo',
                style: TextStyle(
                  color: Color(0xFFE8B84B),
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select a game to get started',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
              ),
            ],
          ),
        ),

        // Game list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _games.length,
            itemBuilder: (_, i) => _GameCard(
              def: _games[i],
              onTap: () => _loadGame(_games[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _GameCard extends StatelessWidget {
  final GameDefinition def;
  final VoidCallback onTap;

  const _GameCard({required this.def, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0F3460), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8B84B).withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.casino_outlined,
                  color: Color(0xFFE8B84B), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def.gameName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(def.gameSubtitle,
                      style: const TextStyle(
                          color: Color(0xFFAAAAAA), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(def.description,
                      style: const TextStyle(
                          color: Color(0xFF7DC9A8), fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.lock_outline,
                color: Color(0xFFE8B84B), size: 20),
          ],
        ),
      ),
    );
  }
}
