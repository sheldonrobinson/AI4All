import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math' as math;

import 'package:asset_cache/asset_cache.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:lcpp_ngin/lcpp_ngin.dart';
import 'package:native_splash_screen/native_splash_screen.dart' as nss;
import 'package:nativeapi/nativeapi.dart' as native;
import 'package:unnu_aux/unnu_aux.dart';
import 'package:unnu_sap/unnu_asr.dart';
import 'package:unnu_sap/unnu_tts.dart';
import 'package:unnu_speech/unnu_speech.dart';
import 'package:unnu_widgets/unnu_widgets.dart';
import 'package:window_manager/window_manager.dart';

import 'initialize/initialize.dart';
import 'src/app.dart';

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

final _jsonAssets = JsonAssetCache(
  assetBundle: rootBundle,
  basePath: 'assets/json/',
);

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) async {
    if (kDebugMode) {
      // In development mode, simply print to console.
      FlutterError.dumpErrorToConsole(details);
      final _ = await FlutterPlatformAlert.showAlert(
        windowTitle: 'Unhandled Exception',
        text: 'Details: ${details}',
        iconStyle: IconStyle.error,
      );
    } else {
      // In production mode, report to the application zone to report to sentry.
      Zone.current.handleUncaughtError(details.exception, details.stack!);
	  
    }
  };

  /// Captures errors reported by the native environment, including native iOS
  /// and Android code.

  runZonedGuarded<void>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      UnnuAux.init();
      final _check = UnnuAux.checkMinimumHw();
      switch (_check) {
        case 0:
          {
            await windowManager.ensureInitialized();

            final mainMonitor = native.DisplayManager.instance.getPrimary();
            final sz = mainMonitor?.size ?? const Size(1280, 800);
            if (kDebugMode) {
              print(
                '''
                Display
                \tname: ${mainMonitor?.name}
                \tid: ${mainMonitor?.id}
                \tprimary: ${mainMonitor?.isPrimary}
                \tsize: ${mainMonitor?.size}
                \tscaleFactor: ${mainMonitor?.scaleFactor}
                \tposition: ${mainMonitor?.position}
                \trefreshRate: ${mainMonitor?.refreshRate}
                \nSize: ${sz}''',
              );
            }
            final windowOptions = WindowOptions(
              size: Size(
                math.max((sz.width * 0.75).roundToDouble(), 800.0),
                math.max(
                  (sz.height * 0.75).roundToDouble(),
                  600.0,
                ),
              ),
              center: true,
              backgroundColor: Colors.transparent,
              skipTaskbar: false,
              titleBarStyle: TitleBarStyle.normal,
              title: 'AI For All - Core Edition',
              maximumSize: sz,
              minimumSize: const Size(360, 480),
              windowButtonVisibility: true,
              alwaysOnTop: false,
            );

            LlamaCpp.initialize();
            UnnuTts.init();
            UnnuAsr.init();

            await _jsonAssets.preload(['config.json']);
            await loadConfiguration();
            await registerModels();
            await UnnuTts.configure(await getOfflineTtsConfig());
            await UnnuAsr.configure(
              getOnlineRecognizerConfig(await getOnlineModelConfig()),
              await getVadModelConfig(),
              OnlinePunctuationConfig(
                model: await getOnlinePunctuationModelConfig(),
              ),
            );
            await registerChatDatabase('chat.db');

            await windowManager.waitUntilReadyToShow(
              windowOptions,
              () async {
                await nss.close(animation: nss.CloseAnimation.fade);
                await windowManager.show();
                await windowManager.focus();
              },
            );
            runApp(MyApp(),
            );
          }
        default:
          {
            await nss.close(animation: nss.CloseAnimation.fade);
            final _ = await FlutterPlatformAlert.showAlert(
              windowTitle: 'Unsupported Hardware',
              text: 'System does not meet minimum hardware requirements ',
              iconStyle: IconStyle.error,
            );
            exit(0);
          }
      }
    },
    (Object error, StackTrace stackTrace) async {
      if(kDebugMode) {
        final _ = await FlutterPlatformAlert.showAlert(
          windowTitle: 'Unhandled Exception',
          text: 'ERROR ${error}\n\n${stackTrace}',
          iconStyle: IconStyle.error,
        );
      }
    },
    zoneValues: {},
  );
}

/// The main application widget for this example.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BetterFeedback(
        feedbackBuilder:
            (context, onSubmit, scrollController) => UnnuCustomFeedbackForm(
          onSubmit: onSubmit,
          scrollController: scrollController,
        ),
        child: const MyHomePage());
  }
}
