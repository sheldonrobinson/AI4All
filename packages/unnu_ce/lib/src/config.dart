import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:unnu_shared/unnu_shared.dart';

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

  final modelPath = await copyAssetDirectory(modelDir,dst);
  return modelPath;
}

Future<CNERConfig> getNERPath() async {
  final Directory directory = await getApplicationSupportDirectory();
  final modelDir = 'packages/unnu_ce/assets/models/operators/cner-base';

  final dst = p.joinAll([
    directory.path,
    'unnu_ce',
    'assets',
    'models',
    'operators',
    'cner-base',
  ]);

  final modelPath = await copyAssetDirectory(modelDir,dst);
  final tokenizerFile = p.join(dst,'tokenizer.json');

  return (path: modelPath, tokenizer: tokenizerFile, type: TokenizerType.HUGGINGFACE);
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

  final agentPath = await copyAssetDirectory(agentDir,dst);
  return agentPath;
}
