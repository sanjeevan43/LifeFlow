import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  static stt.SpeechToText? _speech;

  static Future<void> initialize(Function(String) onCommand) async {
    // Skip initialization on web platform
    if (kIsWeb) {
      return;
    }
    
    final service = FlutterBackgroundService();

    service.on('voice_command').listen((event) {
      if (event != null && event['command'] != null) {
        onCommand(event['command']);
      }
    });

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'voice_assistant_channel',
      'Voice Assistant Service',
      description: 'This channel is used for the voice assistant background service.',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'voice_assistant_channel',
        initialNotificationTitle: 'LifeFlow Voice Assistant',
        initialNotificationContent: 'Listening for commands...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<void> toggleService(bool enable) async {
    // Skip on web platform
    if (kIsWeb) {
      return;
    }
    
    final service = FlutterBackgroundService();
    if (enable) {
      if (!await service.isRunning()) {
        await service.startService();
      }
    } else {
      if (await service.isRunning()) {
        service.invoke("stopService");
      }
    }
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
    
    // For background speech recognition to work significantly better, 
    // real implementations use hotword detection (like Porcupine).
    // Standard SpeechToText relies on system UI and may sleep.
    // However, keeping the service as ForegroundServiceType.microphone
    // gives us the best chance without paid plugins.
    
    _speech = stt.SpeechToText();
    bool available = await _speech!.initialize();
    
    if (available) {
       _startListeningLoop(service);
    }
    
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }

  @pragma('vm:entry-point')
  static bool onIosBackground(ServiceInstance service) {
    return true;
  }

  static void _startListeningLoop(ServiceInstance service) {
    // Continuous listening simulation
    if (_speech == null) return;
    
    _speech!.listen(
      onResult: (val) async {
         if (val.finalResult) {
             // Process command
             final cmd = val.recognizedWords.toLowerCase();
             service.invoke('voice_command', {'command': cmd});
            
            // Basic command processing in background
            if (cmd.contains('call')) {
              // Extract number... logic duplicated from main for now
              // Note: Launching intents from background has restrictions on Android 10+
              // We might need to send a notification to tap
            }
         }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: false,
      cancelOnError: false,
      listenMode: stt.ListenMode.dictation, 
    );
    
    // Restart listener periodically if it stops
    Timer.periodic(const Duration(seconds: 35), (timer) async {
      // Service logic keeps running until stopSelf is called
      if (!_speech!.isListening) {
        await _speech!.listen();
      }
    });
  }
}
