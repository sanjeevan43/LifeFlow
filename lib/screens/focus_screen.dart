import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';

class FocusScreen extends StatefulWidget {
  final String? taskTitle;

  const FocusScreen({super.key, this.taskTitle});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with TickerProviderStateMixin {
  static const int _defaultTime = 25 * 60; // 25 minutes
  int _remainingSeconds = _defaultTime;
  Timer? _timer;
  bool _isRunning = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingSeconds > 0) {
           setState(() => _remainingSeconds--);
        } else {
           _timer?.cancel();
           _isRunning = false;
           // Play sound and award XP when timer completes
        }
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Focus Mode'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
             colors: [
               Color(0xFF0F172A),
               Color(0xFF312E81), 
             ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.taskTitle != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Text(
                    widget.taskTitle!,
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Stack(
                 alignment: Alignment.center,
                 children: [
                    ScaleTransition(
                      scale: Tween(begin: 0.95, end: 1.05).animate(_pulseController),
                      child: Container(
                        width: 300,
                        height: 300,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                               color: _isRunning ? const Color(0xFF00E5FF).withOpacity(0.4) : Colors.transparent,
                               blurRadius: 40,
                               spreadRadius: 10,
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFF00E5FF).withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    GlassCard(
                       borderRadius: BorderRadius.circular(150),
                       blur: 5,
                       opacity: 0.1,
                       child: Container(
                          width: 280,
                          height: 280,
                          alignment: Alignment.center,
                          child: Text(
                            _formatTime(_remainingSeconds),
                            style: const TextStyle(
                               fontFamily: 'Courier', // Monospace for timer
                               fontSize: 64,
                               color: Colors.white,
                               fontWeight: FontWeight.w100,
                            ),
                          ),
                       ),
                    ),
                 ],
              ),
              const SizedBox(height: 60),
              Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                    _buildControlButton(
                       icon: _isRunning ? Icons.pause : Icons.play_arrow,
                       color: _isRunning ? Colors.amber : const Color(0xFF00E5FF),
                       onPressed: _toggleTimer,
                    ),
                    const SizedBox(width: 20),
                    _buildControlButton(
                       icon: Icons.stop,
                       color: Colors.redAccent,
                       onPressed: () {
                          _timer?.cancel();
                          setState(() {
                             _isRunning = false;
                             _remainingSeconds = _defaultTime;
                          });
                       },
                    ),
                 ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return GestureDetector(
       onTap: onPressed,
       child: GlassCard(
          borderRadius: BorderRadius.circular(50),
          child: Container(
             padding: const EdgeInsets.all(16),
             child: Icon(icon, color: color, size: 32),
          ),
       ),
    );
  }
}
