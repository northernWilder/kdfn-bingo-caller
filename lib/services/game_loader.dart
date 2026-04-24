import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_definition.dart';

/// Handles game registry loading, access-code verification, and
/// session persistence via shared_preferences.
class GameLoader {
  static const _prefKeyPrefix = 'unlocked_game_';

  // ── Registry ───────────────────────────────────────────────────────────────

  static Future<List<GameDefinition>> loadRegistry() async {
    final raw = await rootBundle.loadString('assets/data/games_registry.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return (data['games'] as List)
        .map((j) => GameDefinition.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // ── Access code verification ───────────────────────────────────────────────

  /// Loads the full game JSON for [def] and checks [enteredCode] against
  /// the access_code field. Returns the raw decoded data on success, null
  /// on failure (wrong code or missing field).
  static Future<Map<String, dynamic>?> verifyAndLoad(
      GameDefinition def, String enteredCode) async {
    final raw = await rootBundle.loadString(def.assetPath);
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final storedCode = data['access_code'] as String?;
    if (storedCode == null || storedCode.trim() != enteredCode.trim()) {
      return null;
    }
    return data;
  }

  /// Loads a game JSON without checking the code (used after persistence hit).
  static Future<Map<String, dynamic>> loadGameData(GameDefinition def) async {
    final raw = await rootBundle.loadString(def.assetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  /// Persists that [gameId] has been unlocked on this device.
  static Future<void> persistUnlock(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefKeyPrefix$gameId', true);
  }

  /// Returns true if [gameId] was previously unlocked on this device.
  static Future<bool> isUnlocked(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefKeyPrefix$gameId') ?? false;
  }

  /// Revokes a previously stored unlock (e.g. sign-out / reset).
  static Future<void> revokeUnlock(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefKeyPrefix$gameId');
  }
}
