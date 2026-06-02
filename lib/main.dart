import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'test-opus-4.8',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WallpaperScreen(),
    );
  }
}

class WallpaperScreen extends StatefulWidget {
  const WallpaperScreen({super.key});

  @override
  State<WallpaperScreen> createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends State<WallpaperScreen> {
  static const List<String> _categories = <String>[
    'neko',
    'waifu',
    'kitsune',
    'husbando',
  ];

  String? _imageUrl;
  bool _loading = true;
  String? _error;
  int _categoryIndex = 0;
  Brightness _backgroundBrightness = Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadWallpaper();
  }

  Future<void> _loadWallpaper() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final String category = _categories[_categoryIndex % _categories.length];
    _categoryIndex++;

    try {
      final Uri uri = Uri.parse('https://nekos.best/api/v2/$category');
      final http.Response resp = await http.get(
        uri,
        headers: const <String, String>{
          'Accept': 'application/json',
          'User-Agent': 'test-opus-4.8',
        },
      ).timeout(const Duration(seconds: 15));

      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final Map<String, dynamic> data =
          jsonDecode(resp.body) as Map<String, dynamic>;
      final List<dynamic>? results = data['results'] as List<dynamic>?;
      final String? url = (results != null && results.isNotEmpty)
          ? (results.first as Map<String, dynamic>)['url'] as String?
          : null;

      if (url == null || url.isEmpty) {
        throw Exception('пустой ответ');
      }

      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить обои: $e';
        _loading = false;
      });
    }
  }

  Future<void> _updateContrastFromImage(ImageInfo info) async {
    try {
      final ui.Image image = info.image;
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;

      final int width = image.width;
      final int height = image.height;
      if (width == 0 || height == 0) return;

      final int startX = (width * 0.25).floor();
      final int endX = (width * 0.75).floor();
      final int startY = (height * 0.35).floor();
      final int endY = (height * 0.65).floor();

      double luminanceSum = 0;
      int count = 0;
      const int step = 8;

      for (int y = startY; y < endY; y += step) {
        for (int x = startX; x < endX; x += step) {
          final int offset = (y * width + x) * 4;
          if (offset + 2 >= byteData.lengthInBytes) continue;
          final int r = byteData.getUint8(offset);
          final int g = byteData.getUint8(offset + 1);
          final int b = byteData.getUint8(offset + 2);
          luminanceSum += (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
          count++;
        }
      }

      if (count == 0) return;
      final double avg = luminanceSum / count;
      final Brightness brightness =
          avg > 0.5 ? Brightness.light : Brightness.dark;

      if (!mounted) return;
      if (brightness != _backgroundBrightness) {
        setState(() {
          _backgroundBrightness = brightness;
        });
      }
    } catch (_) {
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool darkBackground = _backgroundBrightness == Brightness.dark;
    final Color textColor = darkBackground ? Colors.white : Colors.black;
    final Color outlineColor = darkBackground ? Colors.black : Colors.white;

    final Size screenSize = MediaQuery.sizeOf(context);
    final double shortestSide = screenSize.shortestSide;
    final double fontSize = (shortestSide * 0.11).clamp(28.0, 80.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _loading ? null : _loadWallpaper,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _buildBackground(),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (_error != null) _buildError(),
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.9,
                    colors: <Color>[
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.12),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Привет лох',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: 1.5,
                      shadows: <Shadow>[
                        Shadow(
                          blurRadius: 12,
                          color: outlineColor.withValues(alpha: 0.9),
                          offset: const Offset(0, 0),
                        ),
                        Shadow(
                          blurRadius: 3,
                          color: outlineColor.withValues(alpha: 0.9),
                          offset: const Offset(1.5, 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Нажми на экран — новые обои',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: (shortestSide * 0.03).clamp(10.0, 14.0),
                      color: textColor.withValues(alpha: 0.35),
                      fontWeight: FontWeight.w400,
                      shadows: <Shadow>[
                        Shadow(
                          blurRadius: 4,
                          color: outlineColor.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (_imageUrl == null) {
      return const ColoredBox(color: Colors.black);
    }
    final ImageProvider provider = NetworkImage(_imageUrl!);
    provider.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        _updateContrastFromImage(info);
      }),
    );
    return Image(
      image: provider,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return const ColoredBox(color: Colors.black);
      },
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.wifi_off, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Ошибка',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadWallpaper,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
