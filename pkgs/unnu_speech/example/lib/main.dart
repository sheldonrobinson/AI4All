import 'dart:async';
import 'dart:io';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:unnu_speech/unnu_speech.dart';
import 'package:logging/logging.dart';
import 'package:unnu_sap/unnu_asr.dart';
import 'package:unnu_sap/unnu_tts.dart';

Future<void> initializeTTS() async {
  UnnuTts.configure(await getOfflineTtsConfig());
}

Future<void> initializeASR() async {
  final config = await getOnlineModelConfig();
  final punctCfg = await getOnlinePunctuationModelConfig();
  UnnuAsr.configure(
    getOnlineRecognizerConfig(config),
    await getVadModelConfig(),
    OnlinePunctuationConfig(model: punctCfg),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {
    // Forward logs to the console.
    dev.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      zone: record.zone,
      error: record.error,
      stackTrace: record.stackTrace,
    );
    // TODO: if needed, forward to Sentry.io, Crashlytics, etc.
  });
  await initializeASR();
  await initializeTTS();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _muted = false;

  @override
  void initSate() {
    super.initState();
  }

  void _mute() {
    bool _tmp = !_muted;
    setState(() {
      _muted = _tmp;
    });
  }

  @override
  Widget build(BuildContext context) {
    const spacerSmall = SizedBox(height: 10);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 110, child: UnnuSpeechWidget(
              noise: UnnuAsr.instance.soundEvents,
              eavesdropping: UnnuAsr.instance.nowListening, settings: (hasMicrophone: false, hasSpeaker: false), tooltips: {},
            )),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.max,
              children: [
                OutlinedButton(
                  onPressed: () {
                    UnnuTts.instance.speak(
                      'Hello I am Deep Thought, a supercomputer created by a race of hyper-intelligent pan-dimensional beings that was programmed to calculate the answer to the Ultimate Question of Life, the Universe, and Everything.',
                      0,
                      1.0,
                    );
                    sleep(const Duration(milliseconds: 1));
                    UnnuTts.instance.speak(
                      '42 (or forty-two) is the Answer to the Ultimate Question of Life, the Universe and Everything.',
                      1,
                      1.0,
                    );
                  },
                  child: const Text('Speak'),
                ),
              ],
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  void dispose() {
    UnnuTts.destroy();
    UnnuAsr.destroy();
    super.dispose();
  }
}
