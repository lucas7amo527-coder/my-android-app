import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ProDjApp());
}

class ProDjApp extends StatelessWidget {
  const ProDjApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DJ Jay Chronix Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0B0E),
      ),
      home: const ProDjScreen(),
    );
  }
}

class ProDjScreen extends StatefulWidget {
  const ProDjScreen({super.key});

  @override
  State<ProDjScreen> createState() => _ProDjScreenState();
}

class _ProDjScreenState extends State<ProDjScreen> {
  final AudioPlayer _playerA = AudioPlayer();
  final AudioPlayer _playerB = AudioPlayer();

  // Deck A State (Cyan Blue)
  String _trackA = 'Tap Load Icon ->';
  bool _playingA = false;
  double _pitchA = 0.0; // -10% to +10%
  Duration _posA = Duration.zero;
  Duration _durA = const Duration(minutes: 3, seconds: 45);
  final Map<int, Duration> _cuesA = {};
  int _loopBeatsA = 1;
  String _activeFxA = '';

  // Deck B State (Bright Orange)
  String _trackB = '<- Tap Load Icon';
  bool _playingB = false;
  double _pitchB = 0.0;
  Duration _posB = Duration.zero;
  Duration _durB = const Duration(minutes: 3, seconds: 20);
  final Map<int, Duration> _cuesB = {};
  int _loopBeatsB = 1;
  String _activeFxB = '';

  double _crossfader = 0.5;
  Timer? _waveTimer;
  double _wavePhase = 0.0;

  static const Color cyanAccent = Color(0xFF2196F3);
  static const Color orangeAccent = Color(0xFFFF6D00);
  static const Color panelDark = Color(0xFF16181D);
  static const Color padDark = Color(0xFF23262E);

  @override
  void initState() {
    super.initState();
    _updateCrossfader();

    _playerA.onPositionChanged.listen((p) {
      if (mounted) setState(() => _posA = p);
    });
    _playerA.onDurationChanged.listen((d) {
      if (mounted && d.inMilliseconds > 0) setState(() => _durA = d);
    });
    _playerA.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingA = false);
    });

    _playerB.onPositionChanged.listen((p) {
      if (mounted) setState(() => _posB = p);
    });
    _playerB.onDurationChanged.listen((d) {
      if (mounted && d.inMilliseconds > 0) setState(() => _durB = d);
    });
    _playerB.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingB = false);
    });

    _waveTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_playingA || _playingB) {
        setState(() => _wavePhase += 0.25);
      }
    });
  }

  void _updateCrossfader() {
    double volA = _crossfader <= 0.5 ? 1.0 : (1.0 - _crossfader) * 2;
    double volB = _crossfader >= 0.5 ? 1.0 : _crossfader * 2;
    _playerA.setVolume(volA.clamp(0.0, 1.0));
    _playerB.setVolume(volB.clamp(0.0, 1.0));
  }

  Future<void> _loadTrack(bool isA) async {
    final res = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (res != null && res.files.single.path != null) {
      final path = res.files.single.path!;
      final name = res.files.single.name;
      if (isA) {
        await _playerA.setSourceDeviceFile(path);
        setState(() {
          _trackA = name;
          _playingA = false;
          _posA = Duration.zero;
          _cuesA.clear();
        });
      } else {
        await _playerB.setSourceDeviceFile(path);
        setState(() {
          _trackB = name;
          _playingB = false;
          _posB = Duration.zero;
          _cuesB.clear();
        });
      }
    }
  }

  Future<void> _togglePlay(bool isA) async {
    if (isA) {
      if (_playingA) {
        await _playerA.pause();