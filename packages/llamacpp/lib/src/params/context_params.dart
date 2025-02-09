// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: constant_identifier_names
part of 'package:llamacpp/llamacpp.dart';

/// A class representing the parameters for context configuration.
class ContextParams with ChangeNotifier {
  int _nCtx;

  /// text context, 0 = from model
  int get nCtx => _nCtx;

  set nCtx(int value) {
    _nCtx = value;
    notifyListeners();
  }

  int? _nBatch;

  /// logical maximum batch size that can be submitted to llama_decode
  int? get nBatch => _nBatch;

  set nBatch(int? value) {
    _nBatch = value;
    notifyListeners();
  }

  int? _nUBatch;

  /// physical maximum batch size
  int? get nUBatch => _nUBatch;

  set nUBatch(int? value) {
    _nUBatch = value;
    notifyListeners();
  }

  int? _nSeqMax;

  /// max number of sequences (i.e. distinct states for recurrent models)
  int? get nSeqMax => _nSeqMax;

  set nSeqMax(int? value) {
    _nSeqMax = value;
    notifyListeners();
  }

  int? _nThreads;

  /// number of threads to use for generation
  int? get nThreads => _nThreads;

  set nThreads(int? value) {
    _nThreads = value;
    notifyListeners();
  }

  int? _nThreadsBatch;

  /// number of threads to use for batch processing
  int? get nThreadsBatch => _nThreadsBatch;

  set nThreadsBatch(int? value) {
    _nThreadsBatch = value;
    notifyListeners();
  }

  RopeScalingType? _ropeScalingType;

  /// RoPE scaling type, from `enum llama_rope_scaling_type`
  RopeScalingType? get ropeScalingType => _ropeScalingType;

  set ropeScalingType(RopeScalingType? value) {
    _ropeScalingType = value;
    notifyListeners();
  }

  PoolingType? _poolingType;

  /// whether to pool (sum) embedding results by sequence id
  PoolingType? get poolingType => _poolingType;

  set poolingType(PoolingType? value) {
    _poolingType = value;
    notifyListeners();
  }

  AttentionType? _attentionType;

  /// attention type to use for embeddings
  AttentionType? get attentionType => _attentionType;

  set attentionType(AttentionType? value) {
    _attentionType = value;
    notifyListeners();
  }

  double? _ropeFrequencyBase;

  /// RoPE base frequency, 0 = from model
  double? get ropeFrequencyBase => _ropeFrequencyBase;

  set ropeFrequencyBase(double? value) {
    _ropeFrequencyBase = value;
    notifyListeners();
  }

  double? _ropeFrequencyScale;

  /// RoPE frequency scaling factor, 0 = from model
  double? get ropeFrequencyScale => _ropeFrequencyScale;

  set ropeFrequencyScale(double? value) {
    _ropeFrequencyScale = value;
    notifyListeners();
  }

  double? _yarnExtrapolationFactor;

  /// YaRN extrapolation mix factor, negative = from model
  double? get yarnExtrapolationFactor => _yarnExtrapolationFactor;

  set yarnExtrapolationFactor(double? value) {
    _yarnExtrapolationFactor = value;
    notifyListeners();
  }

  double? _yarnAttenuationFactor;

  /// YaRN magnitude scaling factor
  double? get yarnAttenuationFactor => _yarnAttenuationFactor;

  set yarnAttenuationFactor(double? value) {
    _yarnAttenuationFactor = value;
    notifyListeners();
  }

  double? _yarnBetaFast;

  /// YaRN low correction dim
  double? get yarnBetaFast => _yarnBetaFast;

  set yarnBetaFast(double? value) {
    _yarnBetaFast = value;
    notifyListeners();
  }

  double? _yarnBetaSlow;

  /// YaRN high correction dim
  double? get yarnBetaSlow => _yarnBetaSlow;

  set yarnBetaSlow(double? value) {
    _yarnBetaSlow = value;
    notifyListeners();
  }

  int? _yarnOriginalContext;

  /// YaRN original context size
  int? get yarnOriginalContext => _yarnOriginalContext;

  set yarnOriginalContext(int? value) {
    _yarnOriginalContext = value;
    notifyListeners();
  }

  double? _defragmentationThreshold;

  /// defragment the KV cache if holes/size > thold, < 0 disabled (default)
  double? get defragmentationThreshold => _defragmentationThreshold;

  set defragmentationThreshold(double? value) {
    _defragmentationThreshold = value;
    notifyListeners();
  }

  GgmlType? _typeK;

  /// data type for K cache
  GgmlType? get typeK => _typeK;

  set typeK(GgmlType? value) {
    _typeK = value;
    notifyListeners();
  }

  GgmlType? _typeV;

  /// data type for V cache
  GgmlType? get typeV => _typeV;

  set typeV(GgmlType? value) {
    _typeV = value;
    notifyListeners();
  }

  bool? _embeddings;

  /// if true, extract embeddings (together with logits)
  bool? get embeddings => _embeddings;

  set embeddings(bool? value) {
    _embeddings = value;
    notifyListeners();
  }

  bool? _offloadKqv;

  /// whether to offload the KQV ops (including the KV cache) to GPU
  bool? get offloadKqv => _offloadKqv;

  set offloadKqv(bool? value) {
    _offloadKqv = value;
    notifyListeners();
  }

  // bool? _flashAttention;

