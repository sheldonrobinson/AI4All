// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'package:llamacpp/llamacpp.dart';

typedef ReasoningFamily = ({bool reasoning, int family});

class LlamaCppSamplingParams with ChangeNotifier {
  /// Do stop on eos
  bool? _ignoreEOS;

  bool? get ignoreEOS => _ignoreEOS;

  set ignoreEOS(bool? value) {
    _ignoreEOS = value;
    notifyListeners();
  }

  /// disable performance metrics
  bool? _noPerf;

  bool? get noPerf => _noPerf;

  set noPerf(bool? value) {
    _noPerf = value;
    notifyListeners();
  }

  /// Performance measurement per token
  bool? _timingPerToken;

  bool? get timingPerToken => _timingPerToken;

  set timingPerToken(bool? value) {
    _timingPerToken = value;
    notifyListeners();
  }

  /// Optional seed for random number generation to ensure reproducibility.
  int? _seed;

  int? get seed => _seed;

  set seed(int? value) {
    _seed = value;
    notifyListeners();
  }

  /// nNumber of previous tokens to remember
  int? _nPrev;

  int? get nPrev => _nPrev;

  set nPrev(int? value) {
    _nPrev = value;
    notifyListeners();
  }

  /// If greater than 0, output the probabilities of top n_probs tokens.
  int? _nProbs;

  int? get nProbs => _nProbs;

  set nProbs(int? value) {
    _nProbs = value;
    notifyListeners();
  }

  /// Limits the number of top candidates considered during sampling.
  int? _topK;

  int? get topK => _topK;

  set topK(int? value) {
    _topK = value;
    notifyListeners();
  }

  /// Arguments for top-p sampling (nucleus sampling).
  double? _topP;

  double? get topP => _topP;

  set topP(double? value) {
    _topP = value;
    notifyListeners();
  }

  /// Arguments for minimum-p sampling.
  double? _minP;

  double? get minP => _minP;

  set minP(double? value) {
    _minP = value;
    notifyListeners();
  }

  /// Arguments for typical-p sampling.
  double? _typicalP;

  double? get typicalP => _typicalP;

  set typicalP(double? value) {
    _typicalP = value;
    notifyListeners();
  }

  // Top N Sigmna
  double? _topNsigma;

  double? get topNsigma => _topNsigma;

  set topNsigma(double? value) {
    _topNsigma = value;
    notifyListeners();
  }

  /// The minimum number of items to keep in the sample.
  int? _minKeep;

  int? get minKeep => _minKeep;

  set minKeep(int? value) {
    _minKeep = value;
    notifyListeners();
  }

  /// The temperature value for sampling.
  double? _temperature;

  double? get temperature => _temperature;

  set temperature(double? value) {
    _temperature = value;
    notifyListeners();
  }

  /// Optional range parameter for temperature adjustment.
  double? _dynaTempRange;

  double? get dynaTempRange => _dynaTempRange;

  set dynaTempRange(double? value) {
    _dynaTempRange = value;
    notifyListeners();
  }

  /// Optional exponent parameter for temperature adjustment.
  double? _dynaTempExponent;

  double? get dynaTempExponent => _dynaTempExponent;

  set dynaTempExponent(double? value) {
    _dynaTempExponent = value;
    notifyListeners();
  }

  /// The probability threshold for XTC sampling.
  double? _xtcProbability;

  double? get xtcProbability => _xtcProbability;

  set xtcProbability(double? value) {
    _xtcProbability = value;
    notifyListeners();
  }

  /// The threshold value for XTC sampling.
  double? _xtcThreshold;

  double? get xtcThreshold => _xtcThreshold;

  set xtcThreshold(double? value) {
    _xtcThreshold = value;
    notifyListeners();
  }

  /// The tau value for Mirostat sampling.
  double? _mirostatTau;

  double? get mirostatTau => _mirostatTau;

  set mirostatTau(double? value) {
    _mirostatTau = value;
    notifyListeners();
  }

  /// The eta value for Mirostat sampling.
  double? _mirostatEta;

  double? get mirostatEta => _mirostatEta;

  set mirostatEta(double? value) {
    _mirostatEta = value;
    notifyListeners();
  }

  /// The number of items to keep in the sample.
  int? _mirostat;

  int? get mirostat => _mirostat;

  set mirostat(int? value) {
    _mirostat = value;
    notifyListeners();
  }

  /// Optional BNF-like grammar for constrained sampling.
  String? _grammar;

  String? get grammar => _grammar;

  set grammar(String? value) {
    _grammar = value;
    notifyListeners();
  }

  /// Optional BNF-like grammar lazy parsing.
  bool? _grammarLazy;

  bool? get grammarLazy => _grammarLazy;

  set grammarLazy(bool? value) {
    _grammarLazy = value;
    notifyListeners();
  }

  /// The number of items to consider for the penalty.
  int? _penaltyLastN;

  int? get penaltyLastN => _penaltyLastN;

  set penaltyLastN(int? value) {
    _penaltyLastN = value;
    notifyListeners();
  }

