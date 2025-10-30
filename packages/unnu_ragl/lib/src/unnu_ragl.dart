part of '../unnu_ragl.dart';

const String _libName = 'unnu_ragl';

/// The dynamic library in which the symbols for [UnnuRagLiteBindings] can be found.
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

typedef RagEmbedding = ({int id, String text});

enum RagEmbeddingVectorType { EMBEDDING, QUERY, ID }

typedef RagEmbeddingVector =
    ({
      RagEmbeddingVectorType type,
      String documentId,
      String document,
      List<double> embeddings,
    });

class RagLite with ChangeNotifier {
  static DynamicLibrary? _lib;
  static void init() {
    _lib ??= _dylib;
  }

  static DynamicLibrary get lib {
    init();
    return _lib!;
  }

  RagLite._();

  static final RagLite _singleton = RagLite._();

  static RagLite get instance => _singleton;

  static void configure(String model_path) {
    init();
    final input = model_path.toNativeUtf8();
    unnu_rag_lite_init(input.cast<Char>());
    ffi.calloc.free(input);
  }

  static bool setup({String? kb, bool shared_memory = true}) {
    init();
    final errorCode = ffi.calloc<Int>();
    if (kb != null) {
      final tag = kb.toNativeUtf8();
      // if (shared_memory) {
      //   unnu_rag_lite_open_memory(tag.cast<Char>(), errorCode);
      // } else {
      unnu_rag_lite_open_kb(tag.cast<Char>(), errorCode);
      //}
      ffi.calloc.free(tag);
    } else {
      unnu_rag_lite_open_kb(nullptr, errorCode);
    }

    final val = errorCode.value;
    ffi.calloc.free(errorCode);
    return val != 0;
  }

  Future<List<String>> query(String text) async {
    if (kDebugMode) {
      print('RagLite::query($text)');
    }
    final completer = Completer<List<String>>();

    NativeCallable<UnnuRaglResponseCallbackFunction>? nativeResponseCallable;

    void onResponseCallback(Pointer<UnnuRaglResult> response) {
      if (kDebugMode) {
        print('onResponseCallback()');
      }
      final result = List<String>.empty(growable: true);
      try {
        if (response.ref.type == UnnuRaglResultType.UNNU_RAGL_QUERY) {
          if (response.ref.count > 0) {
            final fragmentsPtr = response.ref.fragments;
            for (var i = 0; i < response.ref.count; i++) {
              final it = fragmentsPtr + i;
              if (it.value.ref.length > 0) {
                final text = it.value.ref.text.cast<ffi.Utf8>().toDartString();
                result.add(text);
              }
            }
          }
        }
      } finally {
        unnu_ragl_free_result(response);
        if (kDebugMode) {
          print('unnu_set_ragl_result_callback:>');
        }

        if (nativeResponseCallable != null) {
          nativeResponseCallable!.close();
          unnu_unset_ragl_result_callback();
          nativeResponseCallable = null;
        }
      }
      completer.complete(result);
      if (kDebugMode) {
        print('onResponseCallback:>');
      }
    }

    if (kDebugMode) {
      print('unnu_set_ragl_result_callback()');
    }

    nativeResponseCallable =
        NativeCallable<UnnuRaglResponseCallbackFunction>.listener(
          onResponseCallback,
        );

    nativeResponseCallable!.keepIsolateAlive = false;

    unnu_set_ragl_result_callback(nativeResponseCallable!.nativeFunction);

    final query = text.toNativeUtf8();
    unnu_rag_lite_query(query.cast<Char>());

    /// Stream of token responses.
    return completer.future.whenComplete(
      () => ffi.calloc.free(query),
    );
  }