  /// whether to use flash attention
  // bool? get flashAttention => _flashAttention;
  //
  // set flashAttention(bool? value) {
  //   _flashAttention = value;
  //   notifyListeners();
  // }

  bool? _noPerformance;

  /// whether to measure performance timings
  bool? get noPerformance => _noPerformance;

  set noPerformance(bool? value) {
    _noPerformance = value;
    notifyListeners();
  }

  /// A class representing the parameters for context configuration.
  ///
  /// The parameters include various settings for context size, batch size,
  /// threading, scaling, pooling, attention, and other advanced configurations.
  ///
  /// - `nCtx`: The context size.
  /// - `nBatch`: The batch size.
  /// - `nUBatch`: The unrolled batch size.
  /// - `nSeqMax`: The maximum sequence length.
  /// - `nThreads`: The number of threads.
  /// - `nThreadsBatch`: The number of threads for batch processing.
  /// - `ropeScalingType`: The type of scaling for ROPE (Rotary Position Embedding).
  /// - `poolingType`: The type of pooling to be used.
  /// - `attentionType`: The type of attention mechanism to be used.
  /// - `ropeFrequencyBase`: The base frequency for ROPE.
  /// - `ropeFrequencyScale`: The scaling factor for ROPE frequency.
  /// - `yarnExtrapolationFactor`: The extrapolation factor for YARN.
  /// - `yarnAttenuationFactor`: The attenuation factor for YARN.
  /// - `yarnBetaFast`: The fast beta parameter for YARN.
  /// - `yarnBetaSlow`: The slow beta parameter for YARN.
  /// - `yarnOriginalContext`: The original context for YARN.
  /// - `defragmentationThreshold`: The threshold for defragmentation.
  /// - `typeK`: The type of key embeddings.
  /// - `typeV`: The type of value embeddings.
  /// - `embeddings`: The embeddings to be used.
  /// - `offloadKqv`: Whether to offload KQV (Key, Query, Value) computations.
  /// - `flashAttention`: Whether to use flash attention.
  /// - `noPerformance`: Whether to disable performance optimizations.
  ContextParams({
    int nCtx = 0,
    int? nBatch,
    int? nUBatch,
    int? nSeqMax,
    int? nThreads,
    int? nThreadsBatch,
    RopeScalingType? ropeScalingType,
    PoolingType? poolingType,
    AttentionType? attentionType,
    double? ropeFrequencyBase,
    double? ropeFrequencyScale,
    double? yarnExtrapolationFactor,
    double? yarnAttenuationFactor,
    double? yarnBetaFast,
    double? yarnBetaSlow,
    int? yarnOriginalContext,
    double? defragmentationThreshold,
    GgmlType? typeK,
    GgmlType? typeV,
    bool? embeddings,
    bool? offloadKqv,
    // bool? flashAttention,
    bool? noPerformance,
  }) : _nCtx = nCtx,
       _nBatch = nBatch,
       _nUBatch = nUBatch,
       _nSeqMax = nSeqMax,
       _nThreads = nThreads,
       _nThreadsBatch = nThreadsBatch,
       _ropeScalingType = ropeScalingType,
       _poolingType = poolingType,
       _attentionType = attentionType,
       _ropeFrequencyBase = ropeFrequencyBase,
       _ropeFrequencyScale = ropeFrequencyScale,
       _yarnExtrapolationFactor = yarnExtrapolationFactor,
       _yarnAttenuationFactor = yarnAttenuationFactor,
       _yarnBetaFast = yarnBetaFast,
       _yarnBetaSlow = yarnBetaSlow,
       _yarnOriginalContext = yarnOriginalContext,
       _defragmentationThreshold = defragmentationThreshold,
       _typeK = typeK,
       _typeV = typeV,
       _embeddings = embeddings,
       _offloadKqv = offloadKqv,
       // _flashAttention = flashAttention,
       _noPerformance = noPerformance;

