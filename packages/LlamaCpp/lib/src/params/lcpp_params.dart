part of 'package:llamacpp/llamacpp.dart';

/// Represents the parameters used for sampling in the model.
class LlamaCppParams {
  /// Do stop on eos
  final bool? ignoreEOS;

  /// disable performance metrics
  final bool? noPerf;

  /// Performance measurement per token
  final bool? timingPerToken;

  /// nNumber of previous tokens to remember
  final int? nPrev;

  /// If greater than 0, output the probabilities of top n_probs tokens.
  final int? nProbs;

  /// Optional seed for random number generation to ensure reproducibility.
  final int? seed;

  /// Limits the number of top candidates considered during sampling.
  final int? topK;

  /// Arguments for top-p sampling (nucleus sampling).
  final double? topP;

  /// Arguments for minimum-p sampling.
  final double? minP;

  /// Arguments for typical-p sampling.
  final double? typicalP;

  final double? topNsigma;

  /// The minimum number of items to keep in the sample.
  final int? minKeep;

  /// The temperature value for sampling.
  final double? temperature;

  /// Optional range parameter for temperature adjustment.
  final double? dynaTempRange;

  /// Optional exponent parameter for temperature adjustment.
  final double? dynaTempExponent;

  /// The probability threshold for XTC sampling.
  final double? xtcProbability;

  /// The threshold value for XTC sampling.
  final double? xtcThreshold;

  /// The tau value for Mirostat sampling.
  final double? mirostatTau;

  /// The eta value for Mirostat sampling.
  final double? mirostatEta;

  /// The number of items to keep in the sample.
  final lcpp_mirostat_type? mirostat;

  /// model family e.g. deepseek phi
  final lcpp_model_family? modelFamily;

  /// how to split the model across multiple GPUs
  final lcpp_split_mode? splitMode;

  /// Optional BNF-like grammar for constrained sampling.
  final String? grammar;

  /// Optional BNF-like grammar lazy parsing.
  final bool? grammarLazy;

  /// The number of items to consider for the penalty.
  final int? penaltyLastN;

  /// The penalty for repetition.
  final double? penaltyRepeat;

  /// The penalty frequency.
  final double? penaltyFrequency;

  /// The penalty for present items.
  final double? penaltyPresent;

  /// The multiplier for the penalty.
  final double? dryMultiplier;

  /// The base value for the penalty.
  final double? dryBase;

  /// The maximum allowed length for the sequence.
  final int? dryAllowedLength;

  /// The penalty for the last N items.
  final int? dryPenaltyLastN;

  final List<int>? samplers;

  /// path to GGUF model file
  final String? modelPath;

  /// Indicates whether only the vocabulary should be loaded.
  ///
  /// If `true`, only the vocabulary is loaded, which can be useful for
  /// certain operations where the full model is not required. If `false`
  /// or `null`, the full model is loaded.
  final bool? vocabOnly;

  /// Indicates whether memory-mapped files should be used.
  ///
  /// If `true`, memory-mapped files will be used, which can improve performance
  /// by allowing the operating system to manage memory more efficiently.
  /// If `false` or `null`, memory-mapped files will not be used.
  final bool? useMmap;

  /// Indicates whether memory locking (mlock) should be used.
  ///
  /// When `true`, the memory used by the application will be locked,
  /// preventing it from being swapped out to disk. This can improve
  /// performance by ensuring that the memory remains in RAM.
  ///
  /// When `false` or `null`, memory locking is not used.
  final bool? useMlock;

  /// A flag indicating whether to check tensors.
  ///
  /// If `true`, tensors will be checked. If `false` or `null`, tensors will not be checked.
  final bool? checkTensors;

  /// escape "\n", "\r", "\t", "\'", "\"", and "\\"
  final bool? escape;

  /// reverse the usage of `\`
  final bool? multilineInput;

  /// Is this a reasoning model
  final bool? isReasoning;

