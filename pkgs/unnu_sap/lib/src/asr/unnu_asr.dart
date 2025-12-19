part of '../../unnu_asr.dart';

/// A longer lived native function, which occupies the thread calling it.
///
/// Do not call these kind of native functions in the main isolate. They will
/// block Dart execution. This will cause dropped frames in Flutter applications.
/// Instead, call these native functions on a separate isolate.
///
/// Modify this to suit your own use case. Example use cases:
///
/// 1. Reuse a single isolate for various different kinds of requests.
/// 2. Use multiple helper isolates for parallel execution.
const String _libName = 'unnu_asr';

/// The dynamic library in which the symbols for [UnnuAsrBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();



class UnnuAsr {
  static DynamicLibrary? _lib;

  // static final UnnuAsrBindings unnuasr = UnnuAsrBindings(_lib ??= _dylib);

  static void init() {
    _lib ??= _dylib;
  }

  static DynamicLibrary get lib {
    init();
    return _lib!;
  }

  UnnuAsr._();

  static final UnnuAsr _singleton = UnnuAsr._();

  static UnnuAsr get instance => _singleton;

  static NativeCallable<VoiceActivityDetectedCallbackFunction>?
      _nativeNowListeningCallable;

  /// Controller to listen to silence changed event.
  static final StreamController<bool> _nowListeningEventController =
      StreamController.broadcast(
    onListen: () {
      if (_nativeNowListeningCallable == null) {
        _set_listening_callbacks();
      }
    },
    onCancel: () {
      if (_nativeNowListeningCallable != null) {
        _nativeNowListeningCallable!.close();
        unnu_asr_unset_listening_callback();
        _nativeNowListeningCallable = null;
      }
    },
  );

  /// Stream of silence state changes.
  Stream<bool> get nowListening => _nowListeningEventController.stream;

  static NativeCallable<SoundEventCallbackFunction>? _nativeSoundDetectCallable;

  /// Controller to listen to silence changed event.
  static final StreamController<double> _soundEventController =
      StreamController.broadcast(
    onListen: () {
      if (_nativeSoundDetectCallable == null) {
        _set_sound_detected_callback();
      }
    },
    onCancel: () {
      if (_nativeSoundDetectCallable != null) {
        _nativeSoundDetectCallable!.close();
        unnu_asr_unset_sound_callback();
        _nativeSoundDetectCallable = null;
      }
    },
  );

  /// Stream of silence state changes.
  Stream<double> get soundEvents => _soundEventController.stream;

  static NativeCallable<TranscriptCallbackFunction>? _nativeTextDataCallable;
  static final _transcriptEventController =
      StreamController<Transcript>.broadcast(
    onListen: () {
      if (_nativeTextDataCallable == null) {
        _set_transcript_callbacks();
      }
    },
    onCancel: () {
      if (_nativeTextDataCallable != null) {
        _nativeTextDataCallable!.close();
        unnu_asr_unset_transcript_callback();
        _nativeTextDataCallable = null;
      }
    },
  );

  Stream<Transcript> get transcription => _transcriptEventController.stream;

  static Future<void> configure(OnlineRecognizerConfig config, VadModelConfig vadConfig,
      OnlinePunctuationConfig punctConfig) async {
    init();

    return await Isolate.run(()=>_configure(config, vadConfig, punctConfig));
  }

