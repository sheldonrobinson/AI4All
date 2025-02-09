part of '../unnu_dxl.dart';

/// Transcript type.
typedef UnnuDxlExtract = ({Map<String, dynamic> metadata, String text});

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
const String _libName = 'unnu_dxl';

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

class UnnuDxl {
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

  UnnuDxl._();

  static final UnnuDxl _singleton = UnnuDxl._();

  static UnnuDxl get instance => _singleton;

  Future<List<UnnuDxlExtract>> process(String filepath) async {
    if (kDebugMode) {
      print('UnnuDxl::process($filepath)');
    }

    NativeCallable<UnnuDxlResultCallbackFunction>? _nativeParseEventCallable;

    /// Controller to listen to silence changed event.


    final extract = List<UnnuDxlExtract>.empty(growable: true);
    final completer = Completer<void>();
    void onResultCallback(UnnuDxlParseResult_t result) {
      if (kDebugMode) {
        print('onResultCallback()');
      }
      try {
        final Map<String, dynamic> metadata = Map<String, dynamic>();
        metadata['file_path'] = filepath;
        if (result.num_metadata_entries > 0) {
          final metadataPtr = result.metadata;
          for (int i = 0; i < result.num_metadata_entries; i++) {
            final it = metadataPtr + i;
            if (it.ref.length > 0) {
              final key = it.ref.key.cast<ffi.Utf8>().toDartString(
                length: it.ref.length,
              );
              switch (it.ref.value.type) {
                case UnnuDxlDataType.UNNU_DXL_BOOL:
                  metadata[key] = it.ref.value.data.boolvalue;
                  break;
                case UnnuDxlDataType.UNNU_DXL_INT:
                  metadata[key] = it.ref.value.data.intvalue;
                  break;
                case UnnuDxlDataType.UNNU_DXL_FLOAT:
                  metadata[key] = it.ref.value.data.floatvalue;
                  break;
                case UnnuDxlDataType.UNNU_DXL_STRING:
                  metadata[key] =
                      it.ref.value.length > 0
                          ? it.ref.value.data.value
                              .cast<ffi.Utf8>()
                              .toDartString(length: it.ref.value.length)
                          : '';
                  if (it.ref.value.length > 0) {
                    ffi.calloc.free(it.ref.value.data.value);
                  }
                  break;
                case UnnuDxlDataType.UNNU_DXL_JSON:
                  metadata[key] =
                      it.ref.value.length > 0
                          ? it.ref.value.data.value
                              .cast<ffi.Utf8>()
                              .toDartString(length: it.ref.value.length)
                          : '';
                  break;
                case UnnuDxlDataType.UNNU_DXL_XML:
                  metadata[key] =
                      it.ref.value.length > 0
                          ? it.ref.value.data.value
                              .cast<ffi.Utf8>()
                              .toDartString(length: it.ref.value.length)
                          : '';
                  break;
                case UnnuDxlDataType.UNNU_DXL_BINARY:
                  // TODO: Handle this case.
                  // throw UnimplementedError();
                  break;
                case UnnuDxlDataType.UNNU_DXL_ERROR:
                  // TODO: Handle this case.
                  // throw UnimplementedError();
                  break;
              }
            }
          }
        }
        final text =
            result.length > 0
                ? result.buffer.cast<ffi.Utf8>().toDartString(
                  length: result.length,
                )
                : '';

        extract.add((metadata: metadata, text: text));
      } finally {
        if (result.length > 0) {
          ffi.calloc.free(result.buffer);
        }
        if (result.num_metadata_entries > 0) {
          final metadataPtr = result.metadata;
          for (int i = 0; i < result.num_metadata_entries; i++) {
            final it = metadataPtr + i;
            if (it.ref.length > 0) {
              ffi.calloc.free(it.ref.key);
            }
            if (it.ref.value.type == UnnuDxlDataType.UNNU_DXL_JSON ||
                it.ref.value.type == UnnuDxlDataType.UNNU_DXL_STRING ||
                it.ref.value.type == UnnuDxlDataType.UNNU_DXL_XML) {
              if (it.ref.value.length > 0) {
                ffi.calloc.free(it.ref.value.data.value);
              }
            }
          }
        }
        if (_nativeParseEventCallable != null) {
          _nativeParseEventCallable!.close();
          unnu_dxl_unset_parse_callback();
          _nativeParseEventCallable = null;
        }
      }
      completer.complete();
      if (kDebugMode) {
        print('onResultCallback:>');
      }
    }

    if (kDebugMode) {
      print('_set_parse_event_callback()');
    }
    _nativeParseEventCallable =
        NativeCallable<UnnuDxlResultCallbackFunction>.listener(
          onResultCallback,
        );

    _nativeParseEventCallable!.keepIsolateAlive = false;

    unnu_dxl_set_parse_callback(_nativeParseEventCallable!.nativeFunction);

    final path = filepath.toNativeUtf8();
    unnu_dxl_parse(path.cast<Char>());

    /// Stream of token responses.
    await completer.future;
    ffi.calloc.free(path);
    return extract;
  }
}
