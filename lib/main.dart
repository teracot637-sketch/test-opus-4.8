import 'dart:convert';

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
  String? _nextUrl;
  bool _loading = true;
  String? _error;
  int _categoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final String? first = await _fetchUrl();
    if (!mounted) return;
    if (first == null) {
      setState(() {
        _error = 'Не удалось загрузить обои';
        _loading = false;
      });
      return;
    }
    setState(() {
      _imageUrl = first;
      _loading = false;
    });
    _prefetchNext();
  }

  Future<String?> _fetchUrl() async {
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

      if (resp.statusCode != 200) return null;

      final Map<String, dynamic> data =
          jsonDecode(resp.body) as Map<String, dynamic>;
      final List<dynamic>? results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final String? url =
          (results.first as Map<String, dynamic>)['url'] as String?;
      return (url == null || url.isEmpty) ? null : url;
    } catch (_) {
      return null;
    }
  }

  Future<void> _prefetchNext() async {
    final String? next = await _fetchUrl();
    if (next == null || !mounted) return;
    precacheImage(NetworkImage(next), context);
    _nextUrl = next;
  }

  void _showNext() {
    if (_nextUrl != null) {
      setState(() {
        _imageUrl = _nextUrl;
        _nextUrl = null;
        _error = null;
      });
      _prefetchNext();
    } else {
      _init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final double shortestSide = screenSize.shortestSide;
    final double fontSize = (shortestSide * 0.1).clamp(26.0, 64.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _loading ? null : _showNext,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _buildBackground(),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (_error != null) _buildError(),
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
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: const <Shadow>[
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black54,
                          offset: Offset(0, 1),
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
                      color: Colors.white.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w400,
                      shadows: const <Shadow>[
                        Shadow(blurRadius: 4, color: Colors.black38),
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
    return Image(
      image: NetworkImage(_imageUrl!),
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
              onPressed: _init,
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
