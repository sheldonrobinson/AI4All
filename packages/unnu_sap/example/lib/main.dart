import 'dart:io';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import './ui/bars.dart';
import 'package:logging/logging.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

/// Demostrate how to use flutter_recorder.
///
/// The silence detection and the visualizer works when using [PCMFormat.f32].
/// Writing audio stream to file is not implemented on Web.
void main() async {
  // The `flutter_recorder` package logs everything
  // (from severe warnings to fine debug messages)
  // using the standard `package:logging`.
  // You can listen to the logs as shown below.
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;
  Logger.root.onRecord.listen((record) {
    dev.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );
  });

  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Recorder'),
        ),
        body: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Directory? savingDir;
  final format = 4;
  final sampleRate = 22050;
  final channels = 0;
  String? filePath;
  var thresholdDb = -20.0;
  var silenceDuration = 2.0;
  var secondsOfAudioToWriteBefore = 0.0;

  File? file;

  @override
  void initState() {
    super.initState();
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      Permission.microphone.request().isGranted.then((value) async {
        if (!value) {
          await [Permission.microphone].request();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            /// List capture devices, init, start, deinit
            Wrap(
              runSpacing: 6,
              spacing: 6,
              children: [
                OutlinedButton(
                  onPressed: () {
                    showDeviceListDialog();
                  },
                  child: const Text('listCaptureDevices'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            /// Recording
            const SizedBox(height: 10),

            /// Streaming
            const SizedBox(height: 10),

            /// The silence detection is available only with f32 format and
            /// the visualization is adapted only with that format.
            if (format == 4)
              Column(
                children: [
                  const Bars(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> showFileRecordedDialog(String filePath) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recording saved!'),
          content: Text('Audio saved to:\n$filePath'),
          actions: <Widget>[
            TextButton(
              child: const Text('open'),
              onPressed: () async {
                OpenFilex.open(
                  filePath,
                  type: 'audio/wav',
                );
              },
            ),
            TextButton(
              child: const Text('close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showDeviceListDialog() async {

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Available input devices'),
          actions: <Widget>[
            const Text(''),
            TextButton(
              child: const Text('close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