  /// The penalty for repetition.
  double? _penaltyRepeat;

  double? get penaltyRepeat => _penaltyRepeat;

  set penaltyRepeat(double? value) {
    _penaltyRepeat = value;
    notifyListeners();
  }

  /// The penalty frequency.
  double? _penaltyFrequency;

  double? get penaltyFrequency => _penaltyFrequency;

  set penaltyFrequency(double? value) {
    _penaltyFrequency = value;
    notifyListeners();
  }

  /// The penalty for present items.
  double? _penaltyPresent;

  double? get penaltyPresent => _penaltyPresent;

  set penaltyPresent(double? value) {
    _penaltyPresent = value;
    notifyListeners();
  }

  /// The multiplier for the penalty.
  double? _dryMultiplier;

  double? get dryMultiplier => _dryMultiplier;

  set dryMultiplier(double? value) {
    _dryMultiplier = value;
    notifyListeners();
  }

  /// The base value for the penalty.
  double? _dryBase;

  double? get dryBase => _dryBase;

  set dryBase(double? value) {
    _dryBase = value;
    notifyListeners();
  }

  /// The maximum allowed length for the sequence.
  int? _dryAllowedLength;

  int? get dryAllowedLength => _dryAllowedLength;

  set dryAllowedLength(int? value) {
    _dryAllowedLength = value;
    notifyListeners();
  }

  /// The penalty for the last N items.
  int? _dryPenaltyLastN;

  int? get dryPenaltyLastN => _dryPenaltyLastN;

  set dryPenaltyLastN(int? value) {
    _dryPenaltyLastN = value;
    notifyListeners();
  }

  /// samplers enabled
  List<int>? _samplers;
  LlamaCppSamplingParams({
    bool? ignoreEOS,
    bool? noPerf,
    bool? timingPerToken,
    int? seed,
    int? nPrev,
    int? nProbs,
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
    int? mirostat,
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
  }) : _ignoreEOS = ignoreEOS ?? false,
       _noPerf = noPerf ?? true,
       _timingPerToken = timingPerToken ?? false,
       _seed = seed ?? LLAMA_DEFAULT_SEED,
       _nPrev = nPrev ?? 64,
       _nProbs = nProbs ?? 0,
       _topK = topK ?? 40,
       _topP = topP ?? 0.95,
       _minP = minP ?? 0.05,
       _typicalP = typicalP ?? 1.0,
       _topNsigma = topNsigma ?? -1.0,
       _minKeep = minKeep ?? 0,
       _temperature = temperature ?? 0.8,
       _dynaTempRange = dynaTempRange ?? 0.0,
       _dynaTempExponent = dynaTempExponent ?? 1.0,
       _xtcProbability = xtcProbability ?? 0.0,
       _xtcThreshold = xtcThreshold ?? 0.10,
       _mirostatTau = mirostatTau ?? 5.0,
       _mirostatEta = mirostatEta ?? 0.10,
       _mirostat = mirostat ?? lcpp_mirostat_type.LCPP_MIROSTAT_NONE.value,
       _grammar = grammar,
       _grammarLazy = grammarLazy ?? false,
       _penaltyLastN = penaltyLastN ?? 64,
       _penaltyFrequency = penaltyFrequency ?? 0.0,
       _penaltyRepeat = penaltyRepeat ?? 1.0,
       _penaltyPresent = penaltyPresent ?? 0.0,
       _dryMultiplier = dryMultiplier ?? 0.0,
       _dryBase = dryBase ?? 1.75,
       _dryAllowedLength = dryAllowedLength ?? 2,
       _dryPenaltyLastN = dryPenaltyLastN ?? -1,
       _samplers = samplers ?? <int>[];

  List<int>? get samplers => _samplers;

  set samplers(List<int>? value) {
    if (value != null) {
      _samplers = _samplers ?? <int>[];
      _samplers!.addAll(value);
      notifyListeners();
    }
  }

  /// Factory constructor that creates an instance of [LlamaCppSamplingParams] with default parameters.
  ///
  /// This constructor uses the `llama_context_default_params` function from the
  /// Llama library to obtain the default context parameters and then converts
  /// them to a [LlamaCppSamplingParams] instance using the [LlamaCppSamplingParams.fromNative] method.
  factory LlamaCppSamplingParams.defaultParams() {
    final lcppParams = lcpp_sampling_params_defaults();
    return LlamaCppSamplingParams.fromNative(lcppParams);
  }