  /// Creates a new instance of [ContextParams] from a map.
  ///
  /// The [map] parameter should contain the following keys:
  /// - `n_ctx`: The context size.
  /// - `n_batch`: The batch size.
  /// - `n_ubatch`: The unrolled batch size.
  /// - `n_seq_max`: The maximum sequence length.
  /// - `n_threads`: The number of threads.
  /// - `n_threads_batch`: The number of threads for batch processing.
  /// - `rope_scaling_type`: The type of scaling for ROPE (Rotary Position Embedding).
  /// - `pooling_type`: The type of pooling to be used.
  /// - `attention_type`: The type of attention mechanism to be used.
  /// - `rope_frequency_base`: The base frequency for ROPE.
  /// - `rope_frequency_scale`: The scaling factor for ROPE frequency.
  /// - `yarn_ext_factor`: The extrapolation factor for YARN.
  /// - `yarn_attn_factor`: The attenuation factor for YARN.
  /// - `yarn_beta_fast`: The fast beta parameter for YARN.
  /// - `yarn_beta_slow`: The slow beta parameter for YARN.
  /// - `yarn_orig_ctx`: The original context for YARN.
  /// - `defrag_thold`: The threshold for defragmentation.
  /// - `type_k`: The type of key embeddings.
  /// - `type_v`: The type of value embeddings.
  /// - `embeddings`: The embeddings to be used.
  /// - `offload_kqv`: Whether to offload KQV (Key, Query, Value) computations.
  /// - `flash_attn`: Whether to use flash attention.
  /// - `no_perf`: Whether to disable performance optimizations.
  factory ContextParams.fromMap(Map<String, dynamic> map) {
    return ContextParams(
      nCtx: map['nCtx'] as int,
      nBatch: map['nBatch'] != null ? map['nBatch'] as int : null,
      nUBatch: map['nUBatch'] != null ? map['nUBatch'] as int : null,
      nSeqMax: map['nSeqMax'] != null ? map['nSeqMax'] as int : null,
      nThreads: map['nThreads'] != null ? map['nThreads'] as int : null,
      nThreadsBatch:
          map['nThreadsBatch'] != null ? map['nThreadsBatch'] as int : null,
      ropeScalingType:
          map['ropeScalingType'] != null
              ? RopeScalingType.fromString(map['ropeScalingType'] as String)
              : null,
      poolingType:
          map['poolingType'] != null
              ? PoolingType.fromString(map['poolingType'] as String)
              : null,
      attentionType:
          map['attentionType'] != null
              ? AttentionType.fromString(map['attentionType'] as String)
              : null,
      ropeFrequencyBase:
          map['ropeFrequencyBase'] != null
              ? map['ropeFrequencyBase'] as double
              : null,
      ropeFrequencyScale:
          map['ropeFrequencyScale'] != null
              ? map['ropeFrequencyScale'] as double
              : null,
      yarnExtrapolationFactor:
          map['yarnExtrapolationFactor'] != null
              ? map['yarnExtrapolationFactor'] as double
              : null,
      yarnAttenuationFactor:
          map['yarnAttenuationFactor'] != null
              ? map['yarnAttenuationFactor'] as double
              : null,
      yarnBetaFast:
          map['yarnBetaFast'] != null ? map['yarnBetaFast'] as double : null,
      yarnBetaSlow:
          map['yarnBetaSlow'] != null ? map['yarnBetaSlow'] as double : null,
      yarnOriginalContext:
          map['yarnOriginalContext'] != null
              ? map['yarnOriginalContext'] as int
              : null,
      defragmentationThreshold:
          map['_defragmentationThreshold'] != null
              ? map['defragmentationThreshold'] as double
              : null,
      typeK:
          map['typeK'] != null
              ? GgmlType.fromString(map['typeK'] as String)
              : null,
      typeV:
          map['typeV'] != null
              ? GgmlType.fromString(map['typeV'] as String)
              : null,
      embeddings: map['embeddings'] != null ? map['embeddings'] as bool : null,
      offloadKqv: map['offloadKqv'] != null ? map['offloadKqv'] as bool : null,
      // flashAttention: map['flashAttention'] != null ? map['flashAttention'] as bool : null,
      noPerformance:
          map['noPerformance'] != null ? map['noPerformance'] as bool : null,
    );
  }

  /// Creates an instance of [ContextParams] from a JSON string.
  ///
  /// The [source] parameter is a JSON-encoded string representation of the
  /// context parameters.
  ///
  /// Returns an instance of [ContextParams] created from the decoded JSON map.
  factory ContextParams.fromJson(String source) =>
      ContextParams.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Creates a [ContextParams] instance from a native [llama_context_params] object.
  ///
  /// The [params] parameter is a native structure containing various context parameters.
  ///
  /// The following fields are mapped from the native structure:
  /// - [nCtx]: Number of contexts.
  /// - [nBatch]: Number of batches.
  /// - [nUBatch]: Number of micro-batches.
  /// - [nSeqMax]: Maximum sequence length.
  /// - [nThreads]: Number of threads.
  /// - [nThreadsBatch]: Number of threads per batch.
  /// - [ropeScalingType]: Type of rope scaling, if applicable.
  /// - [poolingType]: Type of pooling, if applicable.
  /// - [attentionType]: Type of attention, if applicable.
  /// - [ropeFrequencyBase]: Base frequency for rope.
  /// - [ropeFrequencyScale]: Scaling factor for rope frequency.
  /// - [yarnExtrapolationFactor]: Extrapolation factor for yarn.
  /// - [yarnAttenuationFactor]: Attenuation factor for yarn.
  /// - [yarnBetaFast]: Beta fast parameter for yarn.
  /// - [yarnBetaSlow]: Beta slow parameter for yarn.
  /// - [yarnOriginalContext]: Original context for yarn.
  /// - [defragmentationThreshold]: Threshold for defragmentation.
  /// - [typeK]: Type K, if applicable.
  /// - [typeV]: Type V, if applicable.
  /// - [embeddings]: Embeddings.
  /// - [offloadKqv]: Offload KQV flag.
  // /// - [flashAttention]: Flash attention flag.
  /// - [noPerformance]: No performance flag.
  factory ContextParams.fromNative(llama_context_params params) {
    return ContextParams(
      nCtx: params.n_ctx,
      nBatch: params.n_batch,
      nUBatch: params.n_ubatch,
      nSeqMax: params.n_seq_max,
      nThreads: params.n_threads,
      nThreadsBatch: params.n_threads_batch,
      ropeScalingType:
          params.rope_scaling_typeAsInt != -1
              ? RopeScalingType.values[params.rope_scaling_typeAsInt + 1]
              : null,
      poolingType:
          params.pooling_typeAsInt != -1
              ? PoolingType.values[params.pooling_typeAsInt + 1]
              : null,
      attentionType:
          params.attention_typeAsInt != -1
              ? AttentionType.values[params.attention_typeAsInt + 1]
              : null,
      ropeFrequencyBase: params.rope_freq_base,
      ropeFrequencyScale: params.rope_freq_scale,
      yarnExtrapolationFactor: params.yarn_ext_factor,
      yarnAttenuationFactor: params.yarn_attn_factor,
      yarnBetaFast: params.yarn_beta_fast,
      yarnBetaSlow: params.yarn_beta_slow,
      yarnOriginalContext: params.yarn_orig_ctx,
      defragmentationThreshold: params.defrag_thold,
      typeK:
          params.type_kAsInt != -1
              ? GgmlType.fromValue(params.type_kAsInt)
              : null,
      typeV:
          params.type_vAsInt != -1
              ? GgmlType.fromValue(params.type_vAsInt)
              : null,
      embeddings: params.embeddings,
      offloadKqv: params.offload_kqv,
      // flashAttention: params.flash_attn,
      noPerformance: params.no_perf,
    );
  }

