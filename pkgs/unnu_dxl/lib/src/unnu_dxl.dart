part of '../unnu_dxl.dart';

/// Transcript type.
typedef UnnuDxlExtract = ({Map<String, dynamic> metadata, String text});

const String _libName = 'unnu_dxl';

/// The dynamic library in which the symbols for [UnnuDxlBindings] can be found.
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

  static void init() {
    _lib ??= _dylib;
  }

  static DynamicLibrary get lib {
    init();
    return _lib!;
  }

  UnnuDxl._();

  static final UnnuDxl _singleton = UnnuDxl._();

  static UnnuDxl get instance => _singleton;

  Future<List<UnnuDxlExtract>> process(String url) async {
    if (kDebugMode) {
      print('UnnuDxl::process($url)');
    }

    NativeCallable<UnnuDxlResultCallbackFunction>? _nativeParseEventCallable;

    final extract = List<UnnuDxlExtract>.empty(growable: true);
    final completer = Completer<void>();
    void onResultCallback(Pointer<UnnuDxlParseResult_t> result) {
      if (kDebugMode) {
        print('onResultCallback()');
      }
      final metaEntries = result.ref.num_metadata_entries;
      final metadata = <String, dynamic>{};
      metadata['unnu.dox.url'] = url;
      try {
        if (metaEntries > 0) {
          final metadataPtr = result.ref.metadata;
          for (var i = 0; i < metaEntries; i++) {
            final it = metadataPtr + i;
            if (it.ref.length > 0) {
              final key = it.ref.key.cast<ffi.Utf8>().toDartString(
                length: it.ref.length,
              );
              switch (it.ref.value.type) {
                case UnnuDxlDataType.UNNU_DXL_BOOL:
                  metadata[key] = it.ref.value.data.boolvalue;
                case UnnuDxlDataType.UNNU_DXL_INT:
                  metadata[key] = it.ref.value.data.intvalue;
                  break;
                case UnnuDxlDataType.UNNU_DXL_FLOAT:
                  metadata[key] = it.ref.value.data.floatvalue;
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
                case UnnuDxlDataType.UNNU_DXL_JSON:
                  metadata[key] =
                  it.ref.value.length > 0
                      ? it.ref.value.data.value
                      .cast<ffi.Utf8>()
                      .toDartString(length: it.ref.value.length)
                      : '';
                case UnnuDxlDataType.UNNU_DXL_XML:
                  metadata[key] =
                  it.ref.value.length > 0
                      ? it.ref.value.data.value
                      .cast<ffi.Utf8>()
                      .toDartString(length: it.ref.value.length)
                      : '';
                case UnnuDxlDataType.UNNU_DXL_BINARY:
                  break;
                case UnnuDxlDataType.UNNU_DXL_ERROR:
                  break;
              }
            }
          }
        }
      } on Exception catch (e, s) {
        if (kDebugMode) {
          debugPrintStack(stackTrace: s, label: e.toString());
        }
      }
      try {
        final len = result.ref.length;
        final text =
            result.ref.length > 0
                ? result.ref.buffer.cast<ffi.Utf8>().toDartString(
                  length: result.ref.length,
                )
                : '';

        extract.add((metadata: metadata, text: text));
      } on FormatException catch (e, s) {
        if (kDebugMode) {
          debugPrintStack(stackTrace: s, label: e.toString());
        }
        try {
          final characters = result.ref.buffer;
          final length = characters.cast<ffi.Utf8>().length;
          final charList = Uint8List.view(
            characters.cast<Uint8>().asTypedList(length).buffer,
            0,
            length,
          );
          final output = utf8.decode(charList.toList(), allowMalformed: true);
          extract.add((metadata: metadata, text: output));
        } on Exception catch (e, s) {
          if (kDebugMode) {
            debugPrintStack(stackTrace: s, label: e.toString());
          }
        }
      } finally {
        if (kDebugMode) {
          print('onResultCallback:finally');
        }
        unnu_dxl_free_result(result);
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

    _nativeParseEventCallable =
        NativeCallable<UnnuDxlResultCallbackFunction>.listener(
          onResultCallback,
        );

    _nativeParseEventCallable!.keepIsolateAlive = false;

    unnu_dxl_set_parse_callback(_nativeParseEventCallable!.nativeFunction);

    final path = url.toNativeUtf8();
    unnu_dxl_parse(path.cast<Char>());

    /// Stream of token responses.
    await completer.future;
    ffi.calloc.free(path);
    return extract;
  }
}
