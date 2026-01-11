import 'dart:async';
import 'package:flutter/material.dart';
import 'package:habits_app/utils/theme.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  bool _quotes = true;
  bool _music = false;

  int _seconds = 5 * 60; // default 5 min
  Timer? _timer;
  bool _running = false;

  final List<String> _quotePool = const [
    "Breathe in calm, breathe out stress.",
    "Let your thoughts pass like clouds.",
    "You are safe. You are present.",
    "Slow breath. Soft mind.",
    "One minute at a time."
  ];

  String _currentQuote = "Breathe in calm, breathe out stress.";

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_running) return;

    setState(() => _running = true);

    // If Quotes enabled: rotate quote every 12 seconds
    if (_quotes) {
      _pickRandomQuote();
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

      if (_quotes && _running && _seconds % 12 == 0) {
        _pickRandomQuote();
      }
    });

    // Music toggle: for now we show UI only
    // If you want real audio, tell me and I’ll plug in just_audio.
  }

  void _finish() {
    _timer?.cancel();
    setState(() => _running = false);
    Navigator.pop(context);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _seconds = 5 * 60;
      _currentQuote = _quotePool.first;
    });
  }

  void _pickRandomQuote() {
    _quotePool.shuffle();
    setState(() => _currentQuote = _quotePool.first);
  }

  String _format(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return "${m.toString().padLeft(2, '0')} min ${s.toString().padLeft(2, '0')} s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB7EE62), // green like your mock
      body: SafeArea(
        child: Column(
          children: [
            // top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                  const Spacer(),
                  Text("Meditation", style: AppText.h2),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // character / illustration placeholder
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Replace with your asset/lottie later
                  Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Center(
                      child: Text("🧘", style: TextStyle(fontSize: 70)),
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

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        // OPTIONS (Quotes/Music)
                        _OptionTile(
                          icon: Icons.format_quote_rounded,
                          title: "Quotes",
                          subtitle: "Show mindful quotes while you meditate",
                          value: _quotes,
                          onChanged: _running ? null : (v) => setState(() => _quotes = v),
                        ),
                        const SizedBox(height: 10),
                        _OptionTile(
                          icon: Icons.music_note_rounded,
                          title: "Music",
                          subtitle: "Play calm music while meditating",
                          value: _music,
                          onChanged: _running ? null : (v) => setState(() => _music = v),
                        ),

                        const SizedBox(height: 16),

                        // Quote box (only if enabled)
                        if (_quotes)
                          Container(
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
                                    _currentQuote,
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // duration quick pick (optional)
                        if (!_running)
                          Row(
                            children: [
                              Expanded(
                                child: _MiniPill(
                                  text: "5 min",
                                  onTap: () => setState(() => _seconds = 5 * 60),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MiniPill(
                                  text: "10 min",
                                  onTap: () => setState(() => _seconds = 10 * 60),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _MiniPill(
                                  text: "15 min",
                                  onTap: () => setState(() => _seconds = 15 * 60),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // bottom button
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
                      if (!_quotes && !_music) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Choose Quotes or Music to continue.")),
                        );
                        return;
                      }
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
                child: TextButton(
                  onPressed: _reset,
                  child: const Text("Reset"),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.40),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _MiniPill({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.35),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Center(
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}
