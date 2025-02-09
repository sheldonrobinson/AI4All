import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:llamacpp/llamacpp.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:unnu_shared/unnu_shared.dart';

Future<LlamaCppParams> getDefaultLcppParams() async {
  final Directory directory = await getApplicationSupportDirectory();

  final dst = p.joinAll([
    directory.path,
    'assets',
    'models',
    'chat',
  ]);
  final modelDir = 'assets/models/chat';
  final modelFilename = 'Qwen3-1.7B-Q4_K_M.gguf';
  final params = LlamaCppParams.defaultParams();
  final completer = Completer();
  if(kDebugMode){
    print('unnu_a_model: copying model file $modelFilename');
  }
  final modelFilePath = copyAssetFile('$modelDir/$modelFilename', dst).whenComplete(() {
    if(kDebugMode){
      print('unnu_ai_model: copied model file $modelFilename');
    }
    completer.complete();
  },);

  while (!completer.isCompleted) {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  if(kDebugMode){
    print('unnu_ai_model: getDefaultLcppParams:>');
  }
  return params.copyWith(
    modelPath: await modelFilePath,
    splitMode: lcpp_split_mode.LCPP_SPLIT_MODE_LAYER,
    modelFamily: lcpp_model_family.LCPP_MODEL_FAMILY_UNSPECIFIED,
    mainGPU: 0,
    nGpuLayers: 99,
    useMmap: true,
    useMlock: true,
  );
}
