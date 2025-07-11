import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:unnu_sap/unnu_asr.dart';
import 'package:unnu_sap/unnu_tts.dart';
import 'package:unnu_shared/unnu_shared.dart';

// see https://github.com/k2-fsa/sherpa-onnx/blob/master/flutter-examples/tts/lib/model.dart
Future<OfflineTtsConfig> getOfflineTtsConfig() async {
  final Directory directory = await getApplicationSupportDirectory();
  String modelName = '';
  String voices = ''; // for Kokoro only
  String acousticModel = ''; // for Matcha only
  String vocoder = ''; // for Matcha only
  String ruleFsts = '';
  String ruleFars = '';
  String lexicon = '';
  String dataDir = '';
  String dictDir = '';
  String lang = '';

  // Example 8
  // https://k2-fsa.github.io/sherpa/onnx/tts/pretrained_models/kokoro.html#kokoro-en-v0-19-english-11-speakers
  final modelDir = 'packages/unnu_sap/assets/models/tts/kokoro-int8-multi-lang-v1_1';
  final dst = p.joinAll([
    directory.path,
    'unnu_sap',
    'assets',
    'models',
    'tts',
    'kokoro-int8-multi-lang-v1_1',
  ]);
  final modelFile = 'model.onnx';
  voices = 'voices.bin';
  dataDir = 'espeak-ng-data';
  ruleFsts = 'date-zh.fst,number-zh.fst,phone-zh.fst';
  lexicon = 'lexicon-gb-en.txt,lexicon-us-en.txt,lexicon-zh.txt';
  dictDir = 'dict';
  lang = Intl.getCurrentLocale().split('_').first;
  modelName = await copyAssetFile('$modelDir/$modelFile', dst);



  if (ruleFsts != '') {
    final all = ruleFsts.split(',');
    var tmp = <String>[];
    for (final f in all) {
      var filepath = await copyAssetFile('$modelDir/$f', dst);
      tmp.add(filepath);
    }
    ruleFsts = tmp.join(',');
  }

  if (ruleFars != '') {
    final all = ruleFars.split(',');
    var tmp = <String>[];
    for (final f in all) {
      var filepath = await copyAssetFile('$modelDir/$f', dst);
      tmp.add(filepath);
    }
    ruleFars = tmp.join(',');
  }

  if (lexicon != '') {
    final all = lexicon.split(',');
    var tmp = <String>[];
    for (final f in all) {
      var filepath = await copyAssetFile('$modelDir/$f', dst);
      tmp.add(filepath);
    }
    lexicon = tmp.join(',');
  }

  if (dataDir != '') {
    dataDir = await copyAssetDirectory(
      '$modelDir/$dataDir',
      p.join(dst, dataDir),
    );
  }

  if (dictDir != '') {
    dictDir = await copyAssetDirectory(
      '$modelDir/$dictDir',
      p.join(dst, dictDir),
    );
  }

  if (voices != '') {
    voices = await copyAssetFile('$modelDir/$voices', dst);
  }

  final tokens = await copyAssetFile('$modelDir/tokens.txt', dst);
  final OfflineTtsVitsModelConfig vits =
      voices.isNotEmpty || (vocoder.isNotEmpty && acousticModel.isNotEmpty)
          ? OfflineTtsVitsModelConfig()
          : OfflineTtsVitsModelConfig(
            model: modelName,
            lexicon: lexicon,
            tokens: tokens,
            dataDir: dataDir,
            dictDir: dictDir,
          );
  final OfflineTtsKokoroModelConfig kokoro =
      voices.isNotEmpty
          ? OfflineTtsKokoroModelConfig(
            model: modelName,
            voices: voices,
            tokens: tokens,
            dataDir: dataDir,
            dictDir: dictDir,
            lexicon: lexicon,
            lengthScale: 1.0,
            lang: lang,
          )
          : OfflineTtsKokoroModelConfig();
  final OfflineTtsMatchaModelConfig matcha =
      vocoder.isNotEmpty && acousticModel.isNotEmpty
          ? OfflineTtsMatchaModelConfig(
            acousticModel: acousticModel,
            vocoder: vocoder,
            lexicon: lexicon,
            tokens: tokens,
            dataDir: dataDir,
            noiseScale: 0.667,
            lengthScale: 1.0,
            dictDir: dictDir,
          )
          : OfflineTtsMatchaModelConfig();

  final modelConfig = OfflineTtsModelConfig(
    vits: vits,
    kokoro: kokoro,
    matcha: matcha,
    numThreads: 2,
    debug: false,
    provider: 'cpu',
  );

  return OfflineTtsConfig(
    model: modelConfig,
    ruleFsts: ruleFsts,
    ruleFars: ruleFars,
    maxNumSenetences: 1,
  );
}

