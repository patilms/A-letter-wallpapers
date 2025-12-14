import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/favorites_service.dart';
import 'viewer_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> _wallpapers = [];
  List<String> _favorites = [];
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _loadWallpapers();
    _loadFavorites();
  }

  Future<void> _loadWallpapers() async {
    final String response = await rootBundle.loadString(
      'assets/wallpapers.json',
    );
    final data = await json.decode(response);
    setState(() {
      _wallpapers = List<String>.from(data['wallpapers']);
    });
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getFavorites();
    setState(() {
      _favorites = favorites;
    });
  }

  // Refresh favorites when returning from ViewerPage
  void _refreshFavorites() {
    _loadFavorites();
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: _buildDrawer(),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: const Text(
                'A Letter Wallpaper',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: const Color.fromARGB(255, 130, 62, 188),
              iconTheme: const IconThemeData(color: Colors.white),
              floating: true,
              pinned: true,
              snap: true,
              bottom: const TabBar(
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(text: 'All Wallpapers'),
                  Tab(text: 'Favorites'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildGrid(_wallpapers),
              _buildGrid(_favorites, isFavorites: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color.fromARGB(255, 130, 62, 188)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'A Letter Wallpaper',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Best wallpapers for you',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.pop(context);
              _launchUrl('https://policies.google.com/privacy'); // Placebo URL
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Us'),
            onTap: () {
              Navigator.pop(context);
              // Show about dialog or navigate
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share App'),
            onTap: () {
              Navigator.pop(context);
              // Implement app sharing
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rate Us'),
            onTap: () {
              Navigator.pop(context);
              _launchUrl('https://play.google.com/store/apps'); // Placebo URL
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<String> wallpapers, {bool isFavorites = false}) {
    if (wallpapers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFavorites ? Icons.favorite_border : Icons.image_not_supported,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isFavorites ? 'No favorites yet' : 'No wallpapers found',
              style: const TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(4.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
        childAspectRatio: 0.6,
      ),
      itemCount: wallpapers.length,
      itemBuilder: (context, index) {
        final url = wallpapers[index];
        final heroTag = isFavorites ? 'fav_$url' : 'all_$url';

        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ViewerPage(wallpaperUrl: url, heroTag: heroTag),
              ),
            );
            _refreshFavorites(); // Refresh when returning
          },
          child: Hero(
            tag: heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                  if (!isFavorites) // Only show preview on main list mainly
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: const Text(
                          'Preview',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
