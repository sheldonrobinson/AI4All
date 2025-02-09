part of 'package:llamacpp/llamacpp.dart';

Pointer<Pointer<lcpp_common_chat_msg_t>> convertToLcppCommonChatMsg(
    List<cm.ChatMessage> messages) {
  List<Pointer<lcpp_common_chat_msg>> list_of_common_msgs =
      List<Pointer<lcpp_common_chat_msg>>.empty(growable: true);
  messages.asMap().forEach((idx, msg) {
    switch (msg) {
      case cm.HumanChatMessage():
        final msgPtr = ffi.calloc<lcpp_common_chat_msg>();
        msgPtr.ref.role = "user".toNativeUtf8().cast<Char>();
        msgPtr.ref.n_role = "user".length;
        final cm.ChatMessageContent content = msg.content;
        switch (content) {
          case cm.ChatMessageContentText():
            msgPtr.ref.content = content.text.toNativeUtf8().cast<Char>();
            msgPtr.ref.n_content = content.text.length;
            break;
          case cm.ChatMessageContentImage():
            final content_part =
                ffi.calloc<lcpp_common_chat_msg_content_part>();
            msgPtr.ref.content_parts =
                ffi.calloc<Pointer<lcpp_common_chat_msg_content_part>>(1);
            if (content.mimeType != null) {
              content_part.ref.type =
                  content.mimeType!.toNativeUtf8().cast<Char>();
              content_part.ref.n_type = content.mimeType!.length;
            } else {
              content_part.ref.type = "".toNativeUtf8().cast<Char>();
              ;
              content_part.ref.n_type = 0;
            }
            content_part.ref.text = content.data.toNativeUtf8().cast<Char>();
            content_part.ref.n_text = content.data.length;
            msgPtr.ref.content_parts[0] = content_part;
            msgPtr.ref.n_content_parts = 1;
            break;
          case cm.ChatMessageContentMultiModal():
            if (kDebugMode) {
              print("HumanChatMessage::ChatMessageContentMultiModal");
            }
            if (content.parts.isNotEmpty) {
              msgPtr.ref.content_parts =
                  ffi.calloc<Pointer<lcpp_common_chat_msg_content_part>>(
                      content.parts.length);
              List<Pointer<lcpp_common_chat_msg_content_part>>
                  list_of_content_parts =
                  List<Pointer<lcpp_common_chat_msg_content_part>>.empty(
                      growable: true);
              content.parts.forEach((part) {
                switch (part) {
                  case cm.ChatMessageContentText():
                    if (kDebugMode) {
                      print(
                          "ChatMessageContentMultiModal::ChatMessageContentText");
                    }
                    final context_part =
                        ffi.calloc<lcpp_common_chat_msg_content_part>();
                    context_part.ref.text =
                        part.text.toNativeUtf8().cast<Char>();
                    context_part.ref.n_text = part.text.length;
                    list_of_content_parts.add(context_part);
                    break;
                  case cm.ChatMessageContentImage():
                    if (kDebugMode) {
                      print(
                          "ChatMessageContentMultiModal::ChatMessageContentImage");
                    }
                    final context_part =
                        ffi.calloc<lcpp_common_chat_msg_content_part>();
                    if (part.mimeType != null) {
                      context_part.ref.type =
                          part.mimeType!.toNativeUtf8().cast<Char>();
                      context_part.ref.n_type = part.mimeType!.length;
                    } else {
                      context_part.ref.type = "".toNativeUtf8().cast<Char>();
                      context_part.ref.n_type = 0;
                    }
                    context_part.ref.text =
                        part.data.toNativeUtf8().cast<Char>();
                    context_part.ref.n_text = part.data.length;
                    list_of_content_parts.add(context_part);
                    break;

                  case cm.ChatMessageContentMultiModal():
                    // final _context_part = ffi.calloc<lcpp_common_chat_msg_content_part>();
                    // _context_part.ref.type = "".toNativeUtf8().cast<ffi.Char>();
                    // _context_part.ref.n_type = 0;
                    // _context_part.ref.text =
                    //     "".toNativeUtf8().cast<ffi.Char>();
                    // _context_part.ref.n_text = "".length;
                    // _list_content_parts.add(_context_part);
                    break;
                }
              });
              list_of_content_parts.asMap().forEach((idx, value) {
                if (kDebugMode) {
                  print("_list_content_parts[$idx]");
                }
                msgPtr.ref.content_parts[idx] = value;
              });
            }
            break;
        }
        list_of_common_msgs.add(msgPtr);
        break;
      case cm.AIChatMessage():
        if (kDebugMode) {
          print("AIChatMessage()");
        }
        final msgPtr = ffi.calloc<lcpp_common_chat_msg>();
        msgPtr.ref.role = "assistant".toNativeUtf8().cast<Char>();
        msgPtr.ref.n_role = "assistant".length;
        msgPtr.ref.content = msg.content.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_content = msg.content.length;
        if (msg.toolCalls.isNotEmpty) {
          msgPtr.ref.tool_calls =
              ffi.calloc<Pointer<lcpp_common_chat_tool_call>>(
                  msg.toolCalls.length);
          List<Pointer<lcpp_common_chat_tool_call>> list_of_tool_calls =
              List<Pointer<lcpp_common_chat_tool_call>>.empty(growable: true);
          msg.toolCalls.forEach((part) {
            final tool_call = ffi.calloc<lcpp_common_chat_tool_call>();
            tool_call.ref.name = part.name.toNativeUtf8().cast<Char>();
            tool_call.ref.n_name = part.name.length;
            String json = JsonEncoder().convert(part.arguments);
            tool_call.ref.arguments = json.toNativeUtf8().cast<Char>();
            tool_call.ref.n_arguments = json.length;
            tool_call.ref.id = part.id.toNativeUtf8().cast<Char>();
            tool_call.ref.n_id = part.id.length;
            list_of_tool_calls.add(tool_call);
          });
          list_of_tool_calls.asMap().forEach((idx, value) {
            if (kDebugMode) {
              print("_list_tool_calls[$idx]");
            }
            msgPtr.ref.tool_calls[idx] = value;
          });
        }
        list_of_common_msgs.add(msgPtr);
        break;
      case cm.ToolChatMessage():
        if (kDebugMode) {
          print("ToolChatMessage()");
        }
        final msgPtr = ffi.calloc<lcpp_common_chat_msg>();
        msgPtr.ref.role = "tool".toNativeUtf8().cast<Char>();
        msgPtr.ref.n_role = "tool".length;
        msgPtr.ref.tool_call_id = msg.toolCallId.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_tool_call_id = msg.toolCallId.length;
        msgPtr.ref.content = msg.content.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_content = msg.content.length;
        list_of_common_msgs.add(msgPtr);
        break;
      case cm.SystemChatMessage():
        if (kDebugMode) {
          print("SystemChatMessage()");
        }
        final msgPtr = ffi.calloc<lcpp_common_chat_msg>();
        msgPtr.ref.role = "system".toNativeUtf8().cast<Char>();
        msgPtr.ref.n_role = "system".length;
        msgPtr.ref.content = msg.content.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_content = msg.content.length;
        list_of_common_msgs.add(msgPtr);
        break;
      case cm.CustomChatMessage():
        if (kDebugMode) {
          print("CustomChatMessage()");
        }
        final msgPtr = ffi.calloc<lcpp_common_chat_msg>();
        msgPtr.ref.role = msg.role.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_role = msg.role.length;
        msgPtr.ref.content = msg.content.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_content = msg.content.length;
        list_of_common_msgs.add(msgPtr);
        break;
    }
  });
  final msgs = ffi.calloc<Pointer<lcpp_common_chat_msg_t>>(messages.length);
  list_of_common_msgs.asMap().forEach((idx, value) {
    msgs[idx] = value;
  });
  return msgs;
}

