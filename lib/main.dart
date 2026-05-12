import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/services/audio_handler.dart';
import 'core/services/youtube_service.dart';
import 'data/models/video_model.dart';
import 'presentation/providers/player_provider.dart';

import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0A),
  ));

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(VideoModelAdapter());
  await Hive.openBox<VideoModel>(AppConstants.hiveVideoBox);

  // Initialize Audio Service
  final audioHandler = await AudioService.init(
    builder: () => AppAudioHandler(YoutubeService()),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.appaTube.audio',
      androidNotificationChannelName: 'AppaTube Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const AppaTubeApp(),
    ),
  );
}