  /// Number of layers to store in VRAM
  ///
  /// If unset, will default to using CPU
  final int? nGpuLayers;

  /// The GPU that is used for the entire model when split_mode is LLAMA_SPLIT_MODE_NONE
  ///
  /// If unset default to gpu 0
  final int? mainGPU;

  /// Creates a new instance of [LlamaCppParams].
  const LlamaCppParams(
      {this.ignoreEOS,
      this.noPerf,
      this.timingPerToken,
      this.nPrev,
      this.nProbs,
      this.seed,
      this.topK,
      this.topP,
      this.minP,
      this.typicalP,
      this.topNsigma,
      this.minKeep,
      this.temperature,
      this.dynaTempRange,
      this.dynaTempExponent,
      this.xtcProbability,
      this.xtcThreshold,
      this.mirostatTau,
      this.mirostatEta,
      this.mirostat,
      this.modelFamily,
      this.splitMode,
      this.grammar,
      this.grammarLazy,
      this.penaltyLastN,
      this.penaltyRepeat,
      this.penaltyFrequency,
      this.penaltyPresent,
      this.dryMultiplier,
      this.dryBase,
      this.dryAllowedLength,
      this.dryPenaltyLastN,
      this.samplers,
      this.modelPath,
      this.vocabOnly,
      this.useMmap,
      this.useMlock,
      this.checkTensors,
      this.escape,
      this.multilineInput,
      this.isReasoning,
      this.nGpuLayers,
      this.mainGPU});

  /// Constructs a [LlamaCppParams] instance from a [Map].
  factory LlamaCppParams.fromMap(Map<String, dynamic> map) {
    return LlamaCppParams(
      ignoreEOS: map['ignoreEOS'],
      noPerf: map['noPerf'],
      timingPerToken: map['timingPerToken'],
      nPrev: map['nPrev']?.toInt(),
      nProbs: map['nProbs']?.toInt(),
      seed: map['seed']?.toInt(),
      topK: map['topK']?.toInt(),
      topP: map['topP']?.toDouble(),
      minP: map['minP']?.toDouble(),
      typicalP: map['typicalP']?.toDouble(),
      topNsigma: map['topNsigma']?.toDouble(),
      minKeep: map['minKeep']?.toInt(),
      temperature: map['temperature']?.toDouble(),
      dynaTempRange: map['dynaTempRange']?.toDouble(),
      dynaTempExponent: map['dynaTempExponent']?.toDouble(),
      xtcProbability: map['xtcProbability']?.toDouble(),
      xtcThreshold: map['xtcThreshold']?.toDouble(),
      mirostatTau: map['mirostatTau']?.toDouble(),
      mirostatEta: map['mirostatEta']?.toDouble(),
      mirostat: map['mirostat'] != null
          ? lcpp_mirostat_type.fromValue(map['mirostat'])
          : null,
      modelFamily: map['modelFamily'] != null
          ? lcpp_model_family.fromValue(map['modelFamily'])
          : null,
      splitMode: map['splitMode'] != null
          ? lcpp_split_mode.fromValue(map['splitMode'])
          : null,
      grammar: map['grammar'],
      grammarLazy: map['grammarLazy'],
      penaltyLastN: map['penaltyLastN']?.toInt(),
      penaltyRepeat: map['penaltyRepeat']?.toDouble(),
      penaltyFrequency: map['penaltyFrequency']?.toDouble(),
      penaltyPresent: map['penaltyPresent']?.toDouble(),
      dryMultiplier: map['dryMultiplier']?.toDouble(),
      dryBase: map['dryBase']?.toDouble(),
      dryAllowedLength: map['dryAllowedLength']?.toInt(),
      dryPenaltyLastN: map['dryPenaltyLastN']?.toInt(),
      samplers: List<int>.from(map['samplers']),
      modelPath: map['modelPath'],
      vocabOnly: map['vocabOnly'],
      useMmap: map['useMmap'],
      useMlock: map['useMlock'],
      checkTensors: map['checkTensors'],
      escape: map['escape'],
      multilineInput: map['multilineInput'],
      isReasoning: map['isReasoning'],
      nGpuLayers: map['nGpuLayers']?.toInt(),
      mainGPU: map['mainGPU']?.toInt(),
    );
  }

