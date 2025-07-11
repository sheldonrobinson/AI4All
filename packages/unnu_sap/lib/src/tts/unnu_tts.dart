part of '../../unnu_tts.dart';

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
const String _libName = 'unnu_tts';

/// The dynamic library in which the symbols for [UnnuCognitiveEnvironmentBindings] can be found.
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

class UnnuTts {
  static DynamicLibrary? _lib;

  /// Returns an instance of the `unnu_tts` library.
  ///
  /// This getter initializes the `_lib` field if it is `null` by loading the
  /// appropriate dynamic library based on the current platform:
  ///
  /// - On Windows, it loads `unnu_tts.dll`.
  /// - On Linux or Android, it loads `libunnu_tts.so`.
  /// - On macOS or iOS, it loads `unnu_tts.framework/unnu_tts`.
  ///
  /// Throws a [Exception] if the platform is unsupported.

 // static final UnnuTtsBindings unnutts = UnnuTtsBindings(_lib ??= _dylib);

  static void init() {
    _lib ??= _dylib;
  }

  static DynamicLibrary get lib {
    init();
    return _lib!;
  }

  UnnuTts._();

  static final UnnuTts _singleton = UnnuTts._();

  static UnnuTts get instance => _singleton;

  static NativeCallable<SpeakingActivityCallbackFunction>?
      _nativeSpeakingEventCallable;

  /// Controller to listen to silence changed event.
  static final StreamController<bool> _speakingEventController =
      StreamController.broadcast(
    onListen: () {
      if (_nativeSpeakingEventCallable == null) {
        _set_speaking_event_callback();
      }
    },
    onCancel: () {
      if (_nativeSpeakingEventCallable != null) {
        _nativeSpeakingEventCallable!.close();
        unnu_tts_unset_speaking_callback();
        _nativeSpeakingEventCallable = null;
      }
    },
  );

  /// Stream of silence state changes.
  Stream<bool> get speakingEvents => _speakingEventController.stream;

  static Future<void> configure(
      OfflineTtsConfig config) async {
    init();
    return await Isolate.run(()=>_configure(config));
  }