  /// Constructs a [LlamaCppSamplingParams] instance from a [Map].
  factory LlamaCppSamplingParams.fromMap(Map<String, dynamic> map) {
    return LlamaCppSamplingParams(
      ignoreEOS: (map['ignoreEOS'] ?? false) as bool,
      noPerf: (map['noPerf'] ?? true) as bool,
      timingPerToken: (map['timingPerToken'] ?? false) as bool,
      seed: (map['seed'] ?? LLAMA_DEFAULT_SEED)! as int,
      nPrev: (map['nPrev'] ?? 64) as int,
      nProbs: (map['nProbs'] ?? 0.0) as int,
      topK: (map['topK'] ?? 40) as int,
      topP: (map['topP'] ?? 0.95) as double,
      minP: (map['minP'] ?? 0.05) as double,
      typicalP: (map['typicalP'] ?? 1.0) as double,
      topNsigma: (map['topNsigma'] ?? -1.0) as double,
      minKeep: (map['minKeep'] ?? 0) as int,
      temperature: (map['temperature'] ?? 0.8) as double,
      dynaTempRange: (map['dynaTempRange'] ?? 0.0) as double,
      dynaTempExponent: (map['dynaTempExponent'] ?? 1.0) as double,
      xtcProbability: (map['xtcProbability'] ?? 0.0) as double,
      xtcThreshold: (map['xtcThreshold'] ?? 0.10) as double,
      mirostatTau: (map['mirostatTau'] ?? 5.0) as double,
      mirostatEta: (map['mirostatEta'] ?? 0.10) as double,
      mirostat:
          (map['mirostat'] ?? lcpp_mirostat_type.LCPP_MIROSTAT_NONE.value)
              as int,
      grammar: map['grammar'] != null ? map['grammar'] as String : null,
      grammarLazy: (map['grammarLazy'] ?? false) as bool,
      penaltyLastN: (map['penaltyLastN'] ?? 64) as int,
      penaltyRepeat: (map['penaltyRepeat'] ?? 1.0) as double,
      penaltyFrequency: (map['penaltyFrequency'] ?? 0.0) as double,
      penaltyPresent: (map['penaltyPresent'] ?? 0.0) as double,
      dryMultiplier: (map['dryMultiplier'] ?? 0.0) as double,
      dryBase: (map['dryBase'] ?? 1.75) as double,
      dryAllowedLength: (map['dryAllowedLength'] ?? 2) as int,
      dryPenaltyLastN: (map['dryPenaltyLastN'] ?? -1) as int,
      samplers:
          map['samplers'] != null ? map['samplers'] as List<int> : <int>[],
    );
  }

  factory LlamaCppSamplingParams.fromNative(lcpp_sampling_params params) {
    final defaultSamplers = <int>[];
    final nSamplers = params.n_samplers;
    for (int i = 0; i < nSamplers; i++) {
      defaultSamplers.add(params.samplers[i]);
    }
    return LlamaCppSamplingParams(
      dryAllowedLength: params.dry_allowed_length,
      dryBase: params.dry_base,
      dryMultiplier: params.dry_multiplier,
      dryPenaltyLastN: params.dry_penalty_last_n,
      dynaTempExponent: params.dynatemp_exponent,
      dynaTempRange: params.dynatemp_range,
      grammarLazy: params.grammar_lazy,
      ignoreEOS: params.ignore_eos,
      minKeep: params.min_keep,
      minP: params.min_p,
      mirostat: params.mirostat.value,
      mirostatEta: params.mirostat_eta,
      mirostatTau: params.mirostat_tau,
      noPerf: params.no_perf,
      nPrev: params.n_prev,
      nProbs: params.n_probs,
      penaltyFrequency: params.penalty_freq,
      penaltyLastN: params.penalty_last_n,
      penaltyPresent: params.penalty_present,
      penaltyRepeat: params.penalty_repeat,
      seed: params.seed,
      temperature: params.temp,
      timingPerToken: params.timing_per_token,
      topNsigma: params.top_n_sigma,
      topK: params.top_k,
      topP: params.top_p,
      typicalP: params.typ_p,
      xtcProbability: params.xtc_probability,
      xtcThreshold: params.xtc_threshold,
      samplers: defaultSamplers,
    );
  }

