part of '../unnu_ce.dart';

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
const String _libName = 'unnu_ce';

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


class UnnuCE {
  static DynamicLibrary? _lib;

  /// Returns an instance of the `unnu_dxl` library.
  ///
  /// This getter initializes the `_lib` field if it is `null` by loading the
  /// appropriate dynamic library based on the current platform:
  ///
  /// - On Windows, it loads `unnu_dxl.dll`.
  /// - On Linux or Android, it loads `libunnu_dxl.so`.
  /// - On macOS or iOS, it loads `unnu_dxl.framework/unnu_dxl`.
  ///
  /// Throws a [Exception] if the platform is unsupported.

  static void _init() {
    _lib ??= _dylib;
  }

  static DynamicLibrary get lib {
    _init();
    return _lib!;
  }

  UnnuCE._();

  static final UnnuCE _singleton = UnnuCE._();

  static UnnuCE get instance => _singleton;

  static void configure(String model_path) {
    _init();
    final input = model_path.toNativeUtf8();
    unnu_oga_init(input.cast<Char>());
    ffi.calloc.free(input);
  }

  static void agent(String script_path) {
    _init();

    final script = script_path.toNativeUtf8();
    unnu_soar_init(script.cast<Char>());
    ffi.calloc.free(script);
    unnu_soar_start();
  }

  Stream<String> analyze(String text) async* {
    if (kDebugMode) {
      print('UnnuCE::analyze($text)');
    }

    NativeCallable<OgaResultCallbackFunction>?
    nativeResponseCallable;

    final StreamController<String> responseStreamController =
    StreamController.broadcast(
        onCancel: () {
          if (nativeResponseCallable != null) {
            nativeResponseCallable!.close();
            unnu_unset_oga_result_callback();
            nativeResponseCallable = null;
          }
        },
        sync: true);

    void onResponseCallback(UnnuOgaResult_t response) {
      if (kDebugMode) {
        print('onResponseCallback()');
      }
      try {
          if (response.length > 0) {
            final text = response.result.cast<ffi.Utf8>()
                .toDartString();
            responseStreamController.add(text);
          } else{
          responseStreamController.add("");
        }
      } finally {
        if (response.length > 0) {
          ffi.calloc.free(response.result);
        }
      }
      if (kDebugMode) {
        print('onResponseCallback:>');
      }
    }

    if (kDebugMode) {
      print('unnu_set_ragl_result_callback()');
    }

    nativeResponseCallable =
    NativeCallable<OgaResultCallbackFunction>.listener(
      onResponseCallback
    );

    nativeResponseCallable!.keepIsolateAlive = false;

    unnu_set_oga_result_callback(nativeResponseCallable!.nativeFunction);

    final query = text.toNativeUtf8();
    unnu_oga_prompt(query.cast<Char>());
    /// Stream of token responses.
    await for (final response in responseStreamController.stream) {
      if(response.isEmpty){
        break;
      }
      yield response;
    }

    ffi.calloc.free(query);
  }

  void reset() {
    unnu_soar_reset();
  }

  void destroy() {
    unnu_soar_destroy();
  }
}