  Stream<RagEmbeddingVector> embed(String text) async* {
    NativeCallable<UnnuRaglEmbeddingCallbackFunction>? nativeEmbeddingCallable;

    var completed = false;
    final responseStreamController =
        StreamController<RagEmbeddingVector>.broadcast(
          onCancel: () {
            if (nativeEmbeddingCallable != null) {
              nativeEmbeddingCallable!.close();
              unnu_unset_ragl_embedding_callback();
              nativeEmbeddingCallable = null;
            }
          },
          sync: true,
        );

    Future<void> closeStreamAsync() async {
      await responseStreamController.close();
    }

    void onEmbeddingCallback(Pointer<UnnuRagEmbdVec_t> response) {
      try {
        if (response.ref.type == UnnuRaglResultType.UNNU_RAGL_EMBEDDING) {
          if (response.ref.count > 0 &&
              response.ref.length > 0 &&
              response.ref.reflen > 0) {
            responseStreamController.add((
              type: RagEmbeddingVectorType.EMBEDDING,
              documentId: response.ref.ref_id.cast<ffi.Utf8>().toDartString(
                length: response.ref.reflen,
              ),
              document: response.ref.text.cast<ffi.Utf8>().toDartString(
                length: response.ref.length,
              ),
              embeddings: response.ref.values
                  .asTypedList(response.ref.count)
                  .toList(growable: false),
            ));
          }
        } else {
          responseStreamController.add((
            type: RagEmbeddingVectorType.ID,
            documentId:
                response.ref.reflen > 0
                    ? response.ref.ref_id.cast<ffi.Utf8>().toDartString(
                      length: response.ref.reflen,
                    )
                    : '',
            document: '',
            embeddings: <double>[],
          ));
          completed = true;
        }
      } on FormatException catch (e, s) {
        if (kDebugMode) {
          debugPrintStack(stackTrace: s, label: e.message);
        }
        try {
          final characters = response.ref.text;
          final length = characters.cast<ffi.Utf8>().length;

          final charList = Uint8List.view(
            characters.cast<Uint8>().asTypedList(length).buffer,
            0,
            length,
          );
          responseStreamController.add((
            type: RagEmbeddingVectorType.EMBEDDING,
            documentId: response.ref.ref_id.cast<ffi.Utf8>().toDartString(
              length: response.ref.reflen,
            ),
            document: utf8.decode(
              charList.toList(),
              allowMalformed: true,
            ),
            embeddings: response.ref.values
                .asTypedList(response.ref.count)
                .toList(growable: false),
          ));
        } on Exception catch (e, s) {
          if (kDebugMode) {
            debugPrintStack(stackTrace: s);
          }
        }
      } finally {
        unnu_ragl_free_embedvector(response);
        if (completed) {
          if (!responseStreamController.isClosed) {
            unawaited(closeStreamAsync());
          }
        }
      }
    }

    nativeEmbeddingCallable =
        NativeCallable<UnnuRaglEmbeddingCallbackFunction>.listener(
          onEmbeddingCallback,
        );

    nativeEmbeddingCallable!.keepIsolateAlive = false;

    unnu_set_ragl_embedding_callback(nativeEmbeddingCallable!.nativeFunction);

    final query = text.toNativeUtf8();
    unnu_rag_lite_embed(query.cast<Char>());

    /// Stream of token responses.
    yield* responseStreamController.stream;

    ffi.calloc.free(query);
  }

  void addMapping(String uri, String documentId) {
    final docUri = uri.toNativeUtf8();
    final docId = documentId.toNativeUtf8();
    unnu_rag_lite_mapping(docUri.cast<Char>(), docId.cast<Char>());
    ffi.calloc.free(docId);
    ffi.calloc.free(docUri);
  }

  void deleteEmbedding(String uri, String documentId) {
    final docUri = uri.toNativeUtf8();
    final docId = documentId.toNativeUtf8();
    unnu_rag_lite_delete(docId.cast<Char>(), docUri.cast<Char>());
    ffi.calloc.free(docId);
    ffi.calloc.free(docUri);
  }

  Stream<RagEmbeddingVector> retrieve(String id) async* {
    if (kDebugMode) {
      print('RagLite::retrieve($id)');
    }
    NativeCallable<UnnuRaglEmbeddingCallbackFunction>? nativeEmbeddingCallable;

    final responseStreamController =
        StreamController<RagEmbeddingVector>.broadcast(
          onCancel: () {
            if (nativeEmbeddingCallable != null) {
              nativeEmbeddingCallable!.close();
              unnu_unset_ragl_embedding_callback();
              nativeEmbeddingCallable = null;
            }
          },
          sync: true,
        );

    Future<void> closeStreamAsync() async {
      await responseStreamController.close();
    }

    void onEmbeddingCallback(Pointer<UnnuRagEmbdVec_t> response) {
      try {
        if (response.ref.type == UnnuRaglResultType.UNNU_RAGL_EMBEDDING) {
          if (response.ref.length > 0) {
            final doc = response.ref.text.cast<ffi.Utf8>().toDartString(
              length: response.ref.length,
            );
            final refId = response.ref.ref_id.cast<ffi.Utf8>().toDartString(
              length: response.ref.reflen,
            );
            final count = response.ref.count;
            final embd = response.ref.values
                .asTypedList(count)
                .toList(growable: false);
            responseStreamController.add((
              type: RagEmbeddingVectorType.EMBEDDING,
              documentId: refId,
              document: doc,
              embeddings: embd,
            ));
          }
        } else if (response.ref.type == UnnuRaglResultType.UNNU_RAGL_FINISH ||
            response.ref.type == UnnuRaglResultType.UNNU_RAGL_ERROR) {
          if (!responseStreamController.isClosed) {
            unawaited(closeStreamAsync());
          }
        }
      } finally {
        unnu_ragl_free_embedvector(response);
      }
    }

    nativeEmbeddingCallable =
        NativeCallable<UnnuRaglEmbeddingCallbackFunction>.listener(
          onEmbeddingCallback,
        );

    nativeEmbeddingCallable!.keepIsolateAlive = false;

    unnu_set_ragl_embedding_callback(nativeEmbeddingCallable!.nativeFunction);

    final docId = id.toNativeUtf8();
    unnu_rag_lite_retrieve(docId.cast<Char>());

    /// Stream of token responses.
    yield* responseStreamController.stream;

    ffi.calloc.free(docId);
  }