  /// Converts this instance to a [Pointer<llama_sampler>].
  lcpp_sampling_params toNative() {
    final lcpp_sampling_params lcppParams = lcpp_sampling_params_defaults();

    if (_ignoreEOS != null) {
      lcppParams.ignore_eos = _ignoreEOS!;
    }

    if (_noPerf != null) {
      lcppParams.no_perf = _noPerf!;
    }

    if (_timingPerToken != null) {
      lcppParams.timing_per_token = _timingPerToken!;
    }

    if (_nPrev != null) {
      lcppParams.n_prev = _nPrev!;
    }

    if (_nProbs != null) {
      lcppParams.n_probs = _nProbs!;
    }

    if (_seed != null) {
      lcppParams.seed = _seed!;
    }

    if (_topK != null) {
      lcppParams.top_k = _topK!;
    }

    if (_topP != null) {
      lcppParams.top_p = _topP!;
    }

    if (_minKeep != null) {
      lcppParams.min_keep = _minKeep!;
    }

    if (_minP != null) {
      lcppParams.min_p = _minP!;
    }

    if (_typicalP != null) {
      lcppParams.typ_p = _typicalP!;
    }

    if (_topNsigma != null) {
      lcppParams.top_n_sigma = _topNsigma!;
    }

    if (_temperature != null) {
      lcppParams.temp = _temperature!;
    }

    if (_dynaTempExponent != null) {
      lcppParams.dynatemp_exponent = _dynaTempExponent!;
    }

    if (_dynaTempRange != null) {
      lcppParams.dynatemp_range = _dynaTempRange!;
    }

    if (_xtcProbability != null) {
      lcppParams.xtc_probability = _xtcProbability!;
    }

    if (_xtcThreshold != null) {
      lcppParams.xtc_threshold = _xtcThreshold!;
    }

    if (_mirostat != null) {
      lcppParams.mirostatAsInt = _mirostat!;
    }

    if (_mirostatEta != null) {
      lcppParams.mirostat_eta = _mirostatEta!;
    }

    if (_mirostatTau != null) {
      lcppParams.mirostat_tau = _mirostatTau!;
    }

    if (_grammar != null) {
      lcppParams.grammar = _grammar!.toNativeUtf8().cast<Char>();
      lcppParams.n_grammar_length = _grammar!.length;
    }

    if (_grammarLazy != null) {
      lcppParams.grammar_lazy = _grammarLazy!;
    }

    if (_penaltyFrequency != null) {
      lcppParams.penalty_freq = _penaltyFrequency!;
    }

    if (_penaltyLastN != null) {
      lcppParams.penalty_last_n = _penaltyLastN!;
    }

    if (_penaltyRepeat != null) {
      lcppParams.penalty_repeat = _penaltyRepeat!;
    }

    if (_penaltyPresent != null) {
      lcppParams.penalty_present = _penaltyPresent!;
    }

    if (_dryAllowedLength != null) {
      lcppParams.dry_allowed_length = _dryAllowedLength!;
    }

    if (_dryBase != null) {
      lcppParams.dry_base = _dryBase!;
    }

    if (_dryMultiplier != null) {
      lcppParams.dry_multiplier = _dryMultiplier!;
    }

    if (_dryPenaltyLastN != null) {
      lcppParams.dry_penalty_last_n = _dryPenaltyLastN!;
    }

    if (_samplers != null) {
      lcppParams.samplers = ffi.calloc<Uint8>(_samplers!.length);

      _samplers!.asMap().forEach((idx, str) {
        lcppParams.samplers[idx] = _samplers![idx].toUnsigned(8);
      });
      lcppParams.n_samplers = _samplers!.length;
    }

    return lcppParams;
  }

  LlamaCppSamplingParams copyWith({
    bool? ignoreEOS,
    bool? noPerf,
    bool? timingPerToken,
    int? seed,
    int? nPrev,
    int? nProbs,
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
    int? mirostat,
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
  }) {
    return LlamaCppSamplingParams(
      ignoreEOS: ignoreEOS ?? this._ignoreEOS,
      noPerf: noPerf ?? this._noPerf,
      timingPerToken: timingPerToken ?? this._timingPerToken,
      seed: seed ?? this._seed,
      nPrev: nPrev ?? this._nPrev,
      nProbs: nProbs ?? this._nProbs,
      topK: topK ?? this._topK,
      topP: topP ?? this._topP,
      minP: minP ?? this._minP,
      typicalP: typicalP ?? this._typicalP,
      topNsigma: topNsigma ?? this._topNsigma,
      minKeep: minKeep ?? this._minKeep,
      temperature: temperature ?? this._temperature,
      dynaTempRange: dynaTempRange ?? this._dynaTempRange,
      dynaTempExponent: dynaTempExponent ?? this._dynaTempExponent,
      xtcProbability: xtcProbability ?? this._xtcProbability,
      xtcThreshold: xtcThreshold ?? this._xtcThreshold,
      mirostatTau: mirostatTau ?? this._mirostatTau,
      mirostatEta: mirostatEta ?? this._mirostatEta,
      mirostat: mirostat ?? this._mirostat,
      grammar: grammar ?? this._grammar,
      grammarLazy: grammarLazy ?? this._grammarLazy,
      penaltyLastN: penaltyLastN ?? this._penaltyLastN,
      penaltyRepeat: penaltyRepeat ?? this._penaltyRepeat,
      penaltyFrequency: penaltyFrequency ?? this._penaltyFrequency,
      penaltyPresent: penaltyPresent ?? this._penaltyPresent,
      dryMultiplier: dryMultiplier ?? this._dryMultiplier,
      dryBase: dryBase ?? this._dryBase,
      dryAllowedLength: dryAllowedLength ?? this._dryAllowedLength,
      dryPenaltyLastN: dryPenaltyLastN ?? this._dryPenaltyLastN,
      samplers: samplers ?? this._samplers,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ignoreEOS': _ignoreEOS,
      'noPerf': _noPerf,
      'timingPerToken': _timingPerToken,
      'seed': _seed,
      'nPrev': _nPrev,
      'nProbs': _nProbs,
      'topK': _topK,
      'topP': _topP,
      'minP': _minP,
      'typicalP': _typicalP,
      'topNsigma': _topNsigma,
      'minKeep': _minKeep,
      'temperature': _temperature,
      'dynaTempRange': _dynaTempRange,
      'dynaTempExponent': _dynaTempExponent,
      'xtcProbability': _xtcProbability,
      'xtcThreshold': _xtcThreshold,
      'mirostatTau': _mirostatTau,
      'mirostatEta': _mirostatEta,
      'mirostat': _mirostat,
      'grammar': _grammar,
      'grammarLazy': _grammarLazy,
      'penaltyLastN': _penaltyLastN,
      'penaltyRepeat': _penaltyRepeat,
      'penaltyFrequency': _penaltyFrequency,
      'penaltyPresent': _penaltyPresent,
      'dryMultiplier': _dryMultiplier,
      'dryBase': _dryBase,
      'dryAllowedLength': _dryAllowedLength,
      'dryPenaltyLastN': _dryPenaltyLastN,
      'samplers': _samplers,
    };
  }