  static void _configure(OnlineRecognizerConfig config, VadModelConfig vadConfig,
        OnlinePunctuationConfig punctConfig) {

    // Recognizer
    final _recognizer = ffi.calloc<SherpaOnnxOnlineRecognizerConfig>();
    _recognizer.ref.feat_config.sample_rate = config.feat.sampleRate;
    _recognizer.ref.feat_config.feature_dim = config.feat.featureDim;

    // transducer
    _recognizer.ref.model_config.transducer.encoder =
        config.model.transducer.encoder.toNativeUtf8().cast<Char>();
    _recognizer.ref.model_config.transducer.decoder =
        config.model.transducer.decoder.toNativeUtf8().cast<Char>();
    _recognizer.ref.model_config.transducer.joiner =
        config.model.transducer.joiner.toNativeUtf8().cast<Char>();

    // paraformer
    _recognizer.ref.model_config.paraformer.encoder =
        config.model.paraformer.encoder.toNativeUtf8().cast<Char>();
    _recognizer.ref.model_config.paraformer.decoder =
        config.model.paraformer.decoder.toNativeUtf8().cast<Char>();

    // zipformer2Ctc
    _recognizer.ref.model_config.zipformer2_ctc.model =
        config.model.zipformer2Ctc.model.toNativeUtf8().cast<Char>();

    // OnlineModelConfig
    _recognizer.ref.model_config.tokens =
        config.model.tokens.toNativeUtf8().cast<Char>();
    _recognizer.ref.model_config.num_threads = config.model.numThreads;
    _recognizer.ref.model_config.provider =
        config.model.provider.toNativeUtf8().cast<Char>();
    _recognizer.ref.model_config.debug = config.model.debug ? 1 : 0;
    _recognizer.ref.model_config.model_type =
        config.model.modelType.toNativeUtf8().cast<Char>();
    _recognizer.ref.model_config.modeling_unit =
        config.model.modelingUnit.toNativeUtf8().cast<Char>();
    _recognizer.ref.model_config.bpe_vocab =
        config.model.bpeVocab.toNativeUtf8().cast<Char>();

    _recognizer.ref.decoding_method =
        config.decodingMethod.toNativeUtf8().cast<Char>();
    _recognizer.ref.max_active_paths = config.maxActivePaths;
    _recognizer.ref.enable_endpoint = config.enableEndpoint ? 1 : 0;
    _recognizer.ref.rule1_min_trailing_silence = config.rule1MinTrailingSilence;
    _recognizer.ref.rule2_min_trailing_silence = config.rule2MinTrailingSilence;
    _recognizer.ref.rule3_min_utterance_length = config.rule3MinUtteranceLength;
    _recognizer.ref.hotwords_file =
        config.hotwordsFile.toNativeUtf8().cast<Char>();
    _recognizer.ref.hotwords_score = config.hotwordsScore;

    // OnlineCtcFstDecoderConfig
    _recognizer.ref.ctc_fst_decoder_config.graph =
        config.ctcFstDecoderConfig.graph.toNativeUtf8().cast<Char>();
    _recognizer.ref.ctc_fst_decoder_config.max_active =
        config.ctcFstDecoderConfig.maxActive;

    _recognizer.ref.rule_fsts = config.ruleFsts.toNativeUtf8().cast<Char>();
    _recognizer.ref.rule_fars = config.ruleFars.toNativeUtf8().cast<Char>();
    _recognizer.ref.blank_penalty = config.blankPenalty;

    // HomophoneReplacerConfig
    _recognizer.ref.hr.dict_dir = config.hr.dictDir.toNativeUtf8().cast<Char>();
    _recognizer.ref.hr.lexicon = config.hr.lexicon.toNativeUtf8().cast<Char>();
    _recognizer.ref.hr.rule_fsts =
        config.hr.ruleFsts.toNativeUtf8().cast<Char>();

    // VAD
    final _vad = ffi.calloc<SherpaOnnxVadModelConfig>();

    final modelPtr = vadConfig.sileroVad.model.toNativeUtf8();
    _vad.ref.silero_vad.model = modelPtr.cast<Char>();

    _vad.ref.silero_vad.threshold = vadConfig.sileroVad.threshold;
    _vad.ref.silero_vad.min_silence_duration =
        vadConfig.sileroVad.minSilenceDuration;
    _vad.ref.silero_vad.min_speech_duration =
        vadConfig.sileroVad.minSpeechDuration;
    _vad.ref.silero_vad.window_size = vadConfig.sileroVad.windowSize;
    _vad.ref.silero_vad.max_speech_duration =
        vadConfig.sileroVad.maxSpeechDuration;

    _vad.ref.sample_rate = vadConfig.sampleRate;
    _vad.ref.num_threads = vadConfig.numThreads;


    final vadProviderPtr = vadConfig.provider.toNativeUtf8();
    _vad.ref.provider = vadProviderPtr.cast<Char>();
    _vad.ref.debug = vadConfig.debug ? 1 : 0;

    // Punctuation
    final _punct = ffi.calloc<SherpaOnnxOnlinePunctuationConfig>();
    final cnnBiLstmPtr = punctConfig.model.cnnBiLstm.toNativeUtf8();
    final bpeVocabPtr = punctConfig.model.bpeVocab.toNativeUtf8();
    final punctProviderPtr = punctConfig.model.provider.toNativeUtf8();
    _punct.ref.model.cnn_bilstm = cnnBiLstmPtr.cast<Char>();
    _punct.ref.model.bpe_vocab = bpeVocabPtr.cast<Char>();
    _punct.ref.model.num_threads = punctConfig.model.numThreads;
    _punct.ref.model.provider = punctProviderPtr.cast<Char>();
    _punct.ref.model.debug = punctConfig.model.debug ? 1 : 0;

    unnu_asr_init(_recognizer.ref, _vad.ref, _punct.ref);

    // Free the allocated strings and struct memory
    ffi.calloc.free(vadProviderPtr);
    ffi.calloc.free(modelPtr);
    ffi.calloc.free(_vad);

    ffi.calloc.free(punctProviderPtr);
    ffi.calloc.free(cnnBiLstmPtr);
    ffi.calloc.free(bpeVocabPtr);
    ffi.calloc.free(_punct);

    ffi.calloc.free(_recognizer.ref.hr.rule_fsts);
    ffi.calloc.free(_recognizer.ref.hr.lexicon);
    ffi.calloc.free(_recognizer.ref.hr.dict_dir);
    ffi.calloc.free(_recognizer.ref.rule_fars);
    ffi.calloc.free(_recognizer.ref.rule_fsts);
    ffi.calloc.free(_recognizer.ref.ctc_fst_decoder_config.graph);
    ffi.calloc.free(_recognizer.ref.hotwords_file);
    ffi.calloc.free(_recognizer.ref.decoding_method);
    ffi.calloc.free(_recognizer.ref.model_config.bpe_vocab);
    ffi.calloc.free(_recognizer.ref.model_config.modeling_unit);
    ffi.calloc.free(_recognizer.ref.model_config.model_type);
    ffi.calloc.free(_recognizer.ref.model_config.provider);
    ffi.calloc.free(_recognizer.ref.model_config.tokens);
    ffi.calloc.free(_recognizer.ref.model_config.zipformer2_ctc.model);
    ffi.calloc.free(_recognizer.ref.model_config.paraformer.encoder);
    ffi.calloc.free(_recognizer.ref.model_config.paraformer.decoder);

    ffi.calloc.free(_recognizer.ref.model_config.transducer.encoder);
    ffi.calloc.free(_recognizer.ref.model_config.transducer.decoder);
    ffi.calloc.free(_recognizer.ref.model_config.transducer.joiner);
    ffi.calloc.free(_recognizer);
  }