extension _PromptValueToLlamaCppChatMessagesExtension on PromptValue {
  Pointer<Pointer<lcpp_common_chat_msg_t>> toNative() {
    final messages = toChatMessages();
    return convertToLcppCommonChatMsg(messages);
  }
}

extension _ChatMessageToLlamaCppChatMessagesExtension on List<cm.ChatMessage> {
  Pointer<Pointer<lcpp_common_chat_msg_t>> toNative() {
    return convertToLcppCommonChatMsg(this);
  }
}

extension _FreeLlamaCppChatMessagesExtension
    on Pointer<Pointer<lcpp_common_chat_msg_t>> {
  void free(int length) {
    for (var i = 0; i < length; i++) {
      final msg = this[i];
      if (msg.ref.content != nullptr) {
        ffi.calloc.free(msg.ref.content);
      }
      if (msg.ref.role != nullptr) {
        ffi.calloc.free(msg.ref.role);
      }
      if (msg.ref.tool_call_id != nullptr) {
        ffi.calloc.free(msg.ref.tool_call_id);
      }
      if (msg.ref.n_content_parts > 0 && msg.ref.content_parts != nullptr) {
        for (var j = 0; j < msg.ref.n_content_parts; j++) {
          final part = msg.ref.content_parts[j];
          if (part.ref.text != nullptr) {
            ffi.calloc.free(part.ref.text);
          }
          if (part.ref.type != nullptr) {
            ffi.calloc.free(part.ref.type);
          }
        }
        ffi.calloc.free(msg.ref.content_parts);
      }
      if (msg.ref.n_tool_calls > 0 && msg.ref.tool_calls != nullptr) {
        for (var j = 0; j < msg.ref.n_tool_calls; j++) {
          final part = msg.ref.tool_calls[j];
          if (part.ref.name != nullptr) {
            ffi.calloc.free(part.ref.name);
          }
          if (part.ref.arguments != nullptr) {
            ffi.calloc.free(part.ref.arguments);
          }
          if (part.ref.id != nullptr) {
            ffi.calloc.free(part.ref.id);
          }
        }
        ffi.calloc.free(msg.ref.tool_calls);
      }
      ffi.calloc.free(msg);
    }
    ffi.calloc.free(this);
  }
}

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
const String _libName = 'llamacpp';

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