  String toJson() => json.encode(toMap());

  factory LlamaCppSamplingParams.fromJson(String source) =>
      LlamaCppSamplingParams.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  @override
  String toString() {
    return 'LlamaCppSamplingParams(_ignoreEOS: $_ignoreEOS, _noPerf: $_noPerf, _timingPerToken: $_timingPerToken, _seed: $_seed, _nPrev: $_nPrev, _nProbs: $_nProbs, _topK: $_topK, _topP: $_topP, _minP: $_minP, _typicalP: $_typicalP, _topNsigma: $_topNsigma, _minKeep: $_minKeep, _temperature: $_temperature, _dynaTempRange: $_dynaTempRange, _dynaTempExponent: $_dynaTempExponent, _xtcProbability: $_xtcProbability, _xtcThreshold: $_xtcThreshold, _mirostatTau: $_mirostatTau, _mirostatEta: $_mirostatEta, _mirostat: $_mirostat, _grammar: $_grammar, _grammarLazy: $_grammarLazy, _penaltyLastN: $_penaltyLastN, _penaltyRepeat: $_penaltyRepeat, _penaltyFrequency: $_penaltyFrequency, _penaltyPresent: $_penaltyPresent, _dryMultiplier: $_dryMultiplier, _dryBase: $_dryBase, _dryAllowedLength: $_dryAllowedLength, _dryPenaltyLastN: $_dryPenaltyLastN, _samplers: $_samplers)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is LlamaCppSamplingParams &&
        other._ignoreEOS == _ignoreEOS &&
        other._noPerf == _noPerf &&
        other._timingPerToken == _timingPerToken &&
        other._seed == _seed &&
        other._nPrev == _nPrev &&
        other._nProbs == _nProbs &&
        other._topK == _topK &&
        other._topP == _topP &&
        other._minP == _minP &&
        other._typicalP == _typicalP &&
        other._topNsigma == _topNsigma &&
        other._minKeep == _minKeep &&
        other._temperature == _temperature &&
        other._dynaTempRange == _dynaTempRange &&
        other._dynaTempExponent == _dynaTempExponent &&
        other._xtcProbability == _xtcProbability &&
        other._xtcThreshold == _xtcThreshold &&
        other._mirostatTau == _mirostatTau &&
        other._mirostatEta == _mirostatEta &&
        other._mirostat == _mirostat &&
        other._grammar == _grammar &&
        other._grammarLazy == _grammarLazy &&
        other._penaltyLastN == _penaltyLastN &&
        other._penaltyRepeat == _penaltyRepeat &&
        other._penaltyFrequency == _penaltyFrequency &&
        other._penaltyPresent == _penaltyPresent &&
        other._dryMultiplier == _dryMultiplier &&
        other._dryBase == _dryBase &&
        other._dryAllowedLength == _dryAllowedLength &&
        other._dryPenaltyLastN == _dryPenaltyLastN &&
        listEquals(other._samplers, _samplers);
  }

  @override
  int get hashCode {
    return _ignoreEOS.hashCode ^
        _noPerf.hashCode ^
        _timingPerToken.hashCode ^
        _seed.hashCode ^
        _nPrev.hashCode ^
        _nProbs.hashCode ^
        _topK.hashCode ^
        _topP.hashCode ^
        _minP.hashCode ^
        _typicalP.hashCode ^
        _topNsigma.hashCode ^
        _minKeep.hashCode ^
        _temperature.hashCode ^
        _dynaTempRange.hashCode ^
        _dynaTempExponent.hashCode ^
        _xtcProbability.hashCode ^
        _xtcThreshold.hashCode ^
        _mirostatTau.hashCode ^
        _mirostatEta.hashCode ^
        _mirostat.hashCode ^
        _grammar.hashCode ^
        _grammarLazy.hashCode ^
        _penaltyLastN.hashCode ^
        _penaltyRepeat.hashCode ^
        _penaltyFrequency.hashCode ^
        _penaltyPresent.hashCode ^
        _dryMultiplier.hashCode ^
        _dryBase.hashCode ^
        _dryAllowedLength.hashCode ^
        _dryPenaltyLastN.hashCode ^
        _samplers.hashCode;
  }
}

/// Represents the parameters used for sampling in the model.
class LlamaCppParams {
  /// how to split the model across multiple GPUs
  final lcpp_split_mode? _splitMode;

