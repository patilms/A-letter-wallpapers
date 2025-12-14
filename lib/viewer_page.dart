import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

class ViewerPage extends StatefulWidget {
  final String wallpaperUrl;

  const ViewerPage({super.key, required this.wallpaperUrl});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  bool _isProcessing = false;
  static const platform = MethodChannel(
    'com.example.flutter_application_1/wallpaper',
  );

  Future<void> _downloadImage() async {
    setState(() => _isProcessing = true);
    try {
      final file = await DefaultCacheManager().getSingleFile(
        widget.wallpaperUrl,
      );

      // Request permission only if declared in manifest (handled by Gal mostly) or handled by OS
      // Gal.putImage saves to gallery
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
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              widget.wallpaperUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              },
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
