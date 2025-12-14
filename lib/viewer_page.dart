import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ViewerPage extends StatefulWidget {
  final String wallpaperUrl;

  const ViewerPage({super.key, required this.wallpaperUrl});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  bool _isSettingWallpaper = false;
  static const platform = MethodChannel(
    'com.example.flutter_application_1/wallpaper',
  );

  Future<void> _setWallpaper() async {
    setState(() {
      _isSettingWallpaper = true;
    });

    try {
      final file = await DefaultCacheManager().getSingleFile(
        widget.wallpaperUrl,
      );

      // Invoke native method
      // location: 1 = Home, 2 = Lock, 3 = Both (Simple mapping for our native code)
      final bool result = await platform.invokeMethod('setWallpaper', {
        'filePath': file.path,
        'location': 1, // Defaulting to Home Screen for now
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
      if (mounted) {
        setState(() {
          _isSettingWallpaper = false;
        });
      }
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
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _isSettingWallpaper ? null : _setWallpaper,
                icon: _isSettingWallpaper
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wallpaper),
                label: Text(
                  _isSettingWallpaper ? 'Setting...' : 'Set Wallpaper',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