  /// how to split the model across multiple CPUs
  final lcpp_numa_strategy? _numa;

  /// path to GGUF model file
  final String? _modelPath;

  /// Indicates whether only the vocabulary should be loaded.
  ///
  /// If `true`, only the vocabulary is loaded, which can be useful for
  /// certain operations where the full model is not required. If `false`
  /// or `null`, the full model is loaded.
  final bool? _vocabOnly;

  /// Indicates whether memory-mapped files should be used.
  ///
  /// If `true`, memory-mapped files will be used, which can improve performance
  /// by allowing the operating system to manage memory more efficiently.
  /// If `false` or `null`, memory-mapped files will not be used.
  final bool? _useMmap;

  /// Indicates whether memory locking (mlock) should be used.
  ///
  /// When `true`, the memory used by the application will be locked,
  /// preventing it from being swapped out to disk. This can improve
  /// performance by ensuring that the memory remains in RAM.
  ///
  /// When `false` or `null`, memory locking is not used.
  final bool? _useMlock;

  /// A flag indicating whether to check tensors.
  ///
  /// If `true`, tensors will be checked. If `false` or `null`, tensors will not be checked.
  final bool? _checkTensors;

  /// escape "\n", "\r", "\t", "\'", "\"", and "\\"
  final bool? _escape;

  /// reverse the usage of `\`
  final bool? _multilineInput;

  /// off load experts to main mem `\`
  final bool? _expertsOffLoad;

  /// Number of layers to store in VRAM
  ///
  /// If unset, will default to using CPU
  final int? _nGpuLayers;

  /// The GPU that is used for the entire model when split_mode is LLAMA_SPLIT_MODE_NONE
  ///
  /// If unset default to gpu 0
  final int? _mainGPU;

  /// Creates a new instance of [LlamaCppParams].
  const LlamaCppParams({
    lcpp_split_mode? splitMode,
    lcpp_numa_strategy? numa,
    String? modelPath,
    bool? vocabOnly,
    bool? useMmap,
    bool? useMlock,
    bool? checkTensors,
    bool? escape,
    bool? multilineInput,
    bool? expertsOffLoad,
    int? nGpuLayers,
    int? mainGPU,
  }) : _splitMode = splitMode,
       _numa = numa,
       _modelPath = modelPath,
       _vocabOnly = vocabOnly,
       _useMmap = useMmap,
       _useMlock = useMlock,
       _checkTensors = checkTensors,
       _escape = escape,
       _multilineInput = multilineInput,
       _expertsOffLoad = expertsOffLoad,
       _nGpuLayers = nGpuLayers,
       _mainGPU = mainGPU;

  /// Constructs a [LlamaCppParams] instance from a [Map].
  factory LlamaCppParams.fromMap(Map<String, dynamic> map) {
    return LlamaCppParams(
      splitMode:
          map['splitMode'] != null
              ? lcpp_split_mode.fromValue(map['splitMode'] as int)
              : null,
      numa:
          map['numa'] != null
              ? lcpp_numa_strategy.fromValue(map['numa'] as int)
              : null,
      modelPath: map['modelPath'] != null ? map['modelPath'] as String : null,
      vocabOnly: map['vocabOnly'] != null ? map['vocabOnly'] as bool : null,
      useMmap: map['useMmap'] != null ? map['useMmap'] as bool : null,
      useMlock: map['useMlock'] != null ? map['useMlock'] as bool : null,
      checkTensors:
          map['checkTensors'] != null ? map['checkTensors'] as bool : null,
      escape: map['escape'] != null ? map['escape'] as bool : null,
      multilineInput:
          map['multilineInput'] != null ? map['multilineInput'] as bool : null,
      expertsOffLoad:
          map['expertsOffLoad'] != null ? map['expertsOffLoad'] as bool : null,
      nGpuLayers: map['nGpuLayers'] != null ? map['nGpuLayers'] as int : null,
      mainGPU: map['mainGPU'] != null ? map['mainGPU'] as int : null,
    );
  }

  /// Constructs a [LlamaCppParams] instance from a JSON string.
  factory LlamaCppParams.fromJson(String source) =>
      LlamaCppParams.fromMap(json.decode(source) as Map<String, dynamic>);

  factory LlamaCppParams.fromNative(lcpp_params params) {
    return LlamaCppParams(
      nGpuLayers: params.n_gpu_layers,
      checkTensors: params.check_tensors,
      escape: params.escape,
      multilineInput: params.multiline_input,
      mainGPU: params.main_gpu,
      expertsOffLoad: params.offload_experts,
      splitMode: params.split_mode,
      numa: params.numa,
      useMlock: params.use_mlock,
      useMmap: params.use_mmap,
      vocabOnly: params.vocab_only,
    );
  }

  /// Factory constructor that creates an instance of [ContextParams] with default parameters.
  ///
  /// This constructor uses the `llama_context_default_params` function from the
  /// Llama library to obtain the default context parameters and then converts
  /// them to a [ContextParams] instance using the [ContextParams.fromNative] method.
  factory LlamaCppParams.defaultParams() {
    final lcppParams = lcpp_params_defaults();

    return LlamaCppParams.fromNative(lcppParams);
  }

