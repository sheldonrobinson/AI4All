// Speech-to-Text Models

class OfflineZipformerAudioTaggingModelConfig {
  const OfflineZipformerAudioTaggingModelConfig({this.model = ''});

  factory OfflineZipformerAudioTaggingModelConfig.fromJson(
    Map<String, dynamic> map,
  ) {
    return OfflineZipformerAudioTaggingModelConfig(
      model: (map['model'] ?? '') as String,
    );
  }

  @override
  String toString() {
    return 'OfflineZipformerAudioTaggingModelConfig(model: $model)';
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model,
    };
  }

  final String model;
}

class AudioTaggingModelConfig {
  AudioTaggingModelConfig({
    this.zipformer = const OfflineZipformerAudioTaggingModelConfig(),
    this.ced = '',
    this.numThreads = 1,
    this.provider = 'cpu',
    this.debug = true,
  });

  factory AudioTaggingModelConfig.fromJson(Map<String, dynamic> map) {
    return AudioTaggingModelConfig(
      zipformer: OfflineZipformerAudioTaggingModelConfig.fromJson(
        map['zipformer'] as Map<String, dynamic>,
      ),
      ced: (map['ced'] ?? '') as String,
      numThreads: (map['numThreads'] ?? 1) as int,
      provider: (map['provider'] ?? 'cpu') as String,
      debug: (map['debug'] ?? true) as bool,
    );
  }

  @override
  String toString() {
    return 'AudioTaggingModelConfig(zipformer: $zipformer, ced: $ced, numThreads: $numThreads, provider: $provider, debug: $debug)';
  }

  Map<String, dynamic> toJson() {
    return {
      'zipformer': zipformer.toJson(),
      'ced': ced,
      'numThreads': numThreads,
      'provider': provider,
      'debug': debug,
    };
  }

  final OfflineZipformerAudioTaggingModelConfig zipformer;
  final String ced;
  final int numThreads;
  final String provider;
  final bool debug;
}

class AudioTaggingConfig {
  AudioTaggingConfig({required this.model, this.labels = ''});

  factory AudioTaggingConfig.fromJson(Map<String, dynamic> map) {
    return AudioTaggingConfig(
      model: AudioTaggingModelConfig.fromJson(
        map['model'] as Map<String, dynamic>,
      ),
      labels: (map['labels'] ?? '') as String,
    );
  }

  @override
  String toString() {
    return 'AudioTaggingConfig(model: $model, labels: $labels)';
  }

  Map<String, dynamic> toJson() {
    return {
      'model': model.toJson(),
      'labels': labels,
    };
  }

  final AudioTaggingModelConfig model;
  final String labels;
}

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

class HomophoneReplacerConfig {
  const HomophoneReplacerConfig({
    this.dictDir = '',
    this.lexicon = '',
    this.ruleFsts = '',
  });

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

class OnlineNemoCtcModelConfig {
  const OnlineNemoCtcModelConfig({this.model = ''});