// final LlamaCppBindings lcpp=  LlamaCppBindings(_dylib);

/// A class that implements the Llama interface and provides functionality
/// for loading and interacting with a Llama model, context, and sampler.
///
/// The class initializes the model, context, and sampler based on the provided
/// parameters and allows for prompting the model with chat messages.
///
/// The class also provides methods to stop the current operation and free
/// the allocated resources.
///
/// Example usage:
/// ```dart
/// final lcpp = Lcpp(
///   modelParams: ModelParams(...),
///   contextParams: ContextParams(...),
///   lcppParams: LcppParams(...)
/// );
///
/// final responseStream = llamacpp.prompt([...]);
/// responseStream.listen((response) {
///   print(response);
/// });
/// ```
///
/// Properties:
/// - `modelParams`: Sets the model parameters and initializes the model.
/// - `contextParams`: Sets the context parameters and initializes the context.
/// - `lcppParams`: Sets the common params.
///
/// Methods:
/// - `prompt(List<ChatMessage> messages, {bool streaming = true})`: Prompts the model with the given chat messages and returns a stream of responses.
/// - `stop()`: Stops the current operation.
/// - `free()`: Frees the allocated resources.
class LlamaCpp {
  static DynamicLibrary? _lib;
  
  static void init() {
    _lib ??= _dylib;
  }

  static DynamicLibrary get lib {
    init();
    return _lib!;
  }

  ContextParams _contextParams;
  LlamaCppParams _lcppParams;

  set contextParams(ContextParams contextParams) {
    _contextParams = contextParams;
  }

  set lcppParams(LlamaCppParams lcppParams) {
    _lcppParams = lcppParams;
  }

  final StreamController<LLMResult> _responseController =
      StreamController.broadcast(
        sync: false,
      );

  Stream<LLMResult> get responses => _responseController.stream;

  /// A class that initializes and manages a native Llama model.
  ///
  /// The [LlamaCpp] constructor requires [ModelParams] and optionally accepts
  /// [ContextParams] and [LlamaCppParams]. It initializes the model by loading
  /// the necessary backends and calling the `_initModel` method.
  ///
  /// Example usage:
  /// ```dart
  /// final llamaNative = LlamaNative(
  ///   modelParams: ModelParams(...),
  ///   contextParams: ContextParams(...),
  ///   samplingParams: SamplingParams(...),
  /// );
  /// ```
  ///
  /// Parameters:
  /// - [contextParams]: Optional parameters for the context configuration. Defaults to an empty [ContextParams] object.
  /// - [lcppParams]: Optional parameters for the sampling configuration. Defaults to an empty [LlamaCppParams] object.
  LlamaCpp(
      {ContextParams? contextParams,
      LlamaCppParams lcppParams = const LlamaCppParams()})
      : _contextParams = contextParams ?? ContextParams(),
        _lcppParams = lcppParams {
    init();
  }

