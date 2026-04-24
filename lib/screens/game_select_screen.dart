import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_definition.dart';
import '../models/game_state.dart';
import '../services/game_loader.dart';
import 'home_screen.dart';

/// Shown every time the app loads — lists available games, indicates which
/// are already unlocked, and prompts for an access code when needed.
class GameSelectScreen extends StatefulWidget {
  const GameSelectScreen({super.key});

  @override
  State<GameSelectScreen> createState() => _GameSelectScreenState();
}

class _GameSelectScreenState extends State<GameSelectScreen> {
  List<GameDefinition> _games = [];
  // Which game IDs are already unlocked on this device
  Set<String> _unlocked = {};
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

      // Check persistence for all games in parallel
      final unlocked = <String>{};
      await Future.wait(games.map((g) async {
        if (await GameLoader.isUnlocked(g.gameId)) unlocked.add(g.gameId);
      }));

      if (mounted) {
        setState(() {
          _games = games;
          _unlocked = unlocked;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _selectGame(GameDefinition def) async {
    final isUnlocked = _unlocked.contains(def.gameId);

    if (isUnlocked) {
      // Already unlocked — load directly, no code prompt
      setState(() => _loading = true);
      try {
        final data = await GameLoader.loadGameData(def);
        if (mounted) {
          context.read<GameState>().loadFromData(data, logoAssetPath: def.effectiveLogo);
          _navigateToHome();
        }
      } catch (_) {
        // Asset gone or corrupt — revoke and re-prompt
        await GameLoader.revokeUnlock(def.gameId);
        setState(() {
          _unlocked.remove(def.gameId);
          _loading = false;
        });
        if (mounted) _selectGame(def);
      }
    } else {
      // Locked — prompt for code
      final entered = await _promptCode(def);
      if (entered == null) return; // user cancelled

      setState(() => _loading = true);
      final data = await GameLoader.verifyAndLoad(def, entered);

      if (data == null) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Incorrect access code — please try again.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      await GameLoader.persistUnlock(def.gameId);
      if (mounted) {
        setState(() => _unlocked.add(def.gameId));
        context.read<GameState>().loadFromData(data, logoAssetPath: def.effectiveLogo);
        _navigateToHome();
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
            if (def.gameSubtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  def.gameSubtitle,
                  style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                ),
              ),
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
            child: const Text('Unlock',
                style: TextStyle(fontWeight: FontWeight.bold)),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildContent(),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load games:\n$_error',
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => setState(() { _error = null; _loading = true; _init(); }),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8B84B),
                    foregroundColor: const Color(0xFF1A1A2E)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );

  Widget _buildContent() {
    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
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
              Image.asset('assets/images/ebs-logo-light.png', height: 48),
              const SizedBox(height: 18),
              const Text(
                'Retrofit Bingo',
                style: TextStyle(
                  color: Color(0xFFE8B84B),
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select a game to get started',
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
              ),
            ],
          ),
        ),

        // ── Access code hint ─────────────────────────────────────────────────
        if (_unlocked.isEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3460).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFE8B84B).withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFE8B84B), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tap a game to enter your access code. '
                    'Unlocked games are remembered on this device.',
                    style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // ── Game list ────────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _games.length,
            itemBuilder: (_, i) {
              final def = _games[i];
              final unlocked = _unlocked.contains(def.gameId);
              return _GameCard(
                def: def,
                unlocked: unlocked,
                onTap: () => _selectGame(def),
                onForget: unlocked
                    ? () async {
                        await GameLoader.revokeUnlock(def.gameId);
                        setState(() => _unlocked.remove(def.gameId));
                      }
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Game card widget ───────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final GameDefinition def;
  final bool unlocked;
  final VoidCallback onTap;
  final VoidCallback? onForget;

  const _GameCard({
    required this.def,
    required this.unlocked,
    required this.onTap,
    this.onForget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? const Color(0xFF2E7D5E).withValues(alpha: 0.7)
                : const Color(0xFF0F3460),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: unlocked
                  ? const Color(0xFF2E7D5E).withValues(alpha: 0.08)
                  : const Color(0xFFE8B84B).withValues(alpha: 0.04),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            // Logo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: unlocked
                    ? const Color(0xFF2E7D5E).withValues(alpha: 0.15)
                    : const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(6),
              child: Image.asset(
                def.effectiveLogo,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    def.gameName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  if (def.gameSubtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(def.gameSubtitle,
                        style: const TextStyle(
                            color: Color(0xFFAAAAAA), fontSize: 12)),
                  ],
                  if (def.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(def.description,
                        style: const TextStyle(
                            color: Color(0xFF7DC9A8), fontSize: 11)),
                  ],
                  if (unlocked) ...[
                    const SizedBox(height: 6),
                    const Text(
                      'Unlocked on this device',
                      style: TextStyle(
                          color: Color(0xFF2E7D5E),
                          fontSize: 11,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),

            // Lock icon + forget button
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  unlocked ? Icons.lock_open : Icons.lock_outline,
                  color: unlocked
                      ? const Color(0xFF7DC9A8)
                      : const Color(0xFFE8B84B),
                  size: 20,
                ),
                if (onForget != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onForget,
                    child: const Text(
                      'Forget',
                      style: TextStyle(
                          color: Color(0xFF555577),
                          fontSize: 10,
                          decoration: TextDecoration.underline,
                          decorationColor: Color(0xFF555577)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