  static void _configure(
      OfflineTtsConfig config){

    final c = ffi.calloc<SherpaOnnxOfflineTtsConfig>();
    c.ref.model.vits.model =
        config.model.vits.model.toNativeUtf8().cast<Char>();
    c.ref.model.vits.lexicon =
        config.model.vits.lexicon.toNativeUtf8().cast<Char>();
    c.ref.model.vits.tokens =
        config.model.vits.tokens.toNativeUtf8().cast<Char>();
    c.ref.model.vits.data_dir =
        config.model.vits.dataDir.toNativeUtf8().cast<Char>();
    c.ref.model.vits.noise_scale = config.model.vits.noiseScale;
    c.ref.model.vits.noise_scale_w = config.model.vits.noiseScaleW;
    c.ref.model.vits.length_scale = config.model.vits.lengthScale;
    c.ref.model.vits.dict_dir =
        config.model.vits.dictDir.toNativeUtf8().cast<Char>();

    c.ref.model.matcha.acoustic_model =
        config.model.matcha.acousticModel.toNativeUtf8().cast<Char>();
    c.ref.model.matcha.vocoder =
        config.model.matcha.vocoder.toNativeUtf8().cast<Char>();
    c.ref.model.matcha.lexicon =
        config.model.matcha.lexicon.toNativeUtf8().cast<Char>();
    c.ref.model.matcha.tokens =
        config.model.matcha.tokens.toNativeUtf8().cast<Char>();
    c.ref.model.matcha.data_dir =
        config.model.matcha.dataDir.toNativeUtf8().cast<Char>();
    c.ref.model.matcha.noise_scale = config.model.matcha.noiseScale;
    c.ref.model.matcha.length_scale = config.model.matcha.lengthScale;
    c.ref.model.matcha.dict_dir =
        config.model.matcha.dictDir.toNativeUtf8().cast<Char>();

    c.ref.model.kokoro.model =
        config.model.kokoro.model.toNativeUtf8().cast<Char>();
    c.ref.model.kokoro.voices =
        config.model.kokoro.voices.toNativeUtf8().cast<Char>();
    c.ref.model.kokoro.tokens =
        config.model.kokoro.tokens.toNativeUtf8().cast<Char>();
    c.ref.model.kokoro.data_dir =
        config.model.kokoro.dataDir.toNativeUtf8().cast<Char>();
    c.ref.model.kokoro.length_scale = config.model.kokoro.lengthScale;
    c.ref.model.kokoro.dict_dir =
        config.model.kokoro.dictDir.toNativeUtf8().cast<Char>();
    c.ref.model.kokoro.lexicon =
        config.model.kokoro.lexicon.toNativeUtf8().cast<Char>();
    c.ref.model.kokoro.lang =
        config.model.kokoro.lang.toNativeUtf8().cast<Char>();

    c.ref.model.num_threads = config.model.numThreads;
    c.ref.model.debug = config.model.debug ? 1 : 0;
    c.ref.model.provider = config.model.provider.toNativeUtf8().cast<Char>();

    c.ref.rule_fsts = config.ruleFsts.toNativeUtf8().cast<Char>();
    c.ref.max_num_sentences = config.maxNumSenetences;
    c.ref.rule_fars = config.ruleFars.toNativeUtf8().cast<Char>();
    c.ref.silence_scale = config.silenceScale;

    unnu_tts_init(c.ref);

    ffi.calloc.free(c.ref.rule_fars);
    ffi.calloc.free(c.ref.rule_fsts);
    ffi.calloc.free(c.ref.model.provider);

    ffi.calloc.free(c.ref.model.kokoro.lang);
    ffi.calloc.free(c.ref.model.kokoro.lexicon);
    ffi.calloc.free(c.ref.model.kokoro.dict_dir);
    ffi.calloc.free(c.ref.model.kokoro.data_dir);
    ffi.calloc.free(c.ref.model.kokoro.tokens);
    ffi.calloc.free(c.ref.model.kokoro.voices);
    ffi.calloc.free(c.ref.model.kokoro.model);

    ffi.calloc.free(c.ref.model.matcha.dict_dir);
    ffi.calloc.free(c.ref.model.matcha.data_dir);
    ffi.calloc.free(c.ref.model.matcha.tokens);
    ffi.calloc.free(c.ref.model.matcha.lexicon);
    ffi.calloc.free(c.ref.model.matcha.vocoder);
    ffi.calloc.free(c.ref.model.matcha.acoustic_model);

    ffi.calloc.free(c.ref.model.vits.dict_dir);
    ffi.calloc.free(c.ref.model.vits.data_dir);
    ffi.calloc.free(c.ref.model.vits.tokens);
    ffi.calloc.free(c.ref.model.vits.lexicon);
    ffi.calloc.free(c.ref.model.vits.model);
  }

  void speak(String text, int sid, double speed) {
    final words = text.toNativeUtf8().cast<Char>();
    try {
      unnu_tts(words, sid, speed);
    } finally {
      ffi.calloc.free(words);
    }
  }

  static void _speakingEventCallback(Pointer<UnnuTTSBoolStruct_t> speaking) {
    try {
      _speakingEventController.add(speaking.ref.value);
    } on Error catch (e, s) {
        debugPrintStack(stackTrace: s);
    } finally {
      unnu_tts_free_bool(speaking);
    }
  }

  static void _set_speaking_event_callback() {
    if (_nativeSpeakingEventCallable == null) {
      _nativeSpeakingEventCallable =
          NativeCallable<SpeakingActivityCallbackFunction>.listener(
        _speakingEventCallback,
      );

      _nativeSpeakingEventCallable!.keepIsolateAlive = false;

      unnu_tts_set_speaking_callback(
          _nativeSpeakingEventCallable!.nativeFunction);
    }
  }

  bool get enabled => unnu_tts_is_enabled();

  set enabled(bool value) {
    unnu_tts_enable(value);
  }

  bool get muted => unnu_tts_is_muted();

  set muted(bool value) {
    unnu_tts_mute(value);
  }

  bool get supported => unnu_tts_is_supported();

  bool get streaming => unnu_tts_is_streaming();

  bool get speaking => unnu_tts_is_speaking();

  static void destroy() {
    if (_nativeSpeakingEventCallable != null) {
      _nativeSpeakingEventCallable!.close();
      _nativeSpeakingEventCallable = null;
    }
    unnu_tts_destroy();
  }
}
