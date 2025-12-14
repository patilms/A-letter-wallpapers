import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _key = 'favorite_wallpapers';

  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  Future<void> toggleFavorite(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];

    if (favorites.contains(url)) {
      favorites.remove(url);
    } else {
      favorites.add(url);
    }

    await prefs.setStringList(_key, favorites);
  }

  Future<bool> isFavorite(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_key) ?? [];
    return favorites.contains(url);
  }
}