  Stream<double> reconfigure() async* {
    final contextParams = _contextParams.toNative();
    final lcppParams = _lcppParams.toNative();
    final completer = Completer();

    NativeCallable<LppProgressCallbackFunction>? nativeProgressCallable;

    final StreamController<double> responseStreamController =
        StreamController<double>.broadcast(
            onListen: () {
              lcpp_reconfigure(contextParams, lcppParams);
            },
            onCancel: () {
              if (kDebugMode) {
                print('nativeProgressCallable onCancel close()');
              }
              if (nativeProgressCallable != null) {
                nativeProgressCallable!.close();
                lcpp_unset_model_load_progress_callback();
                nativeProgressCallable = null;
              }
              completer.complete();
            },
            sync: true);

    void onProgressCallback(Pointer<LcppFloatStruct_t> response) {
      try {
        final progress = response.ref.value;
        if (kDebugMode) {
          print('onProgressCallback progress: $progress');
        }
        responseStreamController.add(progress);
        if (progress >= 1.0 || progress < 0.0) {
          if(!completer.isCompleted){
            completer.complete();
          }
          if (!responseStreamController.isClosed) {
            responseStreamController.close();
          }

        }
      } finally {
        lcpp_free_float(response);
      }
    }

    nativeProgressCallable =
        NativeCallable<LppProgressCallbackFunction>.listener(
      onProgressCallback,
    );

    lcpp_set_model_load_progress_callback(
        nativeProgressCallable!.nativeFunction);
    yield* responseStreamController.stream;

    if (completer.isCompleted) {
      if (kDebugMode) {
        print('LlamaCpp::reconfigure completer.isCompleted');
      }
      if (!responseStreamController.isClosed) {
        responseStreamController.close();
      }
    }
  }