  ReasoningFamily get reasoning => LlamaCppParams._isReasoning(_modelPath);

  static ReasoningFamily _isReasoning(String? modelPath) {
    if (modelPath != null) {
      final modelFile = p.basenameWithoutExtension(modelPath).toLowerCase();
      if (modelFile.startsWith(RegExp('phi|microsoft', caseSensitive: false))) {
        return (
          reasoning: modelFile.contains(
            RegExp('reasoning', caseSensitive: false),
          ),
          family: lcpp_model_family.LCPP_MODEL_FAMILY_PHI.value,
        );
      } else if (modelFile.startsWith(
        RegExp('llama', caseSensitive: false),
      )) {
        return (
          reasoning: modelFile.startsWith(
            RegExp('llama[3-9]', caseSensitive: false),
          ),
          family: lcpp_model_family.LCPP_MODEL_FAMILY_LLAMA.value,
        );
      } else if (modelFile.startsWith(
        RegExp('gemma|gpt', caseSensitive: false),
      )) {
        return (
          reasoning: modelFile.contains(
            RegExp('reasoning', caseSensitive: false),
          ),
          family:
              modelFile.startsWith(RegExp('gpt', caseSensitive: false))
                  ? lcpp_model_family.LCPP_MODEL_FAMILY_GPT_OSS.value
                  : lcpp_model_family.LCPP_MODEL_FAMILY_GEMMA.value,
        );
      } else if (modelFile.startsWith(
        RegExp('qwen|qwq', caseSensitive: false),
      )) {
        return (
          reasoning: modelFile.startsWith(
            RegExp('qwen[3-9]|qwq', caseSensitive: false),
          ),
          family: lcpp_model_family.LCPP_MODEL_FAMILY_QWEN.value,
        );
      } else if (modelFile.startsWith(
        RegExp('deepseek', caseSensitive: false),
      )) {
        return (
          reasoning: modelFile.startsWith(
            RegExp('deepseek-r|deepseek-v[3-9]\.', caseSensitive: false),
          ),
          family: lcpp_model_family.LCPP_MODEL_FAMILY_DEEPSEEK.value,
        );
      } else if (modelFile.startsWith(
        RegExp('seed|granite|ernie|apertus', caseSensitive: false),
      )) {
        return (
          reasoning: true,
          family:
              modelFile.startsWith(RegExp('seed', caseSensitive: false))
                  ? lcpp_model_family.LCPP_MODEL_FAMILY_SEED_OSS.value
                  : modelFile.startsWith(
                    RegExp('granite', caseSensitive: false),
                  )
                  ? lcpp_model_family.LCPP_MODEL_FAMILY_GRANITE.value
                  : modelFile.startsWith(
                    RegExp('apertus', caseSensitive: false),
                  )
                  ? lcpp_model_family.LCPP_MODEL_FAMILY_APERTUS.value
                  : lcpp_model_family.LCPP_MODEL_FAMILY_GENERIC.value,
        );
      } else if (modelFile.startsWith(
        RegExp('mistral|magistral', caseSensitive: false),
      )) {
        return (
          reasoning: modelFile.startsWith(
            RegExp('magistral', caseSensitive: false),
          ),
          family: lcpp_model_family.LCPP_MODEL_FAMILY_MISTRAL.value,
        );
      } else if (modelFile.contains(
        RegExp('nemotron', caseSensitive: false),
      )) {
        return (
          reasoning: true,
          family: lcpp_model_family.LCPP_MODEL_FAMILY_NEMOTRON.value,
        );
      } else if (modelFile.startsWith(
        RegExp('minimax', caseSensitive: false),
      )) {
        return (
          reasoning: true,
          family: lcpp_model_family.LCPP_MODEL_FAMILY_MINIMAX.value,
        );
      } else if (modelFile.startsWith(
        RegExp('glm', caseSensitive: false),
      )) {
        return (
          reasoning: true,
          family: lcpp_model_family.LCPP_MODEL_FAMILY_GLM.value,
        );
      } else if (modelFile.startsWith(
        RegExp('command-', caseSensitive: false),
      )) {
        return (
          reasoning: true,
          family: lcpp_model_family.LCPP_MODEL_FAMILY_COHERE.value,
        );
      } else if (modelFile.startsWith(
        RegExp('lfm2-', caseSensitive: false),
      )) {
        return (
          reasoning: false,
          family: lcpp_model_family.LCPP_MODEL_FAMILY_LIQUID.value,
        );
      }
      return (
        reasoning: false,
        family: lcpp_model_family.LCPP_MODEL_FAMILY_UNKNOWN.value,
      );
    }
    return (
      reasoning: false,
      family: lcpp_model_family.LCPP_MODEL_FAMILY_UNSPECIFIED.value,
    );
  }

