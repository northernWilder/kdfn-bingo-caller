import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'services/audio_service.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KdfnBingoApp());
}

class KdfnBingoApp extends StatelessWidget {
  const KdfnBingoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameState()..loadCards()),
        Provider(create: (_) => AudioService()..init()),
      ],
      child: MaterialApp(
        title: 'Retrofit Bingo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
                colorScheme: const ColorScheme.dark(
            primary: Color(0xFFE8B84B),
            surface: Color(0xFF16213E),
          ),
          useMaterial3: true,
          fontFamily: 'sans-serif',
        ),
        home: const _LoadingWrapper(),
      ),
    );
  }
}

class _LoadingWrapper extends StatelessWidget {
  const _LoadingWrapper();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameState>();
    if (game.allCards.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFE8B84B)),
              SizedBox(height: 20),
              Text('Loading 1,000 cards...',
                  style: TextStyle(color: Color(0xFFAAAAAA))),
            ],
          ),
        ),
      );
    }
    return const HomeScreen();
  }
}
