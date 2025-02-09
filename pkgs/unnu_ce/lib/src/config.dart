import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import './types.dart';

// see https://github.com/k2-fsa/sherpa-onnx/blob/master/flutter-examples/tts/lib/model.dart
Future<String> getModelPath() async {
  final Directory directory = await getApplicationSupportDirectory();
  final modelDir = 'packages/unnu_ce/assets/models/agents/SmolLM2-135M-Instruct';

  final dst = p.joinAll([
    directory.path,
    'unnu_ce',
    'assets',
    'models',
    'agents',
    'SmolLM2-135M-Instruct',
  ]);

  final modelPath = "";
  return modelPath;
}

Future<String> getAgentPath() async {
  final Directory directory = await getApplicationSupportDirectory();
  final agentDir = 'packages/unnu_ce/assets/agents/unnu';

  final dst = p.joinAll([
    directory.path,
    'unnu_ce',
    'assets',
    'agents',
    'unnu',
  ]);

  final agentPath = "";
  return agentPath;
}