  Future<RagEmbeddingVector> embedQuery(String text) async {
    if (kDebugMode) {
      print('RagLite::query($text)');
    }

    NativeCallable<UnnuRaglEmbeddingCallbackFunction>? nativeEmbeddingCallable;

    final completer = Completer<RagEmbeddingVector>();

    void onEmbeddingCallback(Pointer<UnnuRagEmbdVec_t> response) {
      try {
        if (response.ref.type == UnnuRaglResultType.UNNU_RAGL_QUERY) {
          if (response.ref.length > 0) {
            final doc = response.ref.text.cast<ffi.Utf8>().toDartString(
              length: response.ref.length,
            );

            final count = response.ref.count;
            final embd = response.ref.values
                .asTypedList(count)
                .toList(growable: false);
            completer.complete((
              type: RagEmbeddingVectorType.QUERY,
              documentId: '',
              document: doc,
              embeddings: embd,
            ));
          }
        } else if (response.ref.type == UnnuRaglResultType.UNNU_RAGL_FINISH) {
          completer.complete((
            type: RagEmbeddingVectorType.ID,
            documentId:
                response.ref.reflen > 0
                    ? response.ref.ref_id.cast<ffi.Utf8>().toDartString(
                      length: response.ref.reflen,
                    )
                    : '',
            document: '',
            embeddings: const <double>[],
          ));
        }
      } on FormatException catch (e, s) {
        try {
          final characters = response.ref.text;
          final length = characters.cast<ffi.Utf8>().length;

          final charList = Uint8List.view(
            characters.cast<Uint8>().asTypedList(length).buffer,
            0,
            length,
          );
          final output = utf8.decode(charList.toList(), allowMalformed: true);

          final count = response.ref.count;
          final embd = response.ref.values
              .asTypedList(count)
              .toList(growable: false);
          completer.complete((
            type: RagEmbeddingVectorType.QUERY,
            documentId: '',
            document: output,
            embeddings: embd,
          ));
        } on Exception catch (e, s) {
          if (kDebugMode) {
            debugPrintStack(stackTrace: s);
          }
          completer.complete((
            type: RagEmbeddingVectorType.ID,
            documentId:
                response.ref.reflen > 0
                    ? response.ref.ref_id.cast<ffi.Utf8>().toDartString(
                      length: response.ref.reflen,
                    )
                    : '',
            document: '',
            embeddings: const <double>[],
          ));
        }
      } finally {
        unnu_ragl_free_embedvector(response);
      }
    }

    nativeEmbeddingCallable =
        NativeCallable<UnnuRaglEmbeddingCallbackFunction>.listener(
          onEmbeddingCallback,
        );

    nativeEmbeddingCallable!.keepIsolateAlive = false;

    unnu_set_ragl_embedding_callback(nativeEmbeddingCallable!.nativeFunction);

    final query = text.toNativeUtf8();
    unnu_rag_lite_query(query.cast<Char>());

    return completer.future.whenComplete(() {
      if (nativeEmbeddingCallable != null) {
        nativeEmbeddingCallable!.close();
        unnu_unset_ragl_embedding_callback();
        nativeEmbeddingCallable = null;
      }
      ffi.calloc.free(query);
    });
  }

  void setChunkSize(int sz) {
    unnu_rag_lite_set_chunk_size(sz);
  }

  void setEmbeddingSize(int sz) {
    unnu_rag_lite_update_dims(sz);
  }

  void enableParagraphChunking(bool val) {
    unnu_rag_lite_enable_paragraph_chunking(val ? 0 : 1);
  }

  void setResultSize(int lmt) {
    unnu_rag_lite_result_limit(lmt);
  }

  void setPoolingType(int type) {
    unnu_rag_lite_set_pooling_type(type);
  }

  void _reset() {
    unnu_rag_lite_closeall_kb();
  }

  void destroy() {
    unnu_rag_lite_destroy();
  }
}
