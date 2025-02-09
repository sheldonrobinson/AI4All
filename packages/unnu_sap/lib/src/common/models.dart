// Speech-to-Text Models

class FeatureConfig {
  const FeatureConfig({this.sampleRate = 16000, this.featureDim = 80});

  factory FeatureConfig.fromJson(Map<String, dynamic> json) {
    return FeatureConfig(
      sampleRate: json['sampleRate'] as int? ?? 16000,
      featureDim: json['featureDim'] as int? ?? 80,
    );
  }

  @override
  String toString() {
    return 'FeatureConfig(sampleRate: $sampleRate, featureDim: $featureDim)';
  }

  Map<String, dynamic> toJson() => {
    'sampleRate': sampleRate,
    'featureDim': featureDim,
  };

  final int sampleRate;
  final int featureDim;
}

class OnlineTransducerModelConfig {
  const OnlineTransducerModelConfig({
    this.encoder = '',
    this.decoder = '',
    this.joiner = '',
  });

  factory OnlineTransducerModelConfig.fromJson(Map<String, dynamic> json) {
    return OnlineTransducerModelConfig(
      encoder: json['encoder'] as String? ?? '',
      decoder: json['decoder'] as String? ?? '',
      joiner: json['joiner'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OnlineTransducerModelConfig(encoder: $encoder, decoder: $decoder, joiner: $joiner)';
  }

  Map<String, dynamic> toJson() => {
        'encoder': encoder,
        'decoder': decoder,
        'joiner': joiner,
      };

  final String encoder;
  final String decoder;
  final String joiner;
}

class OnlineParaformerModelConfig {
  const OnlineParaformerModelConfig({this.encoder = '', this.decoder = ''});

  factory OnlineParaformerModelConfig.fromJson(Map<String, dynamic> json) {
    return OnlineParaformerModelConfig(
      encoder: json['encoder'] as String? ?? '',
      decoder: json['decoder'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OnlineParaformerModelConfig(encoder: $encoder, decoder: $decoder)';
  }

  Map<String, dynamic> toJson() => {
        'encoder': encoder,
        'decoder': decoder,
      };

  final String encoder;
  final String decoder;
}

class OnlineZipformer2CtcModelConfig {
  const OnlineZipformer2CtcModelConfig({this.model = ''});

  factory OnlineZipformer2CtcModelConfig.fromJson(Map<String, dynamic> json) {
    return OnlineZipformer2CtcModelConfig(
      model: json['model'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OnlineZipformer2CtcModelConfig(model: $model)';
  }

  Map<String, dynamic> toJson() => {
        'model': model,
      };

  final String model;
}

class OnlineModelConfig {
  const OnlineModelConfig({
    this.transducer = const OnlineTransducerModelConfig(),
    this.paraformer = const OnlineParaformerModelConfig(),
    this.zipformer2Ctc = const OnlineZipformer2CtcModelConfig(),
    required this.tokens,
    this.numThreads = 1,
    this.provider = 'cpu',
    this.debug = true,
    this.modelType = '',
    this.modelingUnit = '',
    this.bpeVocab = '',
  });

  factory OnlineModelConfig.fromJson(Map<String, dynamic> json) {
    return OnlineModelConfig(
      transducer: OnlineTransducerModelConfig.fromJson(
          json['transducer'] as Map<String, dynamic>? ?? const {}),
      paraformer: OnlineParaformerModelConfig.fromJson(
          json['paraformer'] as Map<String, dynamic>? ?? const {}),
      zipformer2Ctc: OnlineZipformer2CtcModelConfig.fromJson(
          json['zipformer2Ctc'] as Map<String, dynamic>? ?? const {}),
      tokens: json['tokens'] as String,
      numThreads: json['numThreads'] as int? ?? 1,
      provider: json['provider'] as String? ?? 'cpu',
      debug: json['debug'] as bool? ?? true,
      modelType: json['modelType'] as String? ?? '',
      modelingUnit: json['modelingUnit'] as String? ?? '',
      bpeVocab: json['bpeVocab'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OnlineModelConfig(transducer: $transducer, paraformer: $paraformer, zipformer2Ctc: $zipformer2Ctc, tokens: $tokens, numThreads: $numThreads, provider: $provider, debug: $debug, modelType: $modelType, modelingUnit: $modelingUnit, bpeVocab: $bpeVocab)';
  }

  Map<String, dynamic> toJson() => {
        'transducer': transducer.toJson(),
        'paraformer': paraformer.toJson(),
        'zipformer2Ctc': zipformer2Ctc.toJson(),
        'tokens': tokens,
        'numThreads': numThreads,
        'provider': provider,
        'debug': debug,
        'modelType': modelType,
        'modelingUnit': modelingUnit,
        'bpeVocab': bpeVocab,
      };

  final OnlineTransducerModelConfig transducer;
  final OnlineParaformerModelConfig paraformer;
  final OnlineZipformer2CtcModelConfig zipformer2Ctc;

  final String tokens;

  final int numThreads;

  final String provider;

  final bool debug;

  final String modelType;

  final String modelingUnit;

  final String bpeVocab;
}

class OnlineCtcFstDecoderConfig {
  const OnlineCtcFstDecoderConfig({this.graph = '', this.maxActive = 3000});

  factory OnlineCtcFstDecoderConfig.fromJson(Map<String, dynamic> json) {
    return OnlineCtcFstDecoderConfig(
      graph: json['graph'] as String? ?? '',
      maxActive: json['maxActive'] as int? ?? 3000,
    );
  }

  @override
  String toString() {
    return 'OnlineCtcFstDecoderConfig(graph: $graph, maxActive: $maxActive)';
  }

  Map<String, dynamic> toJson() => {
        'graph': graph,
        'maxActive': maxActive,
      };

  final String graph;
  final int maxActive;
}

class HomophoneReplacerConfig {
  const HomophoneReplacerConfig(
      {this.dictDir = '', this.lexicon = '', this.ruleFsts = ''});

  factory HomophoneReplacerConfig.fromJson(Map<String, dynamic> json) {
    return HomophoneReplacerConfig(
      dictDir: json['dictDir'] as String? ?? '',
      lexicon: json['lexicon'] as String? ?? '',
      ruleFsts: json['ruleFsts'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'HomophoneReplacerConfig(dictDir: $dictDir, lexicon: $lexicon, ruleFsts: $ruleFsts)';
  }

  Map<String, dynamic> toJson() => {
        'dictDir': dictDir,
        'lexicon': lexicon,
        'ruleFsts': ruleFsts,
      };

  final String dictDir;
  final String lexicon;
  final String ruleFsts;
}

class OnlineRecognizerConfig {
  const OnlineRecognizerConfig({
    this.feat = const FeatureConfig(),
    required this.model,
    this.decodingMethod = 'greedy_search',
    this.maxActivePaths = 4,
    this.enableEndpoint = true,
    this.rule1MinTrailingSilence = 2.4,
    this.rule2MinTrailingSilence = 1.2,
    this.rule3MinUtteranceLength = 20,
    this.hotwordsFile = '',
    this.hotwordsScore = 1.5,
    this.ctcFstDecoderConfig = const OnlineCtcFstDecoderConfig(),
    this.ruleFsts = '',
    this.ruleFars = '',
    this.blankPenalty = 0.0,
    this.hr = const HomophoneReplacerConfig(),
  });

  factory OnlineRecognizerConfig.fromJson(Map<String, dynamic> json) {
    return OnlineRecognizerConfig(
      feat: FeatureConfig.fromJson(
          json['feat'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      model: OnlineModelConfig.fromJson(json['model'] as Map<String, dynamic>),
      decodingMethod: json['decodingMethod'] as String? ?? 'greedy_search',
      maxActivePaths: json['maxActivePaths'] as int? ?? 4,
      enableEndpoint: json['enableEndpoint'] as bool? ?? true,
      rule1MinTrailingSilence:
          (json['rule1MinTrailingSilence'] as num?)?.toDouble() ?? 2.4,
      rule2MinTrailingSilence:
          (json['rule2MinTrailingSilence'] as num?)?.toDouble() ?? 1.2,
      rule3MinUtteranceLength:
          (json['rule3MinUtteranceLength'] as num?)?.toDouble() ?? 20.0,
      hotwordsFile: json['hotwordsFile'] as String? ?? '',
      hotwordsScore: (json['hotwordsScore'] as num?)?.toDouble() ?? 1.5,
      ctcFstDecoderConfig: OnlineCtcFstDecoderConfig.fromJson(
          json['ctcFstDecoderConfig'] as Map<String, dynamic>? ?? const {}),
      ruleFsts: json['ruleFsts'] as String? ?? '',
      ruleFars: json['ruleFars'] as String? ?? '',
      blankPenalty: (json['blankPenalty'] as num?)?.toDouble() ?? 0.0,
      hr: HomophoneReplacerConfig.fromJson(
          json['hr'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
    );
  }

  @override
  String toString() {
    return 'OnlineRecognizerConfig(feat: $feat, model: $model, decodingMethod: $decodingMethod, maxActivePaths: $maxActivePaths, enableEndpoint: $enableEndpoint, rule1MinTrailingSilence: $rule1MinTrailingSilence, rule2MinTrailingSilence: $rule2MinTrailingSilence, rule3MinUtteranceLength: $rule3MinUtteranceLength, hotwordsFile: $hotwordsFile, hotwordsScore: $hotwordsScore, ctcFstDecoderConfig: $ctcFstDecoderConfig, ruleFsts: $ruleFsts, ruleFars: $ruleFars, blankPenalty: $blankPenalty, hr: $hr)';
  }

  Map<String, dynamic> toJson() => {
        'feat': feat.toJson(),
        'model': model.toJson(),
        'decodingMethod': decodingMethod,
        'maxActivePaths': maxActivePaths,
        'enableEndpoint': enableEndpoint,
        'rule1MinTrailingSilence': rule1MinTrailingSilence,
        'rule2MinTrailingSilence': rule2MinTrailingSilence,
        'rule3MinUtteranceLength': rule3MinUtteranceLength,
        'hotwordsFile': hotwordsFile,
        'hotwordsScore': hotwordsScore,
        'ctcFstDecoderConfig': ctcFstDecoderConfig.toJson(),
        'ruleFsts': ruleFsts,
        'ruleFars': ruleFars,
        'blankPenalty': blankPenalty,
        'hr': hr.toJson(),
      };

  final FeatureConfig feat;
  final OnlineModelConfig model;
  final String decodingMethod;

  final int maxActivePaths;

  final bool enableEndpoint;

  final double rule1MinTrailingSilence;

  final double rule2MinTrailingSilence;

  final double rule3MinUtteranceLength;

  final String hotwordsFile;

  final double hotwordsScore;

  final OnlineCtcFstDecoderConfig ctcFstDecoderConfig;
  final String ruleFsts;
  final String ruleFars;

  final double blankPenalty;
  final HomophoneReplacerConfig hr;
}

class SileroVadModelConfig {
  const SileroVadModelConfig(
      {this.model = '',
      this.threshold = 0.5,
      this.minSilenceDuration = 0.5,
      this.minSpeechDuration = 0.25,
      this.windowSize = 512,
      this.maxSpeechDuration = 5.0});

  factory SileroVadModelConfig.fromJson(Map<String, dynamic> json) {
    return SileroVadModelConfig(
      model: json['model'] as String? ?? '',
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.5,
      minSilenceDuration:
          (json['minSilenceDuration'] as num?)?.toDouble() ?? 0.5,
      minSpeechDuration:
          (json['minSpeechDuration'] as num?)?.toDouble() ?? 0.25,
      windowSize: json['windowSize'] as int? ?? 512,
      maxSpeechDuration: (json['maxSpeechDuration'] as num?)?.toDouble() ?? 5.0,
    );
  }

  @override
  String toString() {
    return 'SileroVadModelConfig(model: $model, threshold: $threshold, minSilenceDuration: $minSilenceDuration, minSpeechDuration: $minSpeechDuration, windowSize: $windowSize, maxSpeechDuration: $maxSpeechDuration)';
  }

  Map<String, dynamic> toJson() => {
        'model': model,
        'threshold': threshold,
        'minSilenceDuration': minSilenceDuration,
        'minSpeechDuration': minSpeechDuration,
        'windowSize': windowSize,
        'maxSpeechDuration': maxSpeechDuration,
      };

  final String model;
  final double threshold;
  final double minSilenceDuration;
  final double minSpeechDuration;
  final int windowSize;
  final double maxSpeechDuration;
}

class VadModelConfig {
  VadModelConfig({
    this.sileroVad = const SileroVadModelConfig(),
    this.sampleRate = 16000,
    this.numThreads = 1,
    this.provider = 'cpu',
    this.debug = true,
  });

  final SileroVadModelConfig sileroVad;
  final int sampleRate;
  final int numThreads;
  final String provider;
  final bool debug;

  factory VadModelConfig.fromJson(Map<String, dynamic> json) {
    return VadModelConfig(
      sileroVad: SileroVadModelConfig.fromJson(
          json['sileroVad'] as Map<String, dynamic>? ?? const <String, dynamic>{}),
      sampleRate: json['sampleRate'] as int? ?? 16000,
      numThreads: json['numThreads'] as int? ?? 1,
      provider: json['provider'] as String? ?? 'cpu',
      debug: json['debug'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'sileroVad': sileroVad.toJson(),
        'sampleRate': sampleRate,
        'numThreads': numThreads,
        'provider': provider,
        'debug': debug,
      };

  @override
  String toString() {
    return 'VadModelConfig(sileroVad: $sileroVad, sampleRate: $sampleRate, numThreads: $numThreads, provider: $provider, debug: $debug)';
  }
}

class OnlinePunctuationModelConfig {
  OnlinePunctuationModelConfig(
      {required this.cnnBiLstm,
      required this.bpeVocab,
      this.numThreads = 1,
      this.provider = 'cpu',
      this.debug = true});

  factory OnlinePunctuationModelConfig.fromJson(Map<String, dynamic> json) {
    return OnlinePunctuationModelConfig(
      cnnBiLstm: json['cnnBiLstm'] as String? ?? '',
      bpeVocab: json['bpeVocab'] as String? ?? '',
      numThreads: json['numThreads'] as int? ?? 1,
      provider: json['provider'] as String? ?? 'cpu',
      debug: json['debug'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'OnlinePunctuationModelConfig(cnnBiLstm: $cnnBiLstm, '
        'bpeVocab: $bpeVocab, numThreads: $numThreads, '
        'provider: $provider, debug: $debug)';
  }

  Map<String, dynamic> toJson() {
    return {
      'cnnBiLstm': cnnBiLstm,
      'bpeVocab': bpeVocab,
      'numThreads': numThreads,
      'provider': provider,
      'debug': debug,
    };
  }

  final String cnnBiLstm;
  final String bpeVocab;
  final int numThreads;
  final String provider;
  final bool debug;
}

class OnlinePunctuationConfig {
  OnlinePunctuationConfig({
    required this.model,
  });

  factory OnlinePunctuationConfig.fromJson(Map<String, dynamic> json) {
    return OnlinePunctuationConfig(
      model: OnlinePunctuationModelConfig.fromJson(
          json['model'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() {
    return 'OnlinePunctuationConfig(model: $model)';
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model.toJson(),
    };
  }

  final OnlinePunctuationModelConfig model;
}

// Text-to-Speech Models

class OfflineTtsVitsModelConfig {
  const OfflineTtsVitsModelConfig({
    this.model = '',
    this.lexicon = '',
    this.tokens = '',
    this.dataDir = '',
    this.noiseScale = 0.667,
    this.noiseScaleW = 0.8,
    this.lengthScale = 1.0,
    this.dictDir = '',
  });

  factory OfflineTtsVitsModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineTtsVitsModelConfig(
      model: json['model'] as String? ?? '',
      lexicon: json['lexicon'] as String? ?? '',
      tokens: json['tokens'] as String? ?? '',
      dataDir: json['dataDir'] as String? ?? '',
      noiseScale: (json['noiseScale'] as num?)?.toDouble() ?? 0.667,
      noiseScaleW: (json['noiseScaleW'] as num?)?.toDouble() ?? 0.8,
      lengthScale: (json['lengthScale'] as num?)?.toDouble() ?? 1.0,
      dictDir: json['dictDir'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineTtsVitsModelConfig(model: $model, lexicon: $lexicon, tokens: $tokens, dataDir: $dataDir, noiseScale: $noiseScale, noiseScaleW: $noiseScaleW, lengthScale: $lengthScale, dictDir: $dictDir)';
  }

  Map<String, dynamic> toJson() => {
    'model': model,
    'lexicon': lexicon,
    'tokens': tokens,
    'dataDir': dataDir,
    'noiseScale': noiseScale,
    'noiseScaleW': noiseScaleW,
    'lengthScale': lengthScale,
    'dictDir': dictDir,
  };

  final String model;
  final String lexicon;
  final String tokens;
  final String dataDir;
  final double noiseScale;
  final double noiseScaleW;
  final double lengthScale;
  final String dictDir;
}

class OfflineTtsMatchaModelConfig {
  const OfflineTtsMatchaModelConfig({
    this.acousticModel = '',
    this.vocoder = '',
    this.lexicon = '',
    this.tokens = '',
    this.dataDir = '',
    this.noiseScale = 0.667,
    this.lengthScale = 1.0,
    this.dictDir = '',
  });

  factory OfflineTtsMatchaModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineTtsMatchaModelConfig(
      acousticModel: json['acousticModel'] as String? ?? '',
      vocoder: json['vocoder'] as String? ?? '',
      lexicon: json['lexicon'] as String? ?? '',
      tokens: json['tokens'] as String? ?? '',
      dataDir: json['dataDir'] as String? ?? '',
      noiseScale: (json['noiseScale'] as num?)?.toDouble() ?? 0.667,
      lengthScale: (json['lengthScale'] as num?)?.toDouble() ?? 1.0,
      dictDir: json['dictDir'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineTtsMatchaModelConfig(acousticModel: $acousticModel, vocoder: $vocoder, lexicon: $lexicon, tokens: $tokens, dataDir: $dataDir, noiseScale: $noiseScale, lengthScale: $lengthScale, dictDir: $dictDir)';
  }

  Map<String, dynamic> toJson() => {
    'acousticModel': acousticModel,
    'vocoder': vocoder,
    'lexicon': lexicon,
    'tokens': tokens,
    'dataDir': dataDir,
    'noiseScale': noiseScale,
    'lengthScale': lengthScale,
    'dictDir': dictDir,
  };

  final String acousticModel;
  final String vocoder;
  final String lexicon;
  final String tokens;
  final String dataDir;
  final double noiseScale;
  final double lengthScale;
  final String dictDir;
}

class OfflineTtsKokoroModelConfig {
  const OfflineTtsKokoroModelConfig({
    this.model = '',
    this.voices = '',
    this.tokens = '',
    this.dataDir = '',
    this.lengthScale = 1.0,
    this.dictDir = '',
    this.lexicon = '',
    this.lang = '',
  });

  factory OfflineTtsKokoroModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineTtsKokoroModelConfig(
      model: json['model'] as String? ?? '',
      voices: json['voices'] as String? ?? '',
      tokens: json['tokens'] as String? ?? '',
      dataDir: json['dataDir'] as String? ?? '',
      lengthScale: (json['lengthScale'] as num?)?.toDouble() ?? 1.0,
      dictDir: json['dictDir'] as String? ?? '',
      lexicon: json['lexicon'] as String? ?? '',
      lang: json['lang'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineTtsKokoroModelConfig(model: $model, voices: $voices, tokens: $tokens, dataDir: $dataDir, lengthScale: $lengthScale, dictDir: $dictDir, lexicon: $lexicon, lang: $lang)';
  }

  Map<String, dynamic> toJson() => {
    'model': model,
    'voices': voices,
    'tokens': tokens,
    'dataDir': dataDir,
    'lengthScale': lengthScale,
    'dictDir': dictDir,
    'lexicon': lexicon,
    'lang': lang,
  };

  final String model;
  final String voices;
  final String tokens;
  final String dataDir;
  final double lengthScale;
  final String dictDir;
  final String lexicon;
  final String lang;
}

class OfflineTtsModelConfig {
  const OfflineTtsModelConfig({
    this.vits = const OfflineTtsVitsModelConfig(),
    this.matcha = const OfflineTtsMatchaModelConfig(),
    this.kokoro = const OfflineTtsKokoroModelConfig(),
    this.numThreads = 1,
    this.debug = true,
    this.provider = 'cpu',
  });

  factory OfflineTtsModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineTtsModelConfig(
      vits: OfflineTtsVitsModelConfig.fromJson(
          json['vits'] as Map<String, dynamic>? ?? const {}),
      matcha: OfflineTtsMatchaModelConfig.fromJson(
          json['matcha'] as Map<String, dynamic>? ?? const {}),
      kokoro: OfflineTtsKokoroModelConfig.fromJson(
          json['kokoro'] as Map<String, dynamic>? ?? const {}),
      numThreads: json['numThreads'] as int? ?? 1,
      debug: json['debug'] as bool? ?? true,
      provider: json['provider'] as String? ?? 'cpu',
    );
  }

  @override
  String toString() {
    return 'OfflineTtsModelConfig(vits: $vits, matcha: $matcha, kokoro: $kokoro, numThreads: $numThreads, debug: $debug, provider: $provider)';
  }

  Map<String, dynamic> toJson() => {
    'vits': vits.toJson(),
    'matcha': matcha.toJson(),
    'kokoro': kokoro.toJson(),
    'numThreads': numThreads,
    'debug': debug,
    'provider': provider,
  };

  final OfflineTtsVitsModelConfig vits;
  final OfflineTtsMatchaModelConfig matcha;
  final OfflineTtsKokoroModelConfig kokoro;
  final int numThreads;
  final bool debug;
  final String provider;
}

class OfflineTtsConfig {
  const OfflineTtsConfig({
    required this.model,
    this.ruleFsts = '',
    this.maxNumSenetences = 1,
    this.ruleFars = '',
    this.silenceScale = 0.2,
  });

  factory OfflineTtsConfig.fromJson(Map<String, dynamic> json) {
    return OfflineTtsConfig(
      model:
      OfflineTtsModelConfig.fromJson(json['model'] as Map<String, dynamic>),
      ruleFsts: json['ruleFsts'] as String? ?? '',
      maxNumSenetences: json['maxNumSenetences'] as int? ?? 1,
      ruleFars: json['ruleFars'] as String? ?? '',
      silenceScale: (json['silenceScale'] as num?)?.toDouble() ?? 0.2,
    );
  }

  @override
  String toString() {
    return 'OfflineTtsConfig(model: $model, ruleFsts: $ruleFsts, maxNumSenetences: $maxNumSenetences, ruleFars: $ruleFars, silenceScale: $silenceScale)';
  }

  Map<String, dynamic> toJson() => {
    'model': model.toJson(),
    'ruleFsts': ruleFsts,
    'maxNumSenetences': maxNumSenetences,
    'ruleFars': ruleFars,
    'silenceScale': silenceScale,
  };

  final OfflineTtsModelConfig model;
  final String ruleFsts;
  final int maxNumSenetences;
  final String ruleFars;
  final double silenceScale;
}



