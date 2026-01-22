import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../services/device_access_service.dart';
import '../widgets/glass_card.dart';
import '../services/voice_service.dart';

class DeviceActionsScreen extends StatefulWidget {
  const DeviceActionsScreen({super.key});

  @override
  State<DeviceActionsScreen> createState() => _DeviceActionsScreenState();
}

class _DeviceActionsScreenState extends State<DeviceActionsScreen> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  List<Map<String, dynamic>> _installedApps = [];
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isAlwaysOn = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _loadApps();
    _checkServiceStatus();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkServiceStatus() async {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (mounted) {
      setState(() => _isAlwaysOn = isRunning);
    }
  }

  Future<void> _toggleAlwaysOn(bool value) async {
    setState(() => _isAlwaysOn = value);
    await VoiceService.toggleService(value);
    
    if (mounted) {
      if (value) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voice Assistant is now running in background')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background service stopped')),
        );
      }
    }
  }

  // ... (rest of methods)

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Assistant',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'How can I help you?',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white70),
                onPressed: () => _showHelpDialog(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.power_settings_new, color: Color(0xFF00E5FF), size: 20),
                    SizedBox(width: 12),
                    Text('Always On Mode', style: TextStyle(color: Colors.white)),
                  ],
                ),
                Switch(
                  value: _isAlwaysOn,
                  onChanged: kIsWeb ? null : _toggleAlwaysOn, // Disable on web
                  activeColor: const Color(0xFF00E5FF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Fix #11: Properly dispose speech object to prevent memory leak
    _speech.stop();
    _speech.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadApps() async {
    _installedApps = await DeviceAccessService.getInstalledApps();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening') {
            setState(() => _isListening = false);
            _pulseController.stop();
          }
        },
        onError: (errorNotification) {
          setState(() {
            _isListening = false;
            _text = 'Error: ${errorNotification.errorMsg}';
          });
          _pulseController.stop();
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _text = 'Listening...';
        });
        _pulseController.repeat(reverse: true);
        
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
            });
            
            if (val.finalResult) {
              _processCommand(_text);
            }
          },
        );
      } else {
        setState(() => _text = 'Speech recognition not available');
        if (!kIsWeb) {
          await Permission.microphone.request();
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _pulseController.stop();
    }
  }

  Future<void> _processCommand(String command) async {
    final lowerCommand = command.toLowerCase();
    
    if (lowerCommand.contains('call')) {
      // Extract numbers if any
      final RegExp numReg = RegExp(r'\d+');
      final match = numReg.firstMatch(lowerCommand);
      if (match != null) {
        final number = match.group(0);
        _feedback('Calling $number...');
        await DeviceAccessService.makePhoneCall(number!);
      } else {
        _feedback('Say "Call" followed by a number');
      }
    } else if (lowerCommand.contains('open') || lowerCommand.contains('launch')) {
      // Find app name
      if (lowerCommand.contains('settings')){
        _feedback('Opening Settings...');
        await DeviceAccessService.openSettings();
        return;
      }
      
      // Fuzzy match against installed apps
      // This is basic matching, can be improved
      for (var app in _installedApps) {
        final name = (app['name'] as String).toLowerCase();
        if (lowerCommand.contains(name)) {
          _feedback('Opening ${app['name']}...');
          await DeviceAccessService.openApp(app['packageName']);
          return;
        }
      }
      
      if (lowerCommand.contains('google') || lowerCommand.contains('browser')) {
         _feedback('Opening Browser...');
         await DeviceAccessService.openUrl('https://google.com');
      } else {
         _feedback('App not found or not installed');
      }
    } else if (lowerCommand.contains('search')) {
      final query = lowerCommand.replaceAll('search', '').trim();
      _feedback('Searching for $query...');
      await DeviceAccessService.openUrl('https://google.com/search?q=$query');
    } else {
      _feedback('Command not recognized. Try "Open Settings" or "Call 123"');
    }
  }

  void _feedback(String message) {
    setState(() => _text = message);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF6C63FF),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildVisualizer(),
                    const SizedBox(height: 48),
                    _buildTranscript(),
                  ],
                ),
              ),
              _buildSuggestions(),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildVisualizer() {
    return GestureDetector(
      onTap: _listen,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: 150 * (_isListening ? _pulseAnimation.value : 1.0),
            height: 150 * (_isListening ? _pulseAnimation.value : 1.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isListening 
                  ? [const Color(0xFF00E5FF), const Color(0xFF6C63FF)]
                  : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isListening ? const Color(0xFF00E5FF) : Colors.black).withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 2,
              ),
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: 60,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranscript() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: GlassCard(
        opacity: 0.1,
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 100),
          child: Text(
            _text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 120,
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildSuggestionChip('Open Settings', Icons.settings),
          _buildSuggestionChip('Open Browser', Icons.public),
          _buildSuggestionChip('Call 12345', Icons.phone),
          _buildSuggestionChip('Search Flutter', Icons.search),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () => _processCommand(label),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Commands'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Try saying:'),
            SizedBox(height: 8),
            Text('• "Open Settings"'),
            Text('• "Call [number]"'),
            Text('• "Open [App Name]"'),
            Text('• "Search [Query]"'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}