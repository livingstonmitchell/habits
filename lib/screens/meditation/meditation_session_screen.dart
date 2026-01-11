import 'dart:async';
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

  final List<String> _playlist = const [
    'assets/audio/carry_me_kevin_downswell.mp3',
    'assets/audio/casey_j_if_godnothing_but_the_blood.mp3',
    'assets/audio/change_me.mp3',
    'assets/audio/close_to_you.mp3',
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
      final sources = _playlist.map((p) => AudioSource.asset(p)).toList();
      final playlist = ConcatenatingAudioSource(children: sources);
      await _player.setAudioSource(playlist, initialIndex: 0, initialPosition: Duration.zero);
      await _player.setLoopMode(LoopMode.all);
      setState(() => _audioReady = true);
    } catch (_) {
      setState(() {
        _audioError = true;
        _audioReady = false;
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

      // if timer ended -> stop audio
      if (_seconds == 0) {
        _stopAudio();
      }
    });
  }

  Future<void> _stopAudio() async {
    if (!widget.musicEnabled) return;
    try {
      await _player.stop();
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

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                        child: Row(
                          children: [
                            const Icon(Icons.music_note_rounded),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _audioError
                                    ? "Music failed to load (check assets/audio/)"
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
                                      if (!widget.musicEnabled) return;
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
                      ),
                    ),

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
                ],
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
