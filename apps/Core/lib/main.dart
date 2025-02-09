import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math' as math;


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:llamacpp/llamacpp.dart';
import 'package:unnu_ai_model/unnu_ai_model.dart';
import 'package:unnu_sap/unnu_asr.dart';
import 'package:unnu_sap/unnu_tts.dart';
import 'package:intl/intl.dart';
import 'package:unnu_speech/unnu_speech.dart';
import 'package:feedback/feedback.dart';
import 'package:window_size/window_size.dart' as window_size;
import 'package:asset_cache/asset_cache.dart';
import 'package:june/june.dart';
import 'initialize/initialize.dart';

import 'src/app.dart';
import 'src/types.dart';

void log(
  Object? message, {
  DateTime? time,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
}) {
  dev.log(
    message?.toString() ?? '',
    time: time,
    sequenceNumber: sequenceNumber,
    level: level,
    name: name,
    zone: zone,
    error: error,
    stackTrace: stackTrace,
  );
}

final jsonAssets = JsonAssetCache(assetBundle: rootBundle, basePath: 'assets/json/');

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // In development mode, simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode, report to the application zone to report to sentry.
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    }
  };

  /// Captures errors reported by the native environment, including native iOS
  /// and Android code.

  if (kDebugMode) {
    print('main()');
  }

  runZonedGuarded<void>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      LlamaCpp.init();
      UnnuTts.init();
      UnnuAsr.init();
      await jsonAssets.preload(['config.json']);
      await registerModels();
      await UnnuTts.configure(await getOfflineTtsConfig());
      await UnnuAsr.configure(
        getOnlineRecognizerConfig(await getOnlineModelConfig()),
        await getVadModelConfig(),
        OnlinePunctuationConfig(model: await getOnlinePunctuationModelConfig()),
      );
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await window_size.getWindowInfo().then((window) {
          final screen = window.screen;
          if (screen != null) {
            final screenFrame = screen.visibleFrame;
            final width = math.max(
              (screenFrame.width / 2).roundToDouble(),
              800.0,
            );
            final height = math.max(
              (screenFrame.height / 2).roundToDouble(),
              600.0,
            );
            final left =
                screenFrame.left +
                    ((screenFrame.width - width) / 2).roundToDouble();
            final top =
                screenFrame.top +
                    ((screenFrame.height - height) / 2).roundToDouble();
            final frame = Rect.fromLTWH(left, top, width, height);
            window_size.setWindowTitle('AI For All - Core Edition');
            window_size.setWindowFrame(frame);
            window_size.setWindowMinSize(Size(360, 480));
            window_size.setWindowMaxSize(
              Size(screenFrame.width, screenFrame.height),
            );
          }
        });
      }

      final llmProviderController = June.getState(()=>LLMProviderController());
      final appLayoutController = June.getState(()=>ApplicationLayoutModelController());

      await appLayoutController.configureModel(
        llmProviderController.activeModel.info,
      );

      if (kDebugMode) {
        print('getting currentLocale');
      }

      if (kDebugMode) {
        final currentLocale = Intl.getCurrentLocale();
        final langCode = Intl.shortLocale(currentLocale);
        print(
          'currentLocale: $currentLocale\nsystemLocale: ${Intl.systemLocale}\nlangCode: $langCode',
        );
      }
      await registerChatDatabase('chat.db');

      runApp(
          BetterFeedback( child: MyApp()))
      ;
      if (kDebugMode) {
        print('main:>');
      }
    },
    (Object error, StackTrace stackTrace) {},
    zoneValues: {},
  );
}

/// The main application widget for this example.
class MyApp extends StatelessWidget {

  /// Creates a const main application widget.
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('MyApp.build()');
    }
    return MyHomePage();
  }
}