  /// Factory constructor that creates an instance of [ContextParams] with default parameters.
  ///
  /// This constructor uses the `llama_context_default_params` function from the
  /// Llama library to obtain the default context parameters and then converts
  /// them to a [ContextParams] instance using the [ContextParams.fromNative] method.
  factory ContextParams.defaultParams() {
    final contextParams = llama_context_default_params();

    return ContextParams.fromNative(contextParams);
  }

  /// Converts the current instance to a native `llama_context_params` object.
  ///
  /// This method initializes a `llama_context_params` object with default values
  /// and then updates its fields based on the current instance's properties if they are not null.
  ///
  /// The following fields are set if they are not null:
  /// - `nCtx`: Sets the `n_ctx` field.
  /// - `nBatch`: Sets the `n_batch` field.
  /// - `nUBatch`: Sets the `n_ubatch` field.
  /// - `nSeqMax`: Sets the `n_seq_max` field.
  /// - `nThreads`: Sets the `n_threads` field.
  /// - `nThreadsBatch`: Sets the `n_threads_batch` field.
  /// - `ropeScalingType`: Sets the `rope_scaling_typeAsInt` field (enum index - 1).
  /// - `poolingType`: Sets the `pooling_typeAsInt` field (enum index - 1).
  /// - `attentionType`: Sets the `attention_typeAsInt` field (enum index - 1).
  /// - `ropeFrequencyBase`: Sets the `rope_freq_base` field.
  /// - `ropeFrequencyScale`: Sets the `rope_freq_scale` field.
  /// - `yarnExtrapolationFactor`: Sets the `yarn_ext_factor` field.
  /// - `yarnAttenuationFactor`: Sets the `yarn_attn_factor` field.
  /// - `yarnBetaFast`: Sets the `yarn_beta_fast` field.
  /// - `yarnBetaSlow`: Sets the `yarn_beta_slow` field.
  /// - `yarnOriginalContext`: Sets the `yarn_orig_ctx` field.
  /// - `defragmentationThreshold`: Sets the `defrag_thold` field.
  /// - `typeK`: Sets the `type_kAsInt` field (enum index * 1).
  /// - `typeV`: Sets the `type_vAsInt` field (enum index * 1).
  /// - `embeddings`: Sets the `embeddings` field.
  /// - `offloadKqv`: Sets the `offload_kqv` field.
  /// - `flashAttention`: Sets the `flash_attn` field.
  /// - `noPerformance`: Sets the `no_perf` field.
  ///
  /// Returns:
  /// - A `llama_context_params` object with the updated fields.
  llama_context_params toNative() {
    final llama_context_params contextParams = llama_context_default_params();

    contextParams.n_ctx = nCtx;

    if (nBatch != null) {
      contextParams.n_batch = nBatch!;
    }

    if (nUBatch != null) {
      contextParams.n_ubatch = nUBatch!;
    }

    if (nSeqMax != null) {
      contextParams.n_seq_max = nSeqMax!;
    }

    if (nThreads != null) {
      contextParams.n_threads = nThreads!;
    }

    if (nThreadsBatch != null) {
      contextParams.n_threads_batch = nThreadsBatch!;
    }

    if (ropeScalingType != null) {
      // This enum starts at -1, so we need to subtract 1 from the index
      contextParams.rope_scaling_typeAsInt = ropeScalingType!.index - 1;
    }

    if (poolingType != null) {
      // This enum starts at -1, so we need to subtract 1 from the index
      contextParams.pooling_typeAsInt = poolingType!.index - 1;
    }

    if (attentionType != null) {
      // This enum starts at -1, so we need to subtract 1 from the index
      contextParams.attention_typeAsInt = attentionType!.index - 1;
    }

    if (ropeFrequencyBase != null) {
      contextParams.rope_freq_base = ropeFrequencyBase!;
    }

    if (ropeFrequencyScale != null) {
      contextParams.rope_freq_scale = ropeFrequencyScale!;
    }

    if (yarnExtrapolationFactor != null) {
      contextParams.yarn_ext_factor = yarnExtrapolationFactor!;
    }

    if (yarnAttenuationFactor != null) {
      contextParams.yarn_attn_factor = yarnAttenuationFactor!;
    }

    if (yarnBetaFast != null) {
      contextParams.yarn_beta_fast = yarnBetaFast!;
    }

    if (yarnBetaSlow != null) {
      contextParams.yarn_beta_slow = yarnBetaSlow!;
    }

    if (yarnOriginalContext != null) {
      contextParams.yarn_orig_ctx = yarnOriginalContext!;
    }

    if (defragmentationThreshold != null) {
      contextParams.defrag_thold = defragmentationThreshold!;
    }

    if (typeK != null) {
      // It may seem redundant to multiply by 1, but it's necessary to convert to a C int
      contextParams.type_kAsInt = typeK!.value;
    }

    if (typeV != null) {
      // It may seem redundant to multiply by 1, but it's necessary to convert to a C int
      contextParams.type_vAsInt = typeV!.value;
    }

    if (embeddings != null) {
      contextParams.embeddings = embeddings!;
    }

    if (offloadKqv != null) {
      contextParams.offload_kqv = offloadKqv!;
    }

    // if (flashAttention != null) {
    //   contextParams.flash_attn = flashAttention!;
    // }

    if (noPerformance != null) {
      contextParams.no_perf = noPerformance!;
    }

    return contextParams;
  }