Future<OnlineModelConfig> getOnlineModelConfig() async {
  final Directory directory = await getApplicationSupportDirectory();
  final dst = p.joinAll([
    directory.path,
    'unnu_sap',
    'assets',
    'models',
    'asr',
    'sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20-mobile',
  ]);
  final modelDir =
      'packages/unnu_sap/assets/models/asr/sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20-mobile';
  return OnlineModelConfig(
    transducer: OnlineTransducerModelConfig(
      encoder: await copyAssetFile(
        '$modelDir/encoder-epoch-99-avg-1.int8.onnx',
        dst,
      ),
      decoder: await copyAssetFile(
        '$modelDir/decoder-epoch-99-avg-1.onnx',
        dst,
      ),
      joiner: await copyAssetFile(
        '$modelDir/joiner-epoch-99-avg-1.int8.onnx',
        dst,
      ),
    ),

    modelingUnit: 'cjkchar',
    bpeVocab: '', // await copyAssetFile('$modelDir/bpe.vocab', dst),
    tokens: await copyAssetFile('$modelDir/tokens.txt', dst),
    modelType: 'zipformer',
    debug: false,
    numThreads: 2,
  );
}

OnlineRecognizerConfig getOnlineRecognizerConfig(OnlineModelConfig config) {
  return OnlineRecognizerConfig(
    model: config,
    // ctcFstDecoderConfig: await getOnlineCtcFstDecoderConfig(type: type),
    feat: FeatureConfig(sampleRate: 16000, featureDim: 80),
    enableEndpoint: true,
    rule1MinTrailingSilence: 3.0,
    rule2MinTrailingSilence: 1.5,
    rule3MinUtteranceLength: 45,
  );
}

Future<VadModelConfig> getVadModelConfig() async {
  final Directory directory = await getApplicationSupportDirectory();

  final dst = p.joinAll([
    directory.path,
    'unnu_sap',
    'assets',
    'models',
    'asr',
    'silero-vad',
  ]);
  final modelDir = 'packages/unnu_sap/assets/models/asr/silero-vad';
  final sileroVadConfig = SileroVadModelConfig(
    model: await copyAssetFile('$modelDir/silero_vad.onnx', dst),
    minSilenceDuration: 0.5,
    minSpeechDuration: 0.25,
  );
  return VadModelConfig(
    sileroVad: sileroVadConfig,
    numThreads: 1,
    debug: false,
  );
}

Future<OnlinePunctuationModelConfig> getOnlinePunctuationModelConfig() async {
  final Directory directory = await getApplicationSupportDirectory();

  final dst = p.joinAll([
    directory.path,
    'unnu_sap',
    'assets',
    'models',
    'asr',
    'sherpa-onnx-online-punct-en-2024-08-06',
  ]);
  final modelDir =
      'packages/unnu_sap/assets/models/asr/sherpa-onnx-online-punct-en-2024-08-06';
  return OnlinePunctuationModelConfig(
    cnnBiLstm: await copyAssetFile('$modelDir/model.int8.onnx', dst),
    bpeVocab: await copyAssetFile('$modelDir/bpe.vocab', dst),
    numThreads: 1,
    debug: false,
  );
}