  /// Constructs a [LlamaCppParams] instance from a JSON string.
  factory LlamaCppParams.fromJson(String source) =>
      LlamaCppParams.fromMap(json.decode(source));

  factory LlamaCppParams.fromNative(lcpp_params params) {

    final defaultSamplers = <int>[];
    final nSamplers = params.n_samplers;
    for(int i = 0; i < nSamplers; i++){
      defaultSamplers.add(params.samplers[i]);
    }

    return LlamaCppParams(
        modelFamily: params.model_family,
        nGpuLayers: params.n_gpu_layers,
        checkTensors: params.check_tensors,
        dryAllowedLength: params.dry_allowed_length,
        dryBase: params.dry_base,
        dryMultiplier: params.dry_multiplier,
        dryPenaltyLastN: params.dry_penalty_last_n,
        dynaTempExponent: params.dynatemp_exponent,
        dynaTempRange: params.dynatemp_range,
        escape: params.escape,
        grammarLazy: params.grammar_lazy,
        ignoreEOS: params.ignore_eos,
        mainGPU: params.main_gpu,
        isReasoning: params.is_reasoning,
        minKeep: params.min_keep,
        minP: params.min_p,
        mirostat: params.mirostat,
        mirostatEta: params.mirostat_eta,
        mirostatTau: params.mirostat_tau,
        multilineInput: params.multiline_input,
        noPerf: params.no_perf,
        nPrev: params.n_prev,
        nProbs: params.n_probs,
        penaltyFrequency: params.penalty_freq,
        penaltyLastN: params.penalty_last_n,
        penaltyPresent: params.penalty_present,
        penaltyRepeat: params.penalty_repeat,
        seed: params.seed,
        splitMode: params.split_mode,
        temperature: params.temp,
        timingPerToken: params.timing_per_token,
        topNsigma: params.top_n_sigma,
        topK: params.top_k,
        topP: params.top_p,
        typicalP: params.typ_p,
        useMlock: params.use_mlock,
        useMmap: params.use_mmap,
        vocabOnly: params.vocab_only,
        xtcProbability: params.xtc_probability,
        xtcThreshold: params.xtc_threshold,
        samplers: defaultSamplers);
  }

  /// Factory constructor that creates an instance of [ContextParams] with default parameters.
  ///
  /// This constructor uses the `llama_context_default_params` function from the
  /// Llama library to obtain the default context parameters and then converts
  /// them to a [ContextParams] instance using the [ContextParams.fromNative] method.
  factory LlamaCppParams.defaultParams() {
    final lcpp_params contextParams = lcpp_params_defaults();

    return LlamaCppParams.fromNative(contextParams);
  }