  /// Converts the context parameters to a map.
  ///
  /// The map contains the following key-value pairs:
  /// - `n_ctx`: The context size.
  /// - `n_batch`: The batch size.
  /// - `n_ubatch`: The unrolled batch size.
  /// - `n_seq_max`: The maximum sequence length.
  /// - `n_threads`: The number of threads.
  /// - `n_threads_batch`: The number of threads for batch processing.
  /// - `rope_scaling_type`: The type of scaling for ROPE (Rotary Position Embedding).
  /// - `pooling_type`: The type of pooling to be used.
  /// - `attention_type`: The type of attention mechanism to be used.
  /// - `rope_frequency_base`: The base frequency for ROPE.
  /// - `rope_frequency_scale`: The scaling factor for ROPE frequency.
  /// - `yarn_ext_factor`: The extrapolation factor for YARN.
  /// - `yarn_attn_factor`: The attenuation factor for YARN.
  /// - `yarn_beta_fast`: The fast beta parameter for YARN.
  /// - `yarn_beta_slow`: The slow beta parameter for YARN.
  /// - `yarn_orig_ctx`: The original context for YARN.
  /// - `defrag_thold`: The threshold for defragmentation.
  /// - `type_k`: The type of key embeddings.
  /// - `type_v`: The type of value embeddings.
  /// - `embeddings`: The embeddings to be used.
  /// - `offload_kqv`: Whether to offload KQV (Key, Query, Value) computations.
  /// - `flash_attn`: Whether to use flash attention.
  /// - `no_perf`: Whether to disable performance optimizations.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nCtx': _nCtx,
      'nBatch': _nBatch,
      'nUBatch': _nUBatch,
      'nSeqMax': _nSeqMax,
      'nThreads': _nThreads,
      'nThreadsBatch': _nThreadsBatch,
      'ropeScalingType': _ropeScalingType?.name,
      'poolingType': _poolingType?.name,
      'attentionType': _attentionType?.name,
      'ropeFrequencyBase': _ropeFrequencyBase,
      'ropeFrequencyScale': _ropeFrequencyScale,
      'yarnExtrapolationFactor': _yarnExtrapolationFactor,
      'yarnAttenuationFactor': _yarnAttenuationFactor,
      'yarnBetaFast': _yarnBetaFast,
      'yarnBetaSlow': _yarnBetaSlow,
      'yarnOriginalContext': _yarnOriginalContext,
      'defragmentationThreshold': _defragmentationThreshold,
      'typeK': _typeK?.name,
      'typeV': _typeV?.name,
      'embeddings': _embeddings,
      'offloadKqv': _offloadKqv,
      // 'flashAttention': _flashAttention,
      'noPerformance': _noPerformance,
    };
  }

  /// Converts the current object to a JSON string representation.
  ///
  /// This method uses the `toMap` method to first convert the object to a
  /// map, and then encodes the map to a JSON string using `jsonEncode`.
  ///
  /// Returns:
  ///   A JSON string representation of the current object.
  String toJson() => json.encode(toMap());

  ContextParams copyWith({
    int? nCtx,
    int? nBatch,
    int? nUBatch,
    int? nSeqMax,
    int? nThreads,
    int? nThreadsBatch,
    RopeScalingType? ropeScalingType,
    PoolingType? poolingType,
    AttentionType? attentionType,
    double? ropeFrequencyBase,
    double? ropeFrequencyScale,
    double? yarnExtrapolationFactor,
    double? yarnAttenuationFactor,
    double? yarnBetaFast,
    double? yarnBetaSlow,
    int? yarnOriginalContext,
    double? defragmentationThreshold,
    GgmlType? typeK,
    GgmlType? typeV,
    bool? embeddings,
    bool? offloadKqv,
    bool? flashAttention,
    bool? noPerformance,
  }) {
    return ContextParams(
      nCtx: nCtx ?? this._nCtx,
      nBatch: nBatch ?? this._nBatch,
      nUBatch: nUBatch ?? this._nUBatch,
      nSeqMax: nSeqMax ?? this._nSeqMax,
      nThreads: nThreads ?? this._nThreads,
      nThreadsBatch: nThreadsBatch ?? this._nThreadsBatch,
      ropeScalingType: ropeScalingType ?? this._ropeScalingType,
      poolingType: poolingType ?? this._poolingType,
      attentionType: attentionType ?? this._attentionType,
      ropeFrequencyBase: ropeFrequencyBase ?? this._ropeFrequencyBase,
      ropeFrequencyScale: ropeFrequencyScale ?? this._ropeFrequencyScale,
      yarnExtrapolationFactor:
          yarnExtrapolationFactor ?? this._yarnExtrapolationFactor,
      yarnAttenuationFactor:
          yarnAttenuationFactor ?? this._yarnAttenuationFactor,
      yarnBetaFast: yarnBetaFast ?? this._yarnBetaFast,
      yarnBetaSlow: yarnBetaSlow ?? this._yarnBetaSlow,
      yarnOriginalContext: yarnOriginalContext ?? this._yarnOriginalContext,
      defragmentationThreshold:
          defragmentationThreshold ?? this._defragmentationThreshold,
      typeK: typeK ?? this._typeK,
      typeV: typeV ?? this._typeV,
      embeddings: embeddings ?? this._embeddings,
      offloadKqv: offloadKqv ?? this._offloadKqv,
      // flashAttention: flashAttention ?? this._flashAttention,
      noPerformance: noPerformance ?? this._noPerformance,
    );
  }

  @override
  String toString() {
    return '''
    ContextParams:
    \t_nCtx: $_nCtx
    \t_nBatch: $_nBatch
    \t_nUBatch: $_nUBatch
    \t_nSeqMax: $_nSeqMax
    \t_nThreads: $_nThreads
    \t_nThreadsBatch: $_nThreadsBatch
    \t_ropeScalingType: $_ropeScalingType
    \t_poolingType: $_poolingType
    \t_attentionType: $_attentionType
    \t_ropeFrequencyBase: $_ropeFrequencyBase
    \t_ropeFrequencyScale: $_ropeFrequencyScale
    \t_yarnExtrapolationFactor: $_yarnExtrapolationFactor
    \t_yarnAttenuationFactor: $_yarnAttenuationFactor
    \t_yarnBetaFast: $_yarnBetaFast
    \t_yarnBetaSlow: $_yarnBetaSlow
    \t_yarnOriginalContext: $_yarnOriginalContext
    \t_defragmentationThreshold: $_defragmentationThreshold
    \t_typeK: $_typeK
    \t_typeV: $_typeV
    \t_embeddings: $_embeddings
    \t_offloadKqv: $_offloadKqv
    \t_noPerformance: $_noPerformance
    ''';
  }

  @override
  bool operator ==(covariant ContextParams other) {
    if (identical(this, other)) return true;

    return other._nCtx == _nCtx &&
        other._nBatch == _nBatch &&
        other._nUBatch == _nUBatch &&
        other._nSeqMax == _nSeqMax &&
        other._nThreads == _nThreads &&
        other._nThreadsBatch == _nThreadsBatch &&
        other._ropeScalingType == _ropeScalingType &&
        other._poolingType == _poolingType &&
        other._attentionType == _attentionType &&
        other._ropeFrequencyBase == _ropeFrequencyBase &&
        other._ropeFrequencyScale == _ropeFrequencyScale &&
        other._yarnExtrapolationFactor == _yarnExtrapolationFactor &&
        other._yarnAttenuationFactor == _yarnAttenuationFactor &&
        other._yarnBetaFast == _yarnBetaFast &&
        other._yarnBetaSlow == _yarnBetaSlow &&
        other._yarnOriginalContext == _yarnOriginalContext &&
        other._defragmentationThreshold == _defragmentationThreshold &&
        other._typeK == _typeK &&
        other._typeV == _typeV &&
        other._embeddings == _embeddings &&
        other._offloadKqv == _offloadKqv &&
        // other._flashAttention == _flashAttention &&
        other._noPerformance == _noPerformance;
  }

  @override
  int get hashCode {
    return _nCtx.hashCode ^
        _nBatch.hashCode ^
        _nUBatch.hashCode ^
        _nSeqMax.hashCode ^
        _nThreads.hashCode ^
        _nThreadsBatch.hashCode ^
        _ropeScalingType.hashCode ^
        _poolingType.hashCode ^
        _attentionType.hashCode ^
        _ropeFrequencyBase.hashCode ^
        _ropeFrequencyScale.hashCode ^
        _yarnExtrapolationFactor.hashCode ^
        _yarnAttenuationFactor.hashCode ^
        _yarnBetaFast.hashCode ^
        _yarnBetaSlow.hashCode ^
        _yarnOriginalContext.hashCode ^
        _defragmentationThreshold.hashCode ^
        _typeK.hashCode ^
        _typeV.hashCode ^
        _embeddings.hashCode ^
        _offloadKqv.hashCode ^
        // _flashAttention.hashCode ^
        _noPerformance.hashCode;
  }
}

