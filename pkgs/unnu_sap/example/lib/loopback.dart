import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unnu_sap/unnu_asr.dart';
import './ui/bars.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

/// Loopback example which uses `flutter_soloud` to play audio back to the
/// device from the microphone data stream. Please try it with headset to
/// prevent audio feedback.
///
/// If you want to try other formats than `f32le`, you must comment out
/// the `Bars()` widget.
///
/// The `Echo Cancellation` code is not yet ready and don't know if it will be!
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
          title: Text('loopback and filter example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LoopBack(),
        ),
      ),
    ),
  );
}

class LoopBack extends StatefulWidget {
  const LoopBack({super.key});

  @override
  State<LoopBack> createState() => _LoopBackState();
}

class _LoopBackState extends State<LoopBack> {

  final recorderChannels = 0;
  final recorderFormat = 4;

  final sampleRate = 22050;

  bool autoGain = false;
  // bool echoCancellation = false;

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

    /// Listen for microphne data.

  }


  /// Dispose the audio source if it exists
  Future<void> disposeAudioSource() async {
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> init() async {
    /// Initialize the player and the recorder.

  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        const Text('Please, use headset to prevent audio feedback'),
        // Start / Stop
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: () {
                init();
              },
              child: const Text('Init loopback'),
            ),
            OutlinedButton(
              onPressed: () {
              },
              child: const Text('Stop'),
            ),
          ],
        ),

        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            Text('Auto gain'),
          ],
        ),

        if (autoGain) AutoGainSliders(),

        // if (echoCancellation) EchoCancellationSliders(),
      ],
    );
  }
}

// class EchoCancellationSliders extends StatefulWidget {
//   const EchoCancellationSliders({super.key});

//   @override
//   State<EchoCancellationSliders> createState() =>
//       _EchoCancellationSlidersState();
// }

// class _EchoCancellationSlidersState extends State<EchoCancellationSliders> {
//   late final Recorder recorder;
//   late final EchoCancellation echoCancellation;

//   @override
//   void initState() {
//     super.initState();
//     recorder = Recorder.instance;
//     echoCancellation = recorder.filters.echoCancellationFilter;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               '${echoCancellation.queryEchoDelayMs}: '
//               '${echoCancellation.echoDelayMs.value.toStringAsFixed(2)}',
//             ),
//             Expanded(
//               child: Slider(
//                 value: echoCancellation.echoDelayMs.value,
//                 min: echoCancellation.queryEchoDelayMs.min,
//                 max: echoCancellation.queryEchoDelayMs.max,
//                 onChanged: (v) {
//                   setState(() {
//                     echoCancellation.echoDelayMs.value = v;
//                   });
//                 },
//               ),
//             ),
//           ],
//         ),
//         Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               '${echoCancellation.queryEchoAttenuation}: '
//               '${echoCancellation.echoAttenuation.value.toStringAsFixed(2)}',
//             ),
//             Expanded(
//               child: Slider(
//                 value: echoCancellation.echoAttenuation.value,
//                 min: echoCancellation.queryEchoAttenuation.min,
//                 max: echoCancellation.queryEchoAttenuation.max,
//                 onChanged: (v) {
//                   setState(() {
//                     echoCancellation.echoAttenuation.value = v;
//                   });
//                 },
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

class AutoGainSliders extends StatefulWidget {
  const AutoGainSliders({super.key});

  @override
  State<AutoGainSliders> createState() => _AutoGainSlidersState();
}

class _AutoGainSlidersState extends State<AutoGainSliders> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Placeholder"
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Placeholder"
            ),

          ],
        ),
      ],
    );
  }
}