  Stream<LLMResult> prompt(PromptValue messages,
      {bool streaming = true}) async* {
    final chatMessages = messages.toChatMessages();
    final commonChatMessages = chatMessages.toNative();
    const utf8Decoder = Utf8Decoder(allowMalformed: true);
    final idPrefix = DateTime.now().millisecondsSinceEpoch.toString();
    int tokenCount = 0;

    NativeCallable<LppTokenStreamCallbackFunction>? nativeNewTokenCallable;

    final StreamController<LLMResult> responseStreamController =
        StreamController<LLMResult>.broadcast(
            onCancel: () {
              if (streaming) {
                if (nativeNewTokenCallable != null) {
                  nativeNewTokenCallable!.close();
                  lcpp_unset_token_stream_callback();
                  nativeNewTokenCallable = null;
                }
              }
            },
            sync: true);

    void onNewTokenCallback(Pointer<LcppTextStruct_t> response) {
      try {
        if (streaming) {
          final text = response.ref.text.cast<ffi.Utf8>();
          final output = text.toDartString(length: text.length);

          responseStreamController.add(LLMResult(
              id: '$idPrefix.$tokenCount',
              output: output,
              finishReason: FinishReason.unspecified,
              metadata: {
                'message.id': idPrefix,
                'chunk.id': tokenCount,
                'message.type': 'token'
              },
              usage: const LanguageModelUsage(),
              streaming: true));
        }
      } on FormatException catch (e) {
        if (kDebugMode) {
          print('ont.fmt.ex: ${e.message}');
        }
        try {

          final characters = response.ref.text;
          final length = characters.cast<ffi.Utf8>().length;

          Uint8List charList = Uint8List.view(
              characters.cast<Uint8>().asTypedList(length).buffer, 0, length);
          final output = utf8.decoder.convert(charList);

          responseStreamController.add(LLMResult(
              id: '$idPrefix.$tokenCount',
              output: output,
              finishReason: FinishReason.unspecified,
              metadata: {
                'message.id': idPrefix,
                'chunk.id': tokenCount,
                'message.type': 'token'
              },
              usage: const LanguageModelUsage(),
              streaming: true));
        } on Error catch (ex, st) {
          if (kDebugMode) {
            print('ont tr: ${ex.stackTrace}');
          }
        }
        if (kDebugMode) {
          print('ont.fmt.ex:>');
        }
      } finally {
        tokenCount++;
        lcpp_free_text(response);
      }
    }

    if (streaming) {
      nativeNewTokenCallable =
          NativeCallable<LppTokenStreamCallbackFunction>.listener(
        onNewTokenCallback,
      );

      nativeNewTokenCallable!.keepIsolateAlive = false;

      lcpp_set_token_stream_callback(nativeNewTokenCallable!.nativeFunction);
    }

    LLMResult result;

    NativeCallable<LppChatMessageCallbackFunction>? chatMessageCallable;
    final completer = Completer();

    void chatMessageCallback(Pointer<lcpp_common_chat_msg_t> message) {
      try {
        final Map<String, dynamic> metadata = Map<String, dynamic>();
        metadata['message.id'] = idPrefix;
        metadata['message.type'] = 'response';

        final output = message.ref.n_content > 0
            ? message.ref.content
                .cast<ffi.Utf8>()
                .toDartString(length: message.ref.n_content)
            : '';
        if (message.ref.n_role > 0) {
          metadata['role'] = message.ref.role
              .cast<ffi.Utf8>()
              .toDartString(length: message.ref.n_role);
        }

        if (message.ref.n_reasoning_content > 0) {
          try {
            metadata['reasoning_content'] = message.ref.reasoning_content
                .cast<ffi.Utf8>()
                .toDartString(length: message.ref.n_reasoning_content);
          } on FormatException catch (e) {
            if (kDebugMode) {
              print('reasoning.fmt.ex: ${e.message}');
            }
          }
        }

        if (message.ref.n_tool_name > 0) {
          try {
            metadata['tool_name'] = message.ref.tool_name
                .cast<ffi.Utf8>()
                .toDartString(length: message.ref.n_tool_name);
          } on FormatException catch (e) {
            if (kDebugMode) {
              print('tool_name.fmt.ex: ${e.message}');
            }
          }
        }

        if (message.ref.n_tool_call_id > 0) {
          try {
            metadata['tool_call_id'] = message.ref.tool_call_id
                .cast<ffi.Utf8>()
                .toDartString(length: message.ref.n_tool_call_id);
          } on FormatException catch (e) {
            if (kDebugMode) {
              print('tool_id.fmt.ex: ${e.message}');
            }
          }
        }

        List<Map<String, String>> content_parts =
            List<Map<String, String>>.empty(growable: true);
        if (message.ref.n_content_parts > 0) {
          final contentPartsPtr = message.ref.content_parts;
          for (int i = 0; i < message.ref.n_content_parts; i++) {
            try {
              Map<String, String> _current = {};
              final it = contentPartsPtr + i;
              if (it.value.ref.n_text > 0) {
                _current['text'] = it.value.ref.text
                    .cast<ffi.Utf8>()
                    .toDartString(length: it.value.ref.n_text);
              }
              if (it.value.ref.n_type > 0) {
                _current['type'] = it.value.ref.type
                    .cast<ffi.Utf8>()
                    .toDartString(length: it.value.ref.n_type);
              }
              if (_current.isNotEmpty) {
                content_parts.add(_current);
              }
            } on FormatException catch (e) {
              if (kDebugMode) {
                print('content_p.fmt.ex: ${e.message}');
              }
            }
          }
        }

        if (content_parts.isNotEmpty) {
          metadata['content_parts'] = content_parts;
        }

        List<Map<String, String>> tool_calls =
            List<Map<String, String>>.empty(growable: true);
        if (message.ref.n_tool_calls > 0) {
          final tool_calls_ptr = message.ref.tool_calls;
          for (int i = 0; i < message.ref.n_tool_calls; i++) {
            try {
              Map<String, String> _current = {};
              final it = tool_calls_ptr + i;
              if (it.value.ref.n_name > 0) {
                _current['name'] = it.value.ref.name
                    .cast<ffi.Utf8>()
                    .toDartString(length: it.value.ref.n_name);
              }
              if (it.value.ref.n_id > 0) {
                _current['id'] = it.value.ref.id
                    .cast<ffi.Utf8>()
                    .toDartString(length: it.value.ref.n_id);
              }
              if (it.value.ref.n_arguments > 0) {
                _current['arguments'] = JsonEncoder().convert(it
                    .value.ref.arguments
                    .cast<ffi.Utf8>()
                    .toDartString(length: it.value.ref.n_arguments));
              }
              if (_current.isNotEmpty) {
                tool_calls.add(_current);
              }
            } on FormatException catch (e) {
              if (kDebugMode) {
                print('tool_calls.fmt.ex: ${e.message}');
              }
            }
          }
        }
        if (tool_calls.isNotEmpty) {
          metadata['tool_calls'] = JsonEncoder().convert(tool_calls);
        }

        result = LLMResult(
            id: idPrefix,
            output: output,
            finishReason: tool_calls.isNotEmpty
                ? FinishReason.toolCalls
                : FinishReason.stop,
            metadata: metadata,
            usage: const LanguageModelUsage(),
            streaming: false);
        responseStreamController.add(result);
        completer.complete();
      } on FormatException catch (e) {
          // eat exceptions
      } finally {
        if (chatMessageCallable != null) {
          chatMessageCallable!.close();
          lcpp_unset_chat_message_callback();
          chatMessageCallable = null;
        }
        lcpp_free_common_chat_msg(message);
        responseStreamController.close();
        if (kDebugMode) {
          print('chatMessageCallable::>');
        }
      }
    }

    chatMessageCallable =
        NativeCallable<LppChatMessageCallbackFunction>.listener(
      chatMessageCallback,
    );

    lcpp_set_chat_message_callback(chatMessageCallable!.nativeFunction);

    lcpp_prompt(commonChatMessages, chatMessages.length);

    /// Stream of token responses.
    yield* responseStreamController.stream.map((response){
      if (response.finishReason == FinishReason.stop ||
          response.finishReason == FinishReason.toolCalls) {
        if (kDebugMode) {
          print('LlamaCpp::isCompleted response');
        }
        _responseController.add(response);
      }
      return response;
    });

    commonChatMessages.free(chatMessages.length);
    if (kDebugMode) {
      print('LlamaCpp::prompt:>');
    }
  }