/// Enum representing different types of rope scaling.
///
/// The available types are:
/// - `unspecified`: Default value when the type is not specified.
/// - `none`: No scaling applied.
/// - `linear`: Linear scaling.
/// - `yarn`: Yarn scaling.
/// - `longrope`: Long rope scaling.
///
/// Provides a method to convert a string value to the corresponding
/// `RopeScalingType` enum value.
enum RopeScalingType {
  /// Default value when the type is not specified.
  unspecified,

  /// No scaling applied.
  none,

  /// Linear scaling.
  linear,

  /// Yarn scaling.
  yarn,

  /// Long rope scaling.
  longrope;

  /// Converts a string value to the corresponding `RopeScalingType` enum value.
  static RopeScalingType fromString(String value) {
    return switch (value) {
      'none' => RopeScalingType.none,
      'linear' => RopeScalingType.linear,
      'yarn' => RopeScalingType.yarn,
      'longrope' => RopeScalingType.longrope,
      _=> RopeScalingType.unspecified,
    };
  }
}

/// Enum representing different types of pooling operations.
///
/// The available pooling types are:
/// - `unspecified`: Default value when no pooling type is specified.
/// - `none`: No pooling operation.
/// - `mean`: Mean pooling operation.
/// - `cls`: CLS token pooling operation.
/// - `last`: Last token pooling operation.
/// - `rank`: Rank pooling operation.
///
/// The `fromString` method converts a string value to the corresponding
/// `PoolingType` enum value. If the string does not match any known pooling
/// type, it returns `PoolingType.unspecified`.
enum PoolingType {
  /// Default value when no pooling type is specified.
  unspecified,