  /// Converts this instance to a [Pointer<llama_sampler>].
  lcpp_params toNative() {
    final lcpp_params lcppParams = lcpp_params_defaults();

    if (ignoreEOS != null) {
      lcppParams.ignore_eos = ignoreEOS!;
    }

    if (noPerf != null) {
      lcppParams.no_perf = noPerf!;
    }

    if (timingPerToken != null) {
      lcppParams.timing_per_token = timingPerToken!;
    }

    if (nPrev != null) {
      lcppParams.n_prev = nPrev!;
    }

    if (nProbs != null) {
      lcppParams.n_probs = nProbs!;
    }

    if (seed != null) {
      lcppParams.seed = seed!;
    }

    if (topK != null) {
      lcppParams.top_k = topK!;
    }

    if (topP != null) {
      lcppParams.top_p = topP!;
    }

    if (minKeep != null) {
      lcppParams.min_keep = minKeep!;
    }

    if (minP != null) {
      lcppParams.min_p = minP!;
    }

    if (typicalP != null) {
      lcppParams.typ_p = typicalP!;
    }

    if (topNsigma != null) {
      lcppParams.top_n_sigma = topNsigma!;
    }

    if (temperature != null) {
      lcppParams.temp = temperature!;
    }

    if (dynaTempExponent != null) {
      lcppParams.dynatemp_exponent = dynaTempExponent!;
    }

    if (dynaTempRange != null) {
      lcppParams.dynatemp_range = dynaTempRange!;
    }

    if (xtcProbability != null) {
      lcppParams.xtc_probability = xtcProbability!;
    }

    if (xtcThreshold != null) {
      lcppParams.xtc_threshold = xtcThreshold!;
    }

    if (mirostat != null) {
      lcppParams.mirostatAsInt = mirostat!.value;
    }

    if (mirostatEta != null) {
      lcppParams.mirostat_eta = mirostatEta!;
    }

    if (mirostatTau != null) {
      lcppParams.mirostat_tau = mirostatTau!;
    }

    if (grammar != null) {
      lcppParams.grammar = grammar!.toNativeUtf8().cast<Char>();
      lcppParams.n_grammar_length = grammar!.length;
    }

    if (grammarLazy != null) {
      lcppParams.grammar_lazy = grammarLazy!;
    }

    if (penaltyFrequency != null) {
      lcppParams.penalty_freq = penaltyFrequency!;
    }

    if (penaltyLastN != null) {
      lcppParams.penalty_last_n = penaltyLastN!;
    }

    if (penaltyRepeat != null) {
      lcppParams.penalty_repeat = penaltyRepeat!;
    }

    if (penaltyPresent != null) {
      lcppParams.penalty_present = penaltyPresent!;
    }

    if (dryAllowedLength != null) {
      lcppParams.dry_allowed_length = dryAllowedLength!;
    }

    if (dryBase != null) {
      lcppParams.dry_base = dryBase!;
    }

    if (dryMultiplier != null) {
      lcppParams.dry_multiplier = dryMultiplier!;
    }

    if (dryPenaltyLastN != null) {
      lcppParams.dry_penalty_last_n = dryPenaltyLastN!;
    }

    if (samplers != null) {
      lcppParams.samplers = ffi.calloc<Uint8>(samplers!.length);

      samplers!.asMap().forEach((idx, str) {
        lcppParams.samplers[idx] = samplers![idx].toUnsigned(8);
      });
      lcppParams.n_samplers = samplers!.length;
    }

    if (modelPath != null) {
      lcppParams.model_path = modelPath!.toNativeUtf8().cast<Char>();
      lcppParams.n_model_path_length = modelPath!.length;
      final String modelFile =
          p.basenameWithoutExtension(modelPath!).toLowerCase();
      if (modelFile.startsWith(RegExp(r'phi', caseSensitive: false)) ||
          modelFile.startsWith(RegExp(r'microsoft', caseSensitive: false))) {
        lcppParams.model_familyAsInt =
            lcpp_model_family.LCPP_MODEL_FAMILY_PHI.value;
        lcppParams.is_reasoning =
            modelFile.contains(RegExp(r'reasoning', caseSensitive: false));
      } else if (modelFile.startsWith(RegExp(r'qwen', caseSensitive: false)) ||
          modelFile.startsWith(RegExp(r'qwq', caseSensitive: false))) {
        lcppParams.model_familyAsInt =
            lcpp_model_family.LCPP_MODEL_FAMILY_QWEN.value;
        lcppParams.is_reasoning =
            modelFile.startsWith(RegExp(r'qwen3', caseSensitive: false)) ||
                modelFile.startsWith(RegExp(r'qwq', caseSensitive: false));
      } else if (modelFile.startsWith(RegExp(r'llama', caseSensitive: false))) {
        lcppParams.model_familyAsInt =
            lcpp_model_family.LCPP_MODEL_FAMILY_LLAMA.value;
        lcppParams.is_reasoning = false;
      } else if (modelFile.startsWith(RegExp(r'gemma', caseSensitive: false))) {
        lcppParams.model_familyAsInt =
            lcpp_model_family.LCPP_MODEL_FAMILY_GEMMA.value;
        lcppParams.is_reasoning = false;
      } else if (modelFile
          .startsWith(RegExp(r'deepseek', caseSensitive: false))) {
        lcppParams.model_familyAsInt =
            lcpp_model_family.LCPP_MODEL_FAMILY_DEEPSEEK.value;
        lcppParams.is_reasoning =
            modelFile.startsWith(RegExp(r'deepseek-r', caseSensitive: false));
      } else if (modelFile
          .startsWith(RegExp(r'granite', caseSensitive: false))) {
        lcppParams.model_familyAsInt =
            lcpp_model_family.LCPP_MODEL_FAMILY_GRANITE.value;
        lcppParams.is_reasoning = false;
      } else if (modelFile
          .startsWith(RegExp(r'mistral', caseSensitive: false))) {
        lcppParams.model_familyAsInt =
            lcpp_model_family.LCPP_MODEL_FAMILY_MISTRAL.value;
        lcppParams.is_reasoning = false;
      } else {
        lcppParams.model_familyAsInt = modelFamily != null
            ? modelFamily!.value
            : lcpp_model_family.LCPP_MODEL_FAMILY_UNKNOWN.value;
        lcppParams.is_reasoning = false;
      }
    }

    if (vocabOnly != null) {
      lcppParams.vocab_only = vocabOnly!;
    }

    if (useMmap != null) {
      lcppParams.use_mmap = useMmap!;
    }

    if (useMlock != null) {
      lcppParams.use_mlock = useMlock!;
    }

    if (splitMode != null) {
      lcppParams.split_modeAsInt = splitMode!.value;
    }

    if (checkTensors != null) {
      lcppParams.check_tensors = checkTensors!;
    }

    if (escape != null) {
      lcppParams.escape = escape!;
    }

    if (multilineInput != null) {
      lcppParams.multiline_input = multilineInput!;
    }

    if (isReasoning != null) {
      lcppParams.is_reasoning = isReasoning!;
    }

    if (nGpuLayers != null) {
      lcppParams.n_gpu_layers = nGpuLayers!;
    }

    if (mainGPU != null) {
      lcppParams.main_gpu = mainGPU!;
    }

    return lcppParams;
  }

