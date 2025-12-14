import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'services/favorites_service.dart';

class ViewerPage extends StatefulWidget {
  final String wallpaperUrl;
  final String? heroTag;

  const ViewerPage({super.key, required this.wallpaperUrl, this.heroTag});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  bool _isProcessing = false;
  bool _isFavorite = false;
  static const platform = MethodChannel(
    'com.example.flutter_application_1/wallpaper',
  );
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final isFav = await _favoritesService.isFavorite(widget.wallpaperUrl);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    await _favoritesService.toggleFavorite(widget.wallpaperUrl);
    await _checkFavorite();
  }

  Future<void> _downloadImage() async {
    setState(() => _isProcessing = true);
    try {
      final file = await DefaultCacheManager().getSingleFile(
        widget.wallpaperUrl,
      );
      await Gal.putImage(file.path);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved to Gallery!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _shareImage() async {
    setState(() => _isProcessing = true);
    try {
      final file = await DefaultCacheManager().getSingleFile(
        widget.wallpaperUrl,
      );
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out this wallpaper!');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _setWallpaper() async {
    setState(() => _isProcessing = true);
    try {
      final file = await DefaultCacheManager().getSingleFile(
        widget.wallpaperUrl,
      );
      final bool result = await platform.invokeMethod('setWallpaper', {
        'filePath': file.path,
        'location': 1,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result ? 'Wallpaper set successfully' : 'Failed to set wallpaper',
          ),
        ),
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting wallpaper: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Hero(
              tag: widget.heroTag ?? widget.wallpaperUrl,
              child: CachedNetworkImage(
                imageUrl: widget.wallpaperUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.download,
                  label: 'Save',
                  onTap: _isProcessing ? null : _downloadImage,
                ),
                _buildActionButton(
                  icon: Icons.wallpaper,
                  label: 'Set',
                  onTap: _isProcessing ? null : _setWallpaper,
                  isPrimary: true,
                ),
                _buildActionButton(
                  icon: Icons.share,
                  label: 'Share',
                  onTap: _isProcessing ? null : _shareImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isPrimary
                ? Colors.deepPurple
                : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon),
            color: Colors.white,
            iconSize: 28,
            tooltip: label,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}