  /// No pooling operation.
  none,

  /// Mean pooling operation.
  mean,

  /// CLS token pooling operation.
  cls,

  /// Last token pooling operation.
  last,

  /// Rank pooling operation.
  rank;

  /// Converts a string value to the corresponding `PoolingType` enum value.
  static PoolingType fromString(String value) {
    return switch (value) {
      'none' => PoolingType.none,
      'mean' => PoolingType.mean,
      'cls' => PoolingType.cls,
      'last' => PoolingType.last,
      'rank' => PoolingType.rank,
       _=> PoolingType.unspecified,
    };
  }
}

/// Enum representing different types of attention mechanisms.
///
/// - `unspecified`: Default value when the attention type is not specified.
/// - `causal`: Represents causal attention.
/// - `nonCausal`: Represents non-causal attention.
///
/// Provides a method to convert a string representation to an `AttentionType` enum value.
enum AttentionType {
  /// Default value when the attention type is not specified.
  unspecified,

  /// Causal attention.
  causal,

  /// Non-causal attention.
  nonCausal;

  /// Converts a string value to the corresponding `AttentionType` enum value.
  static AttentionType fromString(String value) {
    return switch (value) {
      'causal' => AttentionType.causal,
      'non-causal' => AttentionType.nonCausal,
       _=> AttentionType.unspecified,
    };
  }
}

/// Enum representing different GGML (General Graphical Modeling Language) types.
///
/// Each type corresponds to a specific data format or quantization level used in GGML.
///
/// The available types are:
/// - `f32`: 32-bit floating point
/// - `f16`: 16-bit floating point
/// - `q4_0`, `q4_1`, `q4_2`, `q4_3`: 4-bit quantization levels
/// - `q5_0`, `q5_1`: 5-bit quantization levels
/// - `q8_0`, `q8_1`: 8-bit quantization levels
/// - `q2_k`, `q3_k`, `q4_k`, `q5_k`, `q6_k`, `q8_k`: Various quantization levels with different bit depths
/// - `iq2_xxs`, `iq2_xs`, `iq3_xxs`, `iq1_s`, `iq4_nl`, `iq3_s`, `iq2_s`, `iq4_xs`: Integer quantization levels with different bit depths and suffixes
/// - `i8`, `i16`, `i32`, `i64`: Integer types with different bit depths
/// - `f64`: 64-bit floating point
/// - `iq1_m`: Integer quantization with a specific suffix
/// - `bf16`: Brain floating point 16-bit
/// - `q4_0_4_4`, `q4_0_4_8`, `q4_0_8_8`: Mixed quantization levels
/// - `tq1_0`, `tq2_0`: Tensor quantization levels
///
/// The `fromString` method allows converting a string representation of a GGML type to its corresponding enum value.
enum GgmlType {
  /// 32-bit floating point
  f32(0),

  /// 16-bit floating point
  f16(1),

  /// 4-bit quantization level 0
  q4_0(2),

  /// 4-bit quantization level 1
  q4_1(3),

  /// 4-bit quantization level 2
  q4_2(4),

  /// 4-bit quantization level 3
  q4_3(5),

  /// 5-bit quantization level 0
  q5_0(6),

  /// 5-bit quantization level 1
  q5_1(7),

  /// 8-bit quantization level 0
  q8_0(8),

  /// 8-bit quantization level 1
  q8_1(9),

  /// 2-bit quantization level for keys
  q2_k(10),

  /// 3-bit quantization level for keys
  q3_k(11),

  /// 4-bit quantization level for keys
  q4_k(12),

  /// 5-bit quantization level for keys
  q5_k(13),

  /// 6-bit quantization level for keys
  q6_k(14),

  /// 8-bit quantization level for keys
  q8_k(15),

  /// Integer quantization level 2 xxs
  iq2_xxs(16),

  /// Integer quantization level 2 xs
  iq2_xs(17),

  /// Integer quantization level 3 xxs
  iq3_xxs(18),

  /// Integer quantization level 1 s
  iq1_s(19),

  /// Integer quantization level 4 nl
  iq4_nl(20),

  /// Integer quantization level 3 s
  iq3_s(21),

