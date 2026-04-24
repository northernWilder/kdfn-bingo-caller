import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'services/audio_service.dart';
import 'screens/game_select_screen.dart';

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
        // GameState starts empty — GameSelectScreen populates it after unlock
        ChangeNotifierProvider(create: (_) => GameState()),
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
        home: const GameSelectScreen(),
      ),
    );
  }
}
