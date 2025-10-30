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
import 'package:june/june.dart';
import 'package:native_splash_screen/native_splash_screen.dart' as nss;
import 'package:nativeapi/nativeapi.dart' as native;
import 'package:splasher/splasher.dart';
import 'package:unnu_aux/unnu_aux.dart';
import 'package:unnu_shared/unnu_shared.dart';
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
        windowTitle: 'Unhandledd Exception',
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
      // final totalMem = (await MemoryInfo.getTotalPhysicalMemorySize()) ?? 0;
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
                \tSize: ${sz}''',
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
              title: 'AI For All - Plus Edition',
              maximumSize: sz,
              minimumSize: const Size(360, 480),
              windowButtonVisibility: true,
              alwaysOnTop: false,
            );

            await _jsonAssets.preload(['config.json']);

            final completer = Completer<bool>();

            unawaited(runInitializaton(completer));

            await windowManager.waitUntilReadyToShow(
              windowOptions,
              () async {
                await nss.close(animation: nss.CloseAnimation.fade);
                await windowManager.show();
                await windowManager.focus();
              },
            );

            runApp(
              BetterFeedback(
                child: MyApp(completed: completer),
              ),
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
      if (kDebugMode) {
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
  /// Creates a const main application widget.
  const MyApp({required this.completed, super.key});

  final Completer<bool> completed;

  @override
  Widget build(BuildContext context) {
    return JuneBuilder(
      InitializationStatusController.new,
      builder:
          (controller) =>
              completed.isCompleted
                  ? const MyHomePage()
                  :  Splasher.withLottie(
                      logo: 'assets/animations/loading_circles.json',
                      logoWidth: 360,
                      logoHeight: 360,
                      title: const Text('AI4All'),
                      loaderColor: Colors.white,
                      loadingTextPadding: EdgeInsets.zero,
                      loadingText: Text(controller.message),
                      backgroundColor: Colors.transparent,
                      navigator: const SizedBox.shrink(),
                      futureNavigator: completed.future,
                    ),
    );
  }
}