  /// Integer quantization level 2 s
  iq2_s(22),

  /// Integer quantization level 4 xs
  iq4_xs(23),

  /// 8-bit integer
  i8(24),

  /// 16-bit integer
  i16(25),

  /// 32-bit integer
  i32(26),

  /// 64-bit integer
  i64(27),

  /// 64-bit floating point
  f64(28),

  /// Integer quantization level 1 m
  iq1_m(29),

  /// Brain floating point 16-bit
  bf16(30),

  /// Mixed quantization level 4-4
  q4_0_4_4(31),

  /// Mixed quantization level 4-8
  q4_0_4_8(32),

  /// Mixed quantization level 8-8
  q4_0_8_8(33),

  /// Tensor quantization level 1
  tq1_0(34),

  /// Tensor quantization level 2
  tq2_0(35),

  /// Mixed quantization level 4-4
  iq4_nl_4_4(36),

  /// Mixed quantization level 4-8
  iq4_nl_4_8(37),

  /// Mixed quantization level 8-8
  iq4_nl_8_8(38),

  /// Tensor quantization level 4
  mxfp4(39);

  final int value;
  const GgmlType(this.value);

  static GgmlType fromValue(int type) {
    return switch (type) {
      0 => GgmlType.f32,
      1 => GgmlType.f16,
      2 => GgmlType.q4_0,
      3 => GgmlType.q4_1,
      4 => GgmlType.q4_2,
      5 => GgmlType.q4_3,
      6 => GgmlType.q5_0,
      7 => GgmlType.q5_1,
      8 => GgmlType.q8_0,
      9 => GgmlType.q8_1,
      10 => GgmlType.q2_k,
      11 => GgmlType.q3_k,
      12 => GgmlType.q4_k,
      13 => GgmlType.q5_k,
      14 => GgmlType.q6_k,
      15 => GgmlType.q8_k,
      16 => GgmlType.iq2_xxs,
      17 => GgmlType.iq2_xs,
      18 => GgmlType.iq3_xxs,
      19 => GgmlType.iq1_s,
      20 => GgmlType.iq4_nl,
      21 => GgmlType.iq3_s,
      22 => GgmlType.iq2_s,
      23 => GgmlType.iq4_xs,
      24 => GgmlType.i8,
      25 => GgmlType.i16,
      26 => GgmlType.i32,
      27 => GgmlType.i64,
      28 => GgmlType.f64,
      29 => GgmlType.iq1_m,
      30 => GgmlType.bf16,
      31 => GgmlType.q4_0_4_4,
      32 => GgmlType.q4_0_4_8,
      33 => GgmlType.q4_0_8_8,
      34 => GgmlType.tq1_0,
      35 => GgmlType.tq2_0,
      36 => GgmlType.iq4_nl_4_4,
      37 => GgmlType.iq4_nl_4_8,
      38 => GgmlType.iq4_nl_8_8,
      39 => GgmlType.mxfp4,
      _ => GgmlType.f32,
    };
  }

  /// Converts a string value to the corresponding `GgmlType` enum value.
  static GgmlType fromString(String value) {
    return switch (value) {
      'f32' => GgmlType.f32,
      'f16' => GgmlType.f16,
      'q4_0' => GgmlType.q4_0,
      'q4_1' => GgmlType.q4_1,
      'q4_2' => GgmlType.q4_2,
      'q4_3' => GgmlType.q4_3,
      'q5_0' => GgmlType.q5_0,
      'q5_1' => GgmlType.q5_1,
      'q8_0' => GgmlType.q8_0,
      'q8_1' => GgmlType.q8_1,
      'q2_k' => GgmlType.q2_k,
      'q3_k' => GgmlType.q3_k,
      'q4_k' => GgmlType.q4_k,
      'q5_k' => GgmlType.q5_k,
      'q6_k' => GgmlType.q6_k,
      'q8_k' => GgmlType.q8_k,
      'iq2_xxs' => GgmlType.iq2_xxs,
      'iq2_xs' => GgmlType.iq2_xs,
      'iq3_xxs' => GgmlType.iq3_xxs,
      'iq1_s' => GgmlType.iq1_s,
      'iq4_nl' => GgmlType.iq4_nl,
      'iq3_s' => GgmlType.iq3_s,
      'iq2_s' => GgmlType.iq2_s,
      'iq4_xs' => GgmlType.iq4_xs,
      'i8' => GgmlType.i8,
      'i16' => GgmlType.i16,
      'i32' => GgmlType.i32,
      'i64' => GgmlType.i64,
      'f64' => GgmlType.f64,
      'iq1_m' => GgmlType.iq1_m,
      'bf16' => GgmlType.bf16,
      'q4_0_4_4' => GgmlType.q4_0_4_4,
      'q4_0_4_8' => GgmlType.q4_0_4_8,
      'q4_0_8_8' => GgmlType.q4_0_8_8,
      'tq1_0' => GgmlType.tq1_0,
      'tq2_0' => GgmlType.tq2_0,
      'iq4_nl_4_4' => GgmlType.iq4_nl_4_4,
      'iq4_nl_4_8' => GgmlType.iq4_nl_4_8,
      'iq4_nl_8_8' => GgmlType.iq4_nl_8_8,
      'mxfp4' => GgmlType.mxfp4,
       _=> GgmlType.f32,
    };
  }
}