  /// Converts this instance to a [Pointer<llama_sampler>].
  lcpp_params toNative() {
    final lcppParams = lcpp_params_defaults();
    if (_modelPath != null) {
      lcppParams
        ..model_path = _modelPath.toNativeUtf8().cast<Char>()
        ..n_model_path_length = _modelPath.length;
    }
    final family = reasoning;
    lcppParams
      ..is_reasoning = family.reasoning
      ..model_familyAsInt = family.family;

    if (_vocabOnly != null) {
      lcppParams.vocab_only = _vocabOnly;
    }

    if (_useMmap != null) {
      lcppParams.use_mmap = _useMmap;
    }

    if (_useMlock != null) {
      lcppParams.use_mlock = _useMlock;
    }

    if (_splitMode != null) {
      lcppParams.split_modeAsInt = _splitMode.value;
    }

    if (_numa != null) {
      lcppParams.numaAsInt = _numa.value;
    }

    if (_checkTensors != null) {
      lcppParams.check_tensors = _checkTensors;
    }

    if (_escape != null) {
      lcppParams.escape = _escape;
    }

    if (_multilineInput != null) {
      lcppParams.multiline_input = _multilineInput;
    }

    if (_expertsOffLoad != null) {
      lcppParams.offload_experts = _expertsOffLoad;
    }

    if (_nGpuLayers != null) {
      lcppParams.n_gpu_layers = _nGpuLayers;
    }

    if (_mainGPU != null) {
      lcppParams.main_gpu = _mainGPU;
    }

    return lcppParams;
  }

  /// Converts this instance to a [Map].
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'splitMode': _splitMode?.value,
      'numa': _numa?.value,
      'modelPath': _modelPath,
      'vocabOnly': _vocabOnly,
      'useMmap': _useMmap,
      'useMlock': _useMlock,
      'checkTensors': _checkTensors,
      'escape': _escape,
      'multilineInput': _multilineInput,
      'expertsOffLoad': _expertsOffLoad,
      'nGpuLayers': _nGpuLayers,
      'mainGPU': _mainGPU,
    };
  }

  /// Converts this instance to a JSON-encoded string.
  String toJson() => json.encode(toMap());

  LlamaCppParams copyWith({
    String? modelPath,
    lcpp_split_mode? splitMode,
    lcpp_numa_strategy? numa,
    bool? vocabOnly,
    bool? useMmap,
    bool? useMlock,
    bool? checkTensors,
    bool? escape,
    bool? multilineInput,
    bool? expertsOffLoad,
    int? nGpuLayers,
    int? mainGPU,
  }) {
    return LlamaCppParams(
      modelPath: modelPath ?? _modelPath,
      splitMode:
          splitMode ?? _splitMode ?? lcpp_split_mode.LCPP_SPLIT_MODE_NONE,
      numa: numa ?? _numa ?? lcpp_numa_strategy.LCPP_NUMA_STRATEGY_DISABLED,
      vocabOnly: vocabOnly ?? _vocabOnly,
      useMmap: useMmap ?? _useMmap,
      useMlock: useMlock ?? _useMlock,
      checkTensors: checkTensors ?? _checkTensors,
      escape: escape ?? _escape,
      multilineInput: multilineInput ?? _multilineInput,
      nGpuLayers: nGpuLayers ?? _nGpuLayers,
      mainGPU: mainGPU ?? _mainGPU,
      expertsOffLoad: _expertsOffLoad ?? _expertsOffLoad ?? false,
    );
  }

  @override
  String toString() {
    return '''
    LlamaCppParams:
    \tsplitMode: $_splitMode
    \tnuma: $_numa
    \tmodelPath: $_modelPath
    \tvocabOnly: $_vocabOnly
    \tuseMmap: $_useMmap
    \tuseMlock: $_useMlock
    \tcheckTensors: $_checkTensors
    \tescape: $_escape
    \tmultilineInput: $_multilineInput
    \t_expertsOffLoad: $_expertsOffLoad
    \tnGpuLayers: $_nGpuLayers
    \tmainGPU: $_mainGPU
    ''';
  }

  @override
  bool operator ==(covariant LlamaCppParams other) {
    if (identical(this, other)) return true;

    return other._splitMode == _splitMode &&
        other._numa == _numa &&
        other._modelPath == _modelPath &&
        other._vocabOnly == _vocabOnly &&
        other._useMmap == _useMmap &&
        other._useMlock == _useMlock &&
        other._checkTensors == _checkTensors &&
        other._escape == _escape &&
        other._multilineInput == _multilineInput &&
        other._nGpuLayers == _nGpuLayers &&
        other._expertsOffLoad == _expertsOffLoad &&
        other._mainGPU == _mainGPU;
  }

  @override
  int get hashCode {
    return _splitMode.hashCode ^
        _numa.hashCode ^
        _modelPath.hashCode ^
        _vocabOnly.hashCode ^
        _useMmap.hashCode ^
        _useMlock.hashCode ^
        _checkTensors.hashCode ^
        _escape.hashCode ^
        _multilineInput.hashCode ^
        _expertsOffLoad.hashCode ^
        _nGpuLayers.hashCode ^
        _mainGPU.hashCode;
  }
}