  /// Converts this instance to a [Map].
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    if (ignoreEOS != null) {
      result.addAll({'ignoreEOS': ignoreEOS});
    }
    if (noPerf != null) {
      result.addAll({'noPerf': noPerf});
    }
    if (timingPerToken != null) {
      result.addAll({'timingPerToken': timingPerToken});
    }
    if (nPrev != null) {
      result.addAll({'nPrev': nPrev});
    }
    if (nProbs != null) {
      result.addAll({'nProbs': nProbs});
    }
    if (seed != null) {
      result.addAll({'seed': seed});
    }
    if (topK != null) {
      result.addAll({'topK': topK});
    }
    if (topP != null) {
      result.addAll({'topP': topP});
    }
    if (minP != null) {
      result.addAll({'minP': minP});
    }
    if (typicalP != null) {
      result.addAll({'typicalP': typicalP});
    }
    if (topNsigma != null) {
      result.addAll({'topNsigma': topNsigma});
    }
    if (minKeep != null) {
      result.addAll({'minKeep': minKeep});
    }
    if (temperature != null) {
      result.addAll({'temperature': temperature});
    }
    if (dynaTempRange != null) {
      result.addAll({'dynaTempRange': dynaTempRange});
    }
    if (dynaTempExponent != null) {
      result.addAll({'dynaTempExponent': dynaTempExponent});
    }
    if (xtcProbability != null) {
      result.addAll({'xtcProbability': xtcProbability});
    }
    if (xtcThreshold != null) {
      result.addAll({'xtcThreshold': xtcThreshold});
    }
    if (mirostatTau != null) {
      result.addAll({'mirostatTau': mirostatTau});
    }
    if (mirostatEta != null) {
      result.addAll({'mirostatEta': mirostatEta});
    }
    if (mirostat != null) {
      result.addAll({'mirostat': mirostat!.value});
    }
    if (modelFamily != null) {
      result.addAll({'modelFamily': modelFamily!.value});
    }
    if (splitMode != null) {
      result.addAll({'splitMode': splitMode!.value});
    }
    if (grammar != null) {
      result.addAll({'grammar': grammar});
    }
    if (grammarLazy != null) {
      result.addAll({'grammarLazy': grammarLazy});
    }
    if (penaltyLastN != null) {
      result.addAll({'penaltyLastN': penaltyLastN});
    }
    if (penaltyRepeat != null) {
      result.addAll({'penaltyRepeat': penaltyRepeat});
    }
    if (penaltyFrequency != null) {
      result.addAll({'penaltyFrequency': penaltyFrequency});
    }
    if (penaltyPresent != null) {
      result.addAll({'penaltyPresent': penaltyPresent});
    }
    if (dryMultiplier != null) {
      result.addAll({'dryMultiplier': dryMultiplier});
    }
    if (dryBase != null) {
      result.addAll({'dryBase': dryBase});
    }
    if (dryAllowedLength != null) {
      result.addAll({'dryAllowedLength': dryAllowedLength});
    }
    if (dryPenaltyLastN != null) {
      result.addAll({'dryPenaltyLastN': dryPenaltyLastN});
    }
    if (samplers != null) {
      result.addAll({'samplers': samplers});
    }
    if (modelPath != null) {
      result.addAll({'modelPath': modelPath});
    }
    if (vocabOnly != null) {
      result.addAll({'vocabOnly': vocabOnly});
    }
    if (useMmap != null) {
      result.addAll({'useMmap': useMmap});
    }
    if (useMlock != null) {
      result.addAll({'useMlock': useMlock});
    }
    if (checkTensors != null) {
      result.addAll({'checkTensors': checkTensors});
    }
    if (escape != null) {
      result.addAll({'escape': escape});
    }
    if (multilineInput != null) {
      result.addAll({'multilineInput': multilineInput});
    }
    if (isReasoning != null) {
      result.addAll({'isReasoning': isReasoning});
    }
    if (nGpuLayers != null) {
      result.addAll({'nGpuLayers': nGpuLayers});
    }
    if (mainGPU != null) {
      result.addAll({'mainGPU': mainGPU});
    }