  void stop() {
    if (kDebugMode) {
      print('LlamaCpp::stop()');
    }
    lcpp_send_abort_signal(true);
    if (kDebugMode) {
      print('LlamaCpp::stop:>');
    }
  }

  void cancel() {
    if (kDebugMode) {
      print('LlamaCpp::cancel()');
    }
    lcpp_send_cancel_signal(true);
    if (kDebugMode) {
      print('LlamaCpp::cancel:>');
    }
  }

  String detokenize(List<int> tokens, bool special) {
    final input = ffi.malloc<Int>(tokens.length);
    for (int index = 0; index < tokens.length; index++) {
      input[index] = tokens[index];
    }

    final result = ffi.malloc<lcpp_data_pvalue>();

    lcpp_detokenize(input, tokens.length, special, result);

    final text = result.ref.found
        ? result.ref.value.cast<ffi.Utf8>().toDartString()
        : '';

    if (result.ref.found) {
      lcpp_native_free(result.ref.value.cast<Void>());
    }

    ffi.malloc.free(input);
    ffi.malloc.free(result);
    return text;
  }

  List<int> tokenize(String text) {
    final input = text.toNativeUtf8();

    final tokens = ffi.malloc<Pointer<llama_token>>();
    int nTokens =
    lcpp_tokenize(input.cast<Char>(), input.length, true, true, tokens);

    final result = nTokens > 0
        ? tokens.value.asTypedList(nTokens).toList(growable: false)
        : List<int>.empty(growable: false);
    ffi.malloc.free(tokens);
    ffi.calloc.free(input);
    return result;
  }

  void reset() {
    if (kDebugMode) {
      print('LlamaCpp::reset()');
    }
    lcpp_reset();
    if (kDebugMode) {
      print('LlamaCpp::reset:>');
    }
  }

  void destroy() {
    lcpp_destroy();
  }
}
