/// Lightweight descriptor loaded from games_registry.json.
/// Does NOT contain cards — just enough to show the selection screen.
class GameDefinition {
  final String gameId;
  final String gameName;
  final String gameSubtitle;
  final String assetPath;
  final String description;

  const GameDefinition({
    required this.gameId,
    required this.gameName,
    required this.gameSubtitle,
    required this.assetPath,
    required this.description,
  });

  factory GameDefinition.fromJson(Map<String, dynamic> j) => GameDefinition(
        gameId: j['game_id'] as String,
        gameName: j['game_name'] as String,
        gameSubtitle: j['game_subtitle'] as String? ?? '',
        assetPath: j['asset_path'] as String,
        description: j['description'] as String? ?? '',
      );
}