    return result;
  }

  /// Converts this instance to a JSON-encoded string.
  String toJson() => json.encode(toMap());

  LlamaCppParams copyWith({
    bool? ignoreEOS,
    bool? noPerf,
    bool? timingPerToken,
    int? nPrev,
    int? nProbs,
    int? seed,
    int? topK,
    double? topP,
    double? minP,
    double? typicalP,
    double? topNsigma,
    int? minKeep,
    double? temperature,
    double? dynaTempRange,
    double? dynaTempExponent,
    double? xtcProbability,
    double? xtcThreshold,
    double? mirostatTau,
    double? mirostatEta,
    lcpp_mirostat_type? mirostat,
    lcpp_model_family? modelFamily,
    lcpp_split_mode? splitMode,
    String? grammar,
    bool? grammarLazy,
    int? penaltyLastN,
    double? penaltyRepeat,
    double? penaltyFrequency,
    double? penaltyPresent,
    double? dryMultiplier,
    double? dryBase,
    int? dryAllowedLength,
    int? dryPenaltyLastN,
    List<int>? samplers,
    String? modelPath,
    bool? vocabOnly,
    bool? useMmap,
    bool? useMlock,
    bool? checkTensors,
    bool? escape,
    bool? multilineInput,
    bool? isReasoning,
    int? nGpuLayers,
    int? mainGPU,
  }) {
    return LlamaCppParams(
      ignoreEOS: ignoreEOS ?? this.ignoreEOS,
      noPerf: noPerf ?? this.noPerf,
      timingPerToken: timingPerToken ?? this.timingPerToken,
      nPrev: nPrev ?? this.nPrev,
      nProbs: nProbs ?? this.nProbs,
      seed: seed ?? this.seed,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      minP: minP ?? this.minP,
      typicalP: typicalP ?? this.typicalP,
      topNsigma: topNsigma ?? this.topNsigma,
      minKeep: minKeep ?? this.minKeep,
      temperature: temperature ?? this.temperature,
      dynaTempRange: dynaTempRange ?? this.dynaTempRange,
      dynaTempExponent: dynaTempExponent ?? this.dynaTempExponent,
      xtcProbability: xtcProbability ?? this.xtcProbability,
      xtcThreshold: xtcThreshold ?? this.xtcThreshold,
      mirostatTau: mirostatTau ?? this.mirostatTau,
      mirostatEta: mirostatEta ?? this.mirostatEta,
      mirostat: mirostat ?? this.mirostat,
      modelFamily: modelFamily ?? this.modelFamily,
      splitMode: splitMode ?? this.splitMode,
      grammar: grammar ?? this.grammar,
      grammarLazy: grammarLazy ?? this.grammarLazy,
      penaltyLastN: penaltyLastN ?? this.penaltyLastN,
      penaltyRepeat: penaltyRepeat ?? this.penaltyRepeat,
      penaltyFrequency: penaltyFrequency ?? this.penaltyFrequency,
      penaltyPresent: penaltyPresent ?? this.penaltyPresent,
      dryMultiplier: dryMultiplier ?? this.dryMultiplier,
      dryBase: dryBase ?? this.dryBase,
      dryAllowedLength: dryAllowedLength ?? this.dryAllowedLength,
      dryPenaltyLastN: dryPenaltyLastN ?? this.dryPenaltyLastN,
      samplers: samplers ?? this.samplers,
      modelPath: modelPath ?? this.modelPath,
      vocabOnly: vocabOnly ?? this.vocabOnly,
      useMmap: useMmap ?? this.useMmap,
      useMlock: useMlock ?? this.useMlock,
      checkTensors: checkTensors ?? this.checkTensors,
      escape: escape ?? this.escape,
      multilineInput: multilineInput ?? this.multilineInput,
      isReasoning: isReasoning ?? this.isReasoning,
      nGpuLayers: nGpuLayers ?? this.nGpuLayers,
      mainGPU: mainGPU ?? this.mainGPU,
    );
  }

  @override
  String toString() {
    return 'LlamaCppParams(ignoreEOS: $ignoreEOS, noPerf: $noPerf, timingPerToken: $timingPerToken, nPrev: $nPrev, nProbs: $nProbs, seed: $seed, topK: $topK, topP: $topP, minP: $minP, typicalP: $typicalP, topNsigma: $topNsigma, minKeep: $minKeep, temperature: $temperature, dynaTempRange: $dynaTempRange, dynaTempExponent: $dynaTempExponent, xtcProbability: $xtcProbability, xtcThreshold: $xtcThreshold, mirostatTau: $mirostatTau, mirostatEta: $mirostatEta, mirostat: $mirostat, modelFamily: $modelFamily, splitMode: $splitMode, grammar: $grammar, grammarLazy: $grammarLazy, penaltyLastN: $penaltyLastN, penaltyRepeat: $penaltyRepeat, penaltyFrequency: $penaltyFrequency, penaltyPresent: $penaltyPresent, dryMultiplier: $dryMultiplier, dryBase: $dryBase, dryAllowedLength: $dryAllowedLength, dryPenaltyLastN: $dryPenaltyLastN, samplers: $samplers, modelPath: $modelPath, vocabOnly: $vocabOnly, useMmap: $useMmap, useMlock: $useMlock, checkTensors: $checkTensors, escape: $escape, multilineInput: $multilineInput, isReasoning: $isReasoning, nGpuLayers: $nGpuLayers, mainGPU: $mainGPU)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is LlamaCppParams &&
        other.ignoreEOS == ignoreEOS &&
        other.noPerf == noPerf &&
        other.timingPerToken == timingPerToken &&
        other.nPrev == nPrev &&
        other.nProbs == nProbs &&
        other.seed == seed &&
        other.topK == topK &&
        other.topP == topP &&
        other.minP == minP &&
        other.typicalP == typicalP &&
        other.topNsigma == topNsigma &&
        other.minKeep == minKeep &&
        other.temperature == temperature &&
        other.dynaTempRange == dynaTempRange &&
        other.dynaTempExponent == dynaTempExponent &&
        other.xtcProbability == xtcProbability &&
        other.xtcThreshold == xtcThreshold &&
        other.mirostatTau == mirostatTau &&
        other.mirostatEta == mirostatEta &&
        other.mirostat == mirostat &&
        other.modelFamily == modelFamily &&
        other.splitMode == splitMode &&
        other.grammar == grammar &&
        other.grammarLazy == grammarLazy &&
        other.penaltyLastN == penaltyLastN &&
        other.penaltyRepeat == penaltyRepeat &&
        other.penaltyFrequency == penaltyFrequency &&
        other.penaltyPresent == penaltyPresent &&
        other.dryMultiplier == dryMultiplier &&
        other.dryBase == dryBase &&
        other.dryAllowedLength == dryAllowedLength &&
        other.dryPenaltyLastN == dryPenaltyLastN &&
        listEquals(other.samplers, samplers) &&
        other.modelPath == modelPath &&
        other.vocabOnly == vocabOnly &&
        other.useMmap == useMmap &&
        other.useMlock == useMlock &&
        other.checkTensors == checkTensors &&
        other.escape == escape &&
        other.multilineInput == multilineInput &&
        other.isReasoning == isReasoning &&
        other.nGpuLayers == nGpuLayers &&
        other.mainGPU == mainGPU;
  }

  @override
  int get hashCode {
    return ignoreEOS.hashCode ^
        noPerf.hashCode ^
        timingPerToken.hashCode ^
        nPrev.hashCode ^
        nProbs.hashCode ^
        seed.hashCode ^
        topK.hashCode ^
        topP.hashCode ^
        minP.hashCode ^
        typicalP.hashCode ^
        topNsigma.hashCode ^
        minKeep.hashCode ^
        temperature.hashCode ^
        dynaTempRange.hashCode ^
        dynaTempExponent.hashCode ^
        xtcProbability.hashCode ^
        xtcThreshold.hashCode ^
        mirostatTau.hashCode ^
        mirostatEta.hashCode ^
        mirostat.hashCode ^
        modelFamily.hashCode ^
        splitMode.hashCode ^
        grammar.hashCode ^
        grammarLazy.hashCode ^
        penaltyLastN.hashCode ^
        penaltyRepeat.hashCode ^
        penaltyFrequency.hashCode ^
        penaltyPresent.hashCode ^
        dryMultiplier.hashCode ^
        dryBase.hashCode ^
        dryAllowedLength.hashCode ^
        dryPenaltyLastN.hashCode ^
        samplers.hashCode ^
        modelPath.hashCode ^
        vocabOnly.hashCode ^
        useMmap.hashCode ^
        useMlock.hashCode ^
        checkTensors.hashCode ^
        escape.hashCode ^
        multilineInput.hashCode ^
        isReasoning.hashCode ^
        nGpuLayers.hashCode ^
        mainGPU.hashCode;
  }
}