  static void _listeningCallback(Pointer<UnnuASRBoolStruct_t> isListening) {
    try {
      _nowListeningEventController.add(isListening.ref.value);
    } on Error catch  (e, s) {
        debugPrintStack(stackTrace: s);
    } finally {
      unnu_asr_free_bool(isListening);
    }
  }

  static void _set_listening_callbacks() {
    if (_nativeNowListeningCallable == null) {
      _nativeNowListeningCallable =
          NativeCallable<VoiceActivityDetectedCallbackFunction>.listener(
              _listeningCallback);

      _nativeNowListeningCallable!.keepIsolateAlive = false;

      unnu_asr_set_listening_callback(
          _nativeNowListeningCallable!.nativeFunction);
    }
  }

  static void _transcriptCallback(
      int type, Pointer<UnnuASRTextStruct_t> transcript) {
    // Create a copy of the data
    try {
      final result = transcript.ref.text
          .cast<ffi.Utf8>()
          .toDartString(length: transcript.ref.length);

      _transcriptEventController
          .add((type: TranscriptType.fromValue(type), text: result));

    } on Error catch (e, s) {
        debugPrintStack(stackTrace: s);
    } finally {
      unnu_asr_free_transcript(transcript);
    }
  }

  static void _set_transcript_callbacks() {
    if (_nativeTextDataCallable == null) {
      _nativeTextDataCallable =
          NativeCallable<TranscriptCallbackFunction>.listener(
        _transcriptCallback,
      );

      _nativeTextDataCallable!.keepIsolateAlive = false;

      unnu_asr_set_transcript_callback(_nativeTextDataCallable!.nativeFunction);
    }
  }

  static void _soundDetectedCallback(Pointer<UnnuASRFloatStruct_t> sound) {
    try {
      _soundEventController.add(sound.ref.value);
    } on Error catch (e, s) {
        debugPrintStack(stackTrace: s);
    } finally {
      unnu_asr_free_float(sound);
    }
  }

  static void _set_sound_detected_callback() {
    if (_nativeSoundDetectCallable == null) {
      _nativeSoundDetectCallable =
          NativeCallable<SoundEventCallbackFunction>.listener(
        _soundDetectedCallback,
      );

      _nativeSoundDetectCallable!.keepIsolateAlive = false;

      unnu_asr_set_sound_callback(_nativeSoundDetectCallable!.nativeFunction);
    }
  }

  bool get enabled => unnu_asr_is_enabled();

  void set enabled(bool value) {
    unnu_asr_enable(value);
  }

  void set punctuated(bool value){
    unnu_asr_punctuate(value);
  }

  bool get punctuated => unnu_asr_is_punctuated();

  bool get muted => unnu_asr_is_muted();

  void set muted(bool value) {
    unnu_asr_mute(value);
  }

  bool get supported => unnu_asr_is_supported();

  bool get streaming => unnu_asr_is_streaming();

  static void destroy() {
    if (_nativeSoundDetectCallable != null) {
      _nativeSoundDetectCallable!.close();
      _nativeSoundDetectCallable = null;
    }
    if (_nativeTextDataCallable != null) {
      _nativeTextDataCallable!.close();
      _nativeTextDataCallable = null;
    }
    unnu_asr_destroy();
  }

  static void nudge(int ms) => unnu_asr_nudge(ms);
}