  factory OnlineNemoCtcModelConfig.fromJson(Map<String, dynamic> json) {
    return OnlineNemoCtcModelConfig(
      model: json['model'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OnlineNemoCtcModelConfig(model: $model)';
  }

  Map<String, dynamic> toJson() => {
    'model': model,
  };

  final String model;
}

class OnlineToneCtcModelConfig {
  const OnlineToneCtcModelConfig({this.model = ''});

  factory OnlineToneCtcModelConfig.fromJson(Map<String, dynamic> json) {
    return OnlineToneCtcModelConfig(
      model: json['model'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OnlineToneCtcModelConfig(model: $model)';
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
    this.nemoCtc = const OnlineNemoCtcModelConfig(),
    this.toneCtc = const OnlineToneCtcModelConfig(),
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
        json['transducer'] as Map<String, dynamic>? ?? const {},
      ),
      paraformer: OnlineParaformerModelConfig.fromJson(
        json['paraformer'] as Map<String, dynamic>? ?? const {},
      ),
      zipformer2Ctc: OnlineZipformer2CtcModelConfig.fromJson(
        json['zipformer2Ctc'] as Map<String, dynamic>? ?? const {},
      ),
      nemoCtc: OnlineNemoCtcModelConfig.fromJson(
        json['nemoCtc'] as Map<String, dynamic>? ?? const {},
      ),
      toneCtc: OnlineToneCtcModelConfig.fromJson(
        json['toneCtc'] as Map<String, dynamic>? ?? const {},
      ),
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
    return 'OnlineModelConfig(transducer: $transducer, paraformer: $paraformer, zipformer2Ctc: $zipformer2Ctc, nemoCtc: $nemoCtc, toneCtc: $toneCtc, tokens: $tokens, numThreads: $numThreads, provider: $provider, debug: $debug, modelType: $modelType, modelingUnit: $modelingUnit, bpeVocab: $bpeVocab)';
  }

  Map<String, dynamic> toJson() => {
    'transducer': transducer.toJson(),
    'paraformer': paraformer.toJson(),
    'zipformer2Ctc': zipformer2Ctc.toJson(),
    'nemoCtc': nemoCtc.toJson(),
    'toneCtc': toneCtc.toJson(),
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
  final OnlineNemoCtcModelConfig nemoCtc;
  final OnlineToneCtcModelConfig toneCtc;

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
        json['feat'] as Map<String, dynamic>? ?? const {},
      ),
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
        json['ctcFstDecoderConfig'] as Map<String, dynamic>? ?? const {},
      ),
      ruleFsts: json['ruleFsts'] as String? ?? '',
      ruleFars: json['ruleFars'] as String? ?? '',
      blankPenalty: (json['blankPenalty'] as num?)?.toDouble() ?? 0.0,
      hr: HomophoneReplacerConfig.fromJson(
        json['hr'] as Map<String, dynamic>? ?? const {},
      ),
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

class OfflineTransducerModelConfig {
  const OfflineTransducerModelConfig({
    this.encoder = '',
    this.decoder = '',
    this.joiner = '',
  });

  factory OfflineTransducerModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineTransducerModelConfig(
      encoder: json['encoder'] as String? ?? '',
      decoder: json['decoder'] as String? ?? '',
      joiner: json['joiner'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineTransducerModelConfig(encoder: $encoder, decoder: $decoder, joiner: $joiner)';
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

class OfflineParaformerModelConfig {
  const OfflineParaformerModelConfig({this.model = ''});

  factory OfflineParaformerModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineParaformerModelConfig(
      model: json['model'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineParaformerModelConfig(model: $model)';
  }

  Map<String, dynamic> toJson() => {
    'model': model,
  };

  final String model;
}

class OfflineNemoEncDecCtcModelConfig {
  const OfflineNemoEncDecCtcModelConfig({this.model = ''});

  factory OfflineNemoEncDecCtcModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineNemoEncDecCtcModelConfig(
      model: json['model'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineNemoEncDecCtcModelConfig(model: $model)';
  }

  Map<String, dynamic> toJson() => {
    'model': model,
  };

  final String model;
}

class OfflineDolphinModelConfig {
  const OfflineDolphinModelConfig({this.model = ''});

  factory OfflineDolphinModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineDolphinModelConfig(
      model: json['model'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineDolphinModelConfig(model: $model)';
  }

  Map<String, dynamic> toJson() => {
    'model': model,
  };

  final String model;
}

class OfflineZipformerCtcModelConfig {
  const OfflineZipformerCtcModelConfig({this.model = ''});

  factory OfflineZipformerCtcModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineZipformerCtcModelConfig(
      model: json['model'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineZipformerCtcModelConfig(model: $model)';
  }

  Map<String, dynamic> toJson() => {
    'model': model,
  };

  final String model;
}

class OfflineWenetCtcModelConfig {
  const OfflineWenetCtcModelConfig({this.model = ''});

  factory OfflineWenetCtcModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineWenetCtcModelConfig(
      model: json['model'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineWenetCtcModelConfig(model: $model)';
  }

  Map<String, dynamic> toJson() => {
    'model': model,
  };

  final String model;
}

class OfflineWhisperModelConfig {
  const OfflineWhisperModelConfig({
    this.encoder = '',
    this.decoder = '',
    this.language = '',
    this.task = '',
    this.tailPaddings = -1,
  });

  factory OfflineWhisperModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineWhisperModelConfig(
      encoder: json['encoder'] as String? ?? '',
      decoder: json['decoder'] as String? ?? '',
      language: json['language'] as String? ?? '',
      task: json['task'] as String? ?? '',
      tailPaddings: json['tailPaddings'] as int? ?? -1,
    );
  }

  @override
  String toString() {
    return 'OfflineWhisperModelConfig(encoder: $encoder, decoder: $decoder, language: $language, task: $task, tailPaddings: $tailPaddings)';
  }

  Map<String, dynamic> toJson() => {
    'encoder': encoder,
    'decoder': decoder,
    'language': language,
    'task': task,
    'tailPaddings': tailPaddings,
  };

  final String encoder;
  final String decoder;
  final String language;
  final String task;
  final int tailPaddings;
}

class OfflineCanaryModelConfig {
  const OfflineCanaryModelConfig({
    this.encoder = '',
    this.decoder = '',
    this.srcLang = 'en',
    this.tgtLang = 'en',
    this.usePnc = true,
  });

  factory OfflineCanaryModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineCanaryModelConfig(
      encoder: json['encoder'] as String? ?? '',
      decoder: json['decoder'] as String? ?? '',
      srcLang: json['srcLang'] as String? ?? 'en',
      tgtLang: json['tgtLang'] as String? ?? 'en',
      usePnc: json['usePnc'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'OfflineCanaryModelConfig(encoder: $encoder, decoder: $decoder, srcLang: $srcLang, tgtLang: $tgtLang, usePnc: $usePnc)';
  }

  Map<String, dynamic> toJson() => {
    'encoder': encoder,
    'decoder': decoder,
    'srcLang': srcLang,
    'tgtLang': tgtLang,
    'usePnc': usePnc,
  };

  final String encoder;
  final String decoder;
  final String srcLang;
  final String tgtLang;
  final bool usePnc;
}

class OfflineFireRedAsrModelConfig {
  const OfflineFireRedAsrModelConfig({this.encoder = '', this.decoder = ''});

  factory OfflineFireRedAsrModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineFireRedAsrModelConfig(
      encoder: json['encoder'] as String? ?? '',
      decoder: json['decoder'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineFireRedAsrModelConfig(encoder: $encoder, decoder: $decoder)';
  }

  Map<String, dynamic> toJson() => {
    'encoder': encoder,
    'decoder': decoder,
  };

  final String encoder;
  final String decoder;
}

class OfflineMoonshineModelConfig {
  const OfflineMoonshineModelConfig({
    this.preprocessor = '',
    this.encoder = '',
    this.uncachedDecoder = '',
    this.cachedDecoder = '',
  });

  factory OfflineMoonshineModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineMoonshineModelConfig(
      preprocessor: json['preprocessor'] as String? ?? '',
      encoder: json['encoder'] as String? ?? '',
      uncachedDecoder: json['uncachedDecoder'] as String? ?? '',
      cachedDecoder: json['cachedDecoder'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineMoonshineModelConfig(preprocessor: $preprocessor, encoder: $encoder, uncachedDecoder: $uncachedDecoder, cachedDecoder: $cachedDecoder)';
  }

  Map<String, dynamic> toJson() => {
    'preprocessor': preprocessor,
    'encoder': encoder,
    'uncachedDecoder': uncachedDecoder,
    'cachedDecoder': cachedDecoder,
  };

  final String preprocessor;
  final String encoder;
  final String uncachedDecoder;
  final String cachedDecoder;
}

class OfflineTdnnModelConfig {
  const OfflineTdnnModelConfig({this.model = ''});

  factory OfflineTdnnModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineTdnnModelConfig(
      model: json['model'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineTdnnModelConfig(model: $model)';
  }

  Map<String, dynamic> toJson() => {
    'model': model,
  };

  final String model;
}

class OfflineSenseVoiceModelConfig {
  const OfflineSenseVoiceModelConfig({
    this.model = '',
    this.language = '',
    this.useInverseTextNormalization = false,
  });

  factory OfflineSenseVoiceModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineSenseVoiceModelConfig(
      model: json['model'] as String? ?? '',
      language: json['language'] as String? ?? '',
      useInverseTextNormalization:
          json['useInverseTextNormalization'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'OfflineSenseVoiceModelConfig(model: $model, language: $language, useInverseTextNormalization: $useInverseTextNormalization)';
  }

  Map<String, dynamic> toJson() => {
    'model': model,
    'language': language,
    'useInverseTextNormalization': useInverseTextNormalization,
  };

  final String model;
  final String language;
  final bool useInverseTextNormalization;
}

class OfflineLMConfig {
  const OfflineLMConfig({this.model = '', this.scale = 1.0});

  factory OfflineLMConfig.fromJson(Map<String, dynamic> json) {
    return OfflineLMConfig(
      model: json['model'] as String? ?? '',
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  String toString() {
    return 'OfflineLMConfig(model: $model, scale: $scale)';
  }

  Map<String, dynamic> toJson() => {
    'model': model,
    'scale': scale,
  };

  final String model;
  final double scale;
}

class OfflineModelConfig {
  const OfflineModelConfig({
    this.transducer = const OfflineTransducerModelConfig(),
    this.paraformer = const OfflineParaformerModelConfig(),
    this.nemoCtc = const OfflineNemoEncDecCtcModelConfig(),
    this.whisper = const OfflineWhisperModelConfig(),
    this.tdnn = const OfflineTdnnModelConfig(),
    this.senseVoice = const OfflineSenseVoiceModelConfig(),
    this.moonshine = const OfflineMoonshineModelConfig(),
    this.fireRedAsr = const OfflineFireRedAsrModelConfig(),
    this.dolphin = const OfflineDolphinModelConfig(),
    this.zipformerCtc = const OfflineZipformerCtcModelConfig(),
    this.canary = const OfflineCanaryModelConfig(),
    this.wenetCtc = const OfflineWenetCtcModelConfig(),
    required this.tokens,
    this.numThreads = 1,
    this.debug = true,
    this.provider = 'cpu',
    this.modelType = '',
    this.modelingUnit = '',
    this.bpeVocab = '',
    this.telespeechCtc = '',
  });

  factory OfflineModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineModelConfig(
      transducer:
          json['transducer'] != null
              ? OfflineTransducerModelConfig.fromJson(
                json['transducer'] as Map<String, dynamic>,
              )
              : const OfflineTransducerModelConfig(),
      paraformer:
          json['paraformer'] != null
              ? OfflineParaformerModelConfig.fromJson(
                json['paraformer'] as Map<String, dynamic>,
              )
              : const OfflineParaformerModelConfig(),
      nemoCtc:
          json['nemoCtc'] != null
              ? OfflineNemoEncDecCtcModelConfig.fromJson(
                json['nemoCtc'] as Map<String, dynamic>,
              )
              : const OfflineNemoEncDecCtcModelConfig(),
      whisper:
          json['whisper'] != null
              ? OfflineWhisperModelConfig.fromJson(
                json['whisper'] as Map<String, dynamic>,
              )
              : const OfflineWhisperModelConfig(),
      tdnn:
          json['tdnn'] != null
              ? OfflineTdnnModelConfig.fromJson(
                json['tdnn'] as Map<String, dynamic>,
              )
              : const OfflineTdnnModelConfig(),
      senseVoice:
          json['senseVoice'] != null
              ? OfflineSenseVoiceModelConfig.fromJson(
                json['senseVoice'] as Map<String, dynamic>,
              )
              : const OfflineSenseVoiceModelConfig(),
      moonshine:
          json['moonshine'] != null
              ? OfflineMoonshineModelConfig.fromJson(
                json['moonshine'] as Map<String, dynamic>,
              )
              : const OfflineMoonshineModelConfig(),
      fireRedAsr:
          json['fireRedAsr'] != null
              ? OfflineFireRedAsrModelConfig.fromJson(
                json['fireRedAsr'] as Map<String, dynamic>,
              )
              : const OfflineFireRedAsrModelConfig(),
      dolphin:
          json['dolphin'] != null
              ? OfflineDolphinModelConfig.fromJson(
                json['dolphin'] as Map<String, dynamic>,
              )
              : const OfflineDolphinModelConfig(),
      zipformerCtc:
          json['zipformerCtc'] != null
              ? OfflineZipformerCtcModelConfig.fromJson(
                json['zipformerCtc'] as Map<String, dynamic>,
              )
              : const OfflineZipformerCtcModelConfig(),
      canary:
          json['canary'] != null
              ? OfflineCanaryModelConfig.fromJson(
                json['canary'] as Map<String, dynamic>,
              )
              : const OfflineCanaryModelConfig(),
      wenetCtc:
          json['wenetCtc'] != null
              ? OfflineWenetCtcModelConfig.fromJson(
                json['wenetCtc'] as Map<String, dynamic>,
              )
              : const OfflineWenetCtcModelConfig(),
      tokens: json['tokens'] as String,
      numThreads: json['numThreads'] as int? ?? 1,
      debug: json['debug'] as bool? ?? true,
      provider: json['provider'] as String? ?? 'cpu',
      modelType: json['modelType'] as String? ?? '',
      modelingUnit: json['modelingUnit'] as String? ?? '',
      bpeVocab: json['bpeVocab'] as String? ?? '',
      telespeechCtc: json['telespeechCtc'] as String? ?? '',
    );
  }

  @override
  String toString() {
    return 'OfflineModelConfig(transducer: $transducer, paraformer: $paraformer, nemoCtc: $nemoCtc, whisper: $whisper, tdnn: $tdnn, senseVoice: $senseVoice, moonshine: $moonshine, fireRedAsr: $fireRedAsr, dolphin: $dolphin, zipformerCtc: $zipformerCtc, canary: $canary, wenetCtc: $wenetCtc, tokens: $tokens, numThreads: $numThreads, debug: $debug, provider: $provider, modelType: $modelType, modelingUnit: $modelingUnit, bpeVocab: $bpeVocab, telespeechCtc: $telespeechCtc)';
  }

  Map<String, dynamic> toJson() => {
    'transducer': transducer.toJson(),
    'paraformer': paraformer.toJson(),
    'nemoCtc': nemoCtc.toJson(),
    'whisper': whisper.toJson(),
    'tdnn': tdnn.toJson(),
    'senseVoice': senseVoice.toJson(),
    'moonshine': moonshine.toJson(),
    'fireRedAsr': fireRedAsr.toJson(),
    'dolphin': dolphin.toJson(),
    'zipformerCtc': zipformerCtc.toJson(),
    'canary': canary.toJson(),
    'wenetCtc': wenetCtc.toJson(),
    'tokens': tokens,
    'numThreads': numThreads,
    'debug': debug,
    'provider': provider,
    'modelType': modelType,
    'modelingUnit': modelingUnit,
    'bpeVocab': bpeVocab,
    'telespeechCtc': telespeechCtc,
  };

  final OfflineTransducerModelConfig transducer;
  final OfflineParaformerModelConfig paraformer;
  final OfflineNemoEncDecCtcModelConfig nemoCtc;
  final OfflineWhisperModelConfig whisper;
  final OfflineTdnnModelConfig tdnn;
  final OfflineSenseVoiceModelConfig senseVoice;
  final OfflineMoonshineModelConfig moonshine;
  final OfflineFireRedAsrModelConfig fireRedAsr;
  final OfflineDolphinModelConfig dolphin;
  final OfflineZipformerCtcModelConfig zipformerCtc;
  final OfflineCanaryModelConfig canary;
  final OfflineWenetCtcModelConfig wenetCtc;

  final String tokens;
  final int numThreads;
  final bool debug;
  final String provider;
  final String modelType;
  final String modelingUnit;
  final String bpeVocab;
  final String telespeechCtc;
}

class OfflineRecognizerConfig {
  const OfflineRecognizerConfig({
    this.feat = const FeatureConfig(),
    required this.model,
    this.lm = const OfflineLMConfig(),
    this.decodingMethod = 'greedy_search',
    this.maxActivePaths = 4,
    this.hotwordsFile = '',
    this.hotwordsScore = 1.5,
    this.ruleFsts = '',
    this.ruleFars = '',
    this.blankPenalty = 0.0,
    this.hr = const HomophoneReplacerConfig(),
  });

  factory OfflineRecognizerConfig.fromJson(Map<String, dynamic> json) {
    return OfflineRecognizerConfig(
      feat:
          json['feat'] != null
              ? FeatureConfig.fromJson(json['feat'] as Map<String, dynamic>)
              : const FeatureConfig(),
      model: OfflineModelConfig.fromJson(json['model'] as Map<String, dynamic>),
      lm:
          json['lm'] != null
              ? OfflineLMConfig.fromJson(json['lm'] as Map<String, dynamic>)
              : const OfflineLMConfig(),
      decodingMethod: json['decodingMethod'] as String? ?? 'greedy_search',
      maxActivePaths: json['maxActivePaths'] as int? ?? 4,
      hotwordsFile: json['hotwordsFile'] as String? ?? '',
      hotwordsScore: (json['hotwordsScore'] as num?)?.toDouble() ?? 1.5,
      ruleFsts: json['ruleFsts'] as String? ?? '',
      ruleFars: json['ruleFars'] as String? ?? '',
      blankPenalty: (json['blankPenalty'] as num?)?.toDouble() ?? 0.0,
      hr: HomophoneReplacerConfig.fromJson(json['hr'] as Map<String, dynamic>),
    );
  }

  @override
  String toString() {
    return 'OfflineRecognizerConfig(feat: $feat, model: $model, lm: $lm, decodingMethod: $decodingMethod, maxActivePaths: $maxActivePaths, hotwordsFile: $hotwordsFile, hotwordsScore: $hotwordsScore, ruleFsts: $ruleFsts, ruleFars: $ruleFars, blankPenalty: $blankPenalty, hr: $hr)';
  }

  Map<String, dynamic> toJson() => {
    'feat': feat.toJson(),
    'model': model.toJson(),
    'lm': lm.toJson(),
    'decodingMethod': decodingMethod,
    'maxActivePaths': maxActivePaths,
    'hotwordsFile': hotwordsFile,
    'hotwordsScore': hotwordsScore,
    'ruleFsts': ruleFsts,
    'ruleFars': ruleFars,
    'blankPenalty': blankPenalty,
    'hr': hr.toJson(),
  };

  final FeatureConfig feat;
  final OfflineModelConfig model;
  final OfflineLMConfig lm;
  final String decodingMethod;

  final int maxActivePaths;

  final String hotwordsFile;

  final double hotwordsScore;

  final String ruleFsts;
  final String ruleFars;

  final double blankPenalty;
  final HomophoneReplacerConfig hr;
}

class OfflinePunctuationModelConfig {
  OfflinePunctuationModelConfig({
    required this.ctTransformer,
    this.numThreads = 1,
    this.provider = 'cpu',
    this.debug = true,
  });

  factory OfflinePunctuationModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflinePunctuationModelConfig(
      ctTransformer: json['ctTransformer'] as String,
      numThreads: json['numThreads'] as int? ?? 1,
      provider: json['provider'] as String? ?? 'cpu',
      debug: json['debug'] as bool? ?? true,
    );
  }

  @override
  String toString() {
    return 'OfflinePunctuationModelConfig(ctTransformer: $ctTransformer, numThreads: $numThreads, provider: $provider, debug: $debug)';
  }

  Map<String, dynamic> toJson() => {
    'ctTransformer': ctTransformer,
    'numThreads': numThreads,
    'provider': provider,
    'debug': debug,
  };

  final String ctTransformer;
  final int numThreads;
  final String provider;
  final bool debug;
}

class OfflinePunctuationConfig {
  OfflinePunctuationConfig({
    required this.model,
  });

  factory OfflinePunctuationConfig.fromJson(Map<String, dynamic> json) {
    return OfflinePunctuationConfig(
      model: OfflinePunctuationModelConfig.fromJson(
        json['model'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  String toString() {
    return 'OfflinePunctuationConfig(model: $model)';
  }

  Map<String, dynamic> toJson() => {
    'model': model.toJson(),
  };

  final OfflinePunctuationModelConfig model;
}

class OnlinePunctuationModelConfig {
  OnlinePunctuationModelConfig({
    required this.cnnBiLstm,
    required this.bpeVocab,
    this.numThreads = 1,
    this.provider = 'cpu',
    this.debug = true,
  });

  factory OnlinePunctuationModelConfig.fromJson(Map<String, dynamic> json) {
    return OnlinePunctuationModelConfig(
      cnnBiLstm: json['cnnBiLstm'] as String,
      bpeVocab: json['bpeVocab'] as String,
      numThreads: json['numThreads'] as int,
      provider: json['provider'] as String,
      debug: json['debug'] as bool,
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
        json['model'] as Map<String, dynamic>,
      ),
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

class SileroVadModelConfig {
  const SileroVadModelConfig({
    this.model = '',
    this.threshold = 0.5,
    this.minSilenceDuration = 0.5,
    this.minSpeechDuration = 0.25,
    this.windowSize = 512,
    this.maxSpeechDuration = 5.0,
  });

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

class TenVadModelConfig {
  const TenVadModelConfig({
    this.model = '',
    this.threshold = 0.5,
    this.minSilenceDuration = 0.5,
    this.minSpeechDuration = 0.25,
    this.windowSize = 256,
    this.maxSpeechDuration = 5.0,
  });

  factory TenVadModelConfig.fromJson(Map<String, dynamic> json) {
    return TenVadModelConfig(
      model: json['model'] as String? ?? '',
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.5,
      minSilenceDuration:
          (json['minSilenceDuration'] as num?)?.toDouble() ?? 0.5,
      minSpeechDuration:
          (json['minSpeechDuration'] as num?)?.toDouble() ?? 0.25,
      windowSize: json['windowSize'] as int? ?? 256,
      maxSpeechDuration: (json['maxSpeechDuration'] as num?)?.toDouble() ?? 5.0,
    );
  }

  @override
  String toString() {
    return 'TenVadModelConfig(model: $model, threshold: $threshold, minSilenceDuration: $minSilenceDuration, minSpeechDuration: $minSpeechDuration, windowSize: $windowSize, maxSpeechDuration: $maxSpeechDuration)';
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
    this.tenVad = const TenVadModelConfig(),
  });

  final SileroVadModelConfig sileroVad;
  final TenVadModelConfig tenVad;
  final int sampleRate;
  final int numThreads;
  final String provider;
  final bool debug;

  factory VadModelConfig.fromJson(Map<String, dynamic> json) {
    return VadModelConfig(
      sileroVad: SileroVadModelConfig.fromJson(
        json['sileroVad'] as Map<String, dynamic>? ?? const {},
      ),
      tenVad: TenVadModelConfig.fromJson(
        json['tenVad'] as Map<String, dynamic>? ?? const {},
      ),
      sampleRate: json['sampleRate'] as int? ?? 16000,
      numThreads: json['numThreads'] as int? ?? 1,
      provider: json['provider'] as String? ?? 'cpu',
      debug: json['debug'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'sileroVad': sileroVad.toJson(),
    'tenVad': tenVad.toJson(),
    'sampleRate': sampleRate,
    'numThreads': numThreads,
    'provider': provider,
    'debug': debug,
  };

  @override
  String toString() {
    return 'VadModelConfig(sileroVad: $sileroVad, tenVad: $tenVad, sampleRate: $sampleRate, numThreads: $numThreads, provider: $provider, debug: $debug)';
  }
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

class OfflineTtsKittenModelConfig {
  const OfflineTtsKittenModelConfig({
    this.model = '',
    this.voices = '',
    this.tokens = '',
    this.dataDir = '',
    this.lengthScale = 1.0,
  });

  factory OfflineTtsKittenModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineTtsKittenModelConfig(
      model: json['model'] as String? ?? '',
      voices: json['voices'] as String? ?? '',
      tokens: json['tokens'] as String? ?? '',
      dataDir: json['dataDir'] as String? ?? '',
      lengthScale: (json['lengthScale'] as num?)?.toDouble() ?? 1.0,
    );
  }

  @override
  String toString() {
    return 'OfflineTtsKittenModelConfig(model: $model, voices: $voices, tokens: $tokens, dataDir: $dataDir, lengthScale: $lengthScale)';
  }

  Map<String, dynamic> toJson() => {
    'model': model,
    'voices': voices,
    'tokens': tokens,
    'dataDir': dataDir,
    'lengthScale': lengthScale,
  };

  final String model;
  final String voices;
  final String tokens;
  final String dataDir;
  final double lengthScale;
}

class OfflineTtsModelConfig {
  const OfflineTtsModelConfig({
    this.vits = const OfflineTtsVitsModelConfig(),
    this.matcha = const OfflineTtsMatchaModelConfig(),
    this.kokoro = const OfflineTtsKokoroModelConfig(),
    this.kitten = const OfflineTtsKittenModelConfig(),
    this.numThreads = 1,
    this.debug = true,
    this.provider = 'cpu',
  });

  factory OfflineTtsModelConfig.fromJson(Map<String, dynamic> json) {
    return OfflineTtsModelConfig(
      vits: OfflineTtsVitsModelConfig.fromJson(
        json['vits'] as Map<String, dynamic>? ?? const {},
      ),
      matcha: OfflineTtsMatchaModelConfig.fromJson(
        json['matcha'] as Map<String, dynamic>? ?? const {},
      ),
      kokoro: OfflineTtsKokoroModelConfig.fromJson(
        json['kokoro'] as Map<String, dynamic>? ?? const {},
      ),
      kitten: OfflineTtsKittenModelConfig.fromJson(
        json['kitten'] as Map<String, dynamic>? ?? const {},
      ),
      numThreads: json['numThreads'] as int? ?? 1,
      debug: json['debug'] as bool? ?? true,
      provider: json['provider'] as String? ?? 'cpu',
    );
  }

  @override
  String toString() {
    return 'OfflineTtsModelConfig(vits: $vits, matcha: $matcha, kokoro: $kokoro, kitten: $kitten, numThreads: $numThreads, debug: $debug, provider: $provider)';
  }

  Map<String, dynamic> toJson() => {
    'vits': vits.toJson(),
    'matcha': matcha.toJson(),
    'kokoro': kokoro.toJson(),
    'kitten': kitten.toJson(),
    'numThreads': numThreads,
    'debug': debug,
    'provider': provider,
  };

  final OfflineTtsVitsModelConfig vits;
  final OfflineTtsMatchaModelConfig matcha;
  final OfflineTtsKokoroModelConfig kokoro;
  final OfflineTtsKittenModelConfig kitten;
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
      model: OfflineTtsModelConfig.fromJson(
        json['model'] as Map<String, dynamic>,
      ),
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
