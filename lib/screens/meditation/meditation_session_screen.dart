import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';
import 'package:just_audio/just_audio.dart';

class MeditationSessionScreen extends StatefulWidget {
  final String title;
  final String emoji;
  final bool quotesEnabled;
  final bool musicEnabled;
  final VoidCallback? onFinish;

  const MeditationSessionScreen({
    super.key,
    required this.title,
    required this.emoji,
    required this.quotesEnabled,
    required this.musicEnabled,
    this.onFinish,
  });

  @override
  State<MeditationSessionScreen> createState() => _MeditationSessionScreenState();
}

class _MeditationSessionScreenState extends State<MeditationSessionScreen> {
  int _seconds = 5 * 60;
  Timer? _timer;
  bool _running = false;

  // ✅ AUDIO
  final AudioPlayer _player = AudioPlayer();
  bool _audioReady = false;
  bool _audioError = false;
  String _audioErrorMsg = "";

  // ✅ IMPORTANT: these strings MUST exactly match your pubspec + file names on disk
  final List<String> _playlist = const [
    'assets/audio/Bamboo_Flute.mp3',
    'assets/audio/birds_chirping.mp3',
    'assets/audio/ocean_waves.mp3',
    'assets/audio/Short_Fireplace.mp3',
  ];

  final List<String> _quotes = const [
    "Breathe in calm, breathe out stress.",
    "Let thoughts pass like clouds.",
    "You are safe. You are present.",
    "Slow breath. Soft mind.",
    "One minute at a time.",
  ];

  String _quote = "Breathe in calm, breathe out stress.";

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (!widget.musicEnabled) return;

    try {
      setState(() {
        _audioReady = false;
        _audioError = false;
        _audioErrorMsg = "";
      });

      // Build playlist
      final sources = _playlist.map((p) => AudioSource.asset(p)).toList();
      final list = ConcatenatingAudioSource(children: sources);

      await _player.setAudioSource(
        list,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );

      await _player.setLoopMode(LoopMode.all);

      if (!mounted) return;
      setState(() => _audioReady = true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _audioError = true;
        _audioReady = false;
        _audioErrorMsg = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _setRandomQuote() {
    final copy = [..._quotes]..shuffle();
    setState(() => _quote = copy.first);
  }

  void _start() async {
    if (_running) return;

    setState(() => _running = true);

    if (widget.quotesEnabled) _setRandomQuote();

    // ✅ Start audio if enabled
    if (widget.musicEnabled && _audioReady && !_audioError) {
      try {
        await _player.play();
      } catch (_) {}
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _running = false;
          t.cancel();
        }
      });

      if (widget.quotesEnabled && _running && _seconds % 12 == 0) {
        _setRandomQuote();
      }

      if (_seconds == 0) {
        _stopAudio();
      }
    });
  }

  Future<void> _stopAudio() async {
    if (!widget.musicEnabled) return;
    try {
      await _player.stop();
      // reset playlist position
      await _player.seek(Duration.zero, index: 0);
    } catch (_) {}
  }

  void _finish() async {
    _timer?.cancel();
    await _stopAudio();
    setState(() => _running = false);
    widget.onFinish?.call();
    if (mounted) Navigator.pop(context);
  }

  void _reset() async {
    _timer?.cancel();
    await _stopAudio();
    setState(() {
      _running = false;
      _seconds = 5 * 60;
      _quote = _quotes.first;
    });
  }

  String _format(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return "${m.toString().padLeft(2, '0')} min ${sec.toString().padLeft(2, '0')} s";
  }

  String _prettyTrackName(String path) {
    // assets/audio/change_me.mp3 -> change me
    final file = path.split('/').last;
    final name = file.replaceAll('.mp3', '').replaceAll('_', ' ');
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB7EE62),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      await _stopAudio();
                      if (mounted) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                  const Spacer(),
                  Text(widget.title, style: AppText.h2),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ✅ prevents overflow on smaller screens
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    Container(
                      height: 160,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: Text(widget.emoji, style: const TextStyle(fontSize: 70)),
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      _format(_seconds),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ✅ MUSIC CARD
                    if (widget.musicEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.music_note_rounded),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _audioError
                                          ? "Music failed to load (check pubspec + filenames)"
                                          : (_audioReady ? "Music ready" : "Loading music..."),
                                      style: const TextStyle(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  if (_audioReady && !_audioError)
                                    StreamBuilder<PlayerState>(
                                      stream: _player.playerStateStream,
                                      builder: (context, snap) {
                                        final playing = snap.data?.playing ?? false;
                                        return IconButton(
                                          onPressed: () async {
                                            if (!_audioReady || _audioError) return;
                                            if (playing) {
                                              await _player.pause();
                                            } else {
                                              await _player.play();
                                            }
                                          },
                                          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                                        );
                                      },
                                    ),
                                ],
                              ),

                              if (_audioReady && !_audioError) ...[
                                const SizedBox(height: 8),
                                StreamBuilder<int?>(
                                  stream: _player.currentIndexStream,
                                  builder: (context, snap) {
                                    final idx = snap.data ?? 0;
                                    final path = _playlist[idx.clamp(0, _playlist.length - 1)];
                                    return Text(
                                      "Now playing: ${_prettyTrackName(path)}",
                                      style: AppText.muted.copyWith(fontWeight: FontWeight.w800),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () async {
                                        try {
                                          await _player.seekToPrevious();
                                        } catch (_) {}
                                      },
                                      icon: const Icon(Icons.skip_previous),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () async {
                                        try {
                                          await _player.seekToNext();
                                        } catch (_) {}
                                      },
                                      icon: const Icon(Icons.skip_next),
                                    ),
                                    const Spacer(),
                                    if (kIsWeb)
                                      Text(
                                        "Calm Spirit audio ✓",
                                        style: AppText.muted.copyWith(fontSize: 12),
                                      ),
                                  ],
                                ),
                              ],

                              if (_audioError) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _audioErrorMsg,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.muted.copyWith(fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                    // ✅ QUOTES CARD
                    if (widget.quotesEnabled) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.format_quote_rounded),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _quote,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    if (_running) {
                      _finish();
                    } else {
                      _start();
                    }
                  },
                  child: Text(_running ? "Finish" : "Start"),
                ),
              ),
            ),

            if (_running)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextButton(onPressed: _reset, child: const Text("Reset")),
              ),
          ],
        ),
      ),
    );
  }
}
