part of '../unnu_ai_model.dart';

/// A back-and-forth chat with a generative model.
///
/// Records messages sent and received in [history]. The history will always
/// record the content from the first candidate in the
/// [LLMResult], other candidates may be available on the returned
/// response.
final class ChatSession {
  final Future<LLMResult> Function(
    ChatPromptValue content, {
    LLMOptions? generationConfig,
  })
  GenerateContent;
  final Stream<LLMResult> Function(
    ChatPromptValue content, {
    LLMOptions? generationConfig,
  })
  GenerateContentStream;

  final _mutex = Mutex();

  final List<cm.ChatMessage> _history;
  final LLMOptions? _generationConfig;

  ChatSession._(
    this.GenerateContent,
    this.GenerateContentStream,
    this._history,
    this._generationConfig,
  );

  /// The content that has been successfully sent to, or received from, the
  /// generative model.
  ///
  /// If there are outstanding requests from calls to [sendMessage] or
  /// [sendMessageStream], these will not be reflected in the history.
  /// Messages without a candidate in the response are not recorded in history,
  /// including the message sent to the model.
  Iterable<cm.ChatMessage> get history => _history.skip(0);

  void rewrite(Iterable<cm.ChatMessage> messages) async {
    final lock = await _mutex.acquire();
    try {
      _history.clear();
      _history.addAll(messages);
    }finally{
      if(lock != null){
        lock.release();
      }
    }
  }

  /// Sends [message] to the model as a continuation of the chat [history].
  ///
  /// Prepends the history to the request and uses the provided model to
  /// generate new content.
  ///
  /// When there are no candidates in the response, the [message] and response
  /// are ignored and will not be recorded in the [history].
  ///
  /// Waits for any ongoing or pending requests to [sendMessage] or
  /// [sendMessageStream] to complete before generating new content.
  /// Successful messages and responses for ongoing or pending requests will
  /// be reflected in the history sent for this message.
  Future<LLMResult> sendMessage(cm.ChatMessage message) async {
    if (kDebugMode) {
      print('ChatSession::sndMsg($message)');
    }
    final lock = await _mutex.acquire();
    try {
      final response = await GenerateContent(
        ChatPromptValue(_history.followedBy([message]).toList(growable: false)),
        generationConfig: _generationConfig,
      );
      _history.add(message);
      _history.add(cm.ChatMessage.ai(response.output));
      if (kDebugMode) {
        print('ChatSession::sndMsg:=> $response');
      }
      return response;
    } finally {
      if(lock != null){
        lock.release();
      }

    }
  }

  /// Continues the chat with a new [message].
  ///
  /// Sends [message] to the model as a continuation of the chat [history] and
  /// reads the response in a stream.
  /// Prepends the history to the request and uses the provided model to
  /// generate new content.
  ///
  /// When there are no candidates in any response in the stream, the [message]
  /// and responses are ignored and will not be recorded in the [history].
  ///
  /// Waits for any ongoing or pending requests to [sendMessage] or
  /// [sendMessageStream] to complete before generating new content.
  /// Successful messages and responses for ongoing or pending requests will
  /// be reflected in the history sent for this message.
  ///
  /// Waits to read the entire streamed response before recording the message
  /// and response and allowing pending messages to be sent.
  Stream<LLMResult> sendMessageStream(cm.ChatMessage message) async* {
    if (kDebugMode) {
      print('ChatSession::sendMessageStream()');
    }
    try {
      final responses = GenerateContentStream(
        ChatPromptValue(_history.followedBy([message]).toList(growable: false)),
        generationConfig: _generationConfig,
      );
      LLMResult fullResponse = LLMResult(
        id: '',
        output: '',
        finishReason: FinishReason.unspecified,
        metadata: {},
        usage: LanguageModelUsage(),
      );
      yield* responses.map((response) {
        if (response.finishReason == FinishReason.stop ||
            response.finishReason == FinishReason.toolCalls) {
          fullResponse = response;
        }
        return response;
      });

      _history.add(message);
      List<cm.AIChatMessageToolCall> tools =
          List<cm.AIChatMessageToolCall>.empty(growable: false);
      if (fullResponse.metadata['tool_calls'] != null) {
        List<Map<String, String>> toolCalls = JsonDecoder().convert(
          fullResponse.metadata['tool_calls'],
        );
        tools =
            toolCalls
                .map<cm.AIChatMessageToolCall>(
                  (value) => cm.AIChatMessageToolCall(
                    id: value['id'] ?? '<unspecified>',
                    name: value['name'] ?? '<unspecified>',
                    arguments:
                        value['arguments'] != null
                            ? JsonDecoder().convert(value['arguments']!)
                            : {},
                    argumentsRaw: value['arguments'] ?? '',
                  ),
                )
                .toList();
      }
      final aiMessage = cm.AIChatMessage(
        content: fullResponse.output,
        toolCalls: tools,
      );
      _history.add(aiMessage);
    } catch (e, s) {
      if (kDebugMode) {
        print("Error: $e");
        debugPrintStack(stackTrace: s);
      }
    }
    if (kDebugMode) {
      print('ChatSession::sendMessageStream:=>');
    }
  }

  static ChatSession dummy() {
    return ChatSession._(
      (content, {generationConfig}) => Future<LLMResult>.value(
        LLMResult(
          id: '',
          metadata: {},
          finishReason: FinishReason.unspecified,
          output: '',
          usage: LanguageModelUsage(),
          streaming: false,
        ),
      ),
      (content, {generationConfig}) => Stream<LLMResult>.empty(),
      [],
      LcppOptions(concurrencyLimit: 100, defaultIsStreaming: false),
    );
  }
}

/// Starts a [ChatSession] that will use this model to respond to messages.
///
/// ```dart
/// final chat = model.startChat();
/// final response = await chat.sendMessage(Content.text('Hello there.'));
/// print(response.text);
/// ```
ChatSession _startChat(
  Future<LLMResult> Function(
    ChatPromptValue content, {
    LLMOptions? generationConfig,
  })
  generateContent,
  Stream<LLMResult> Function(
    ChatPromptValue content, {
    LLMOptions? generationConfig,
  })
  generateContentStream, {
  List<cm.ChatMessage>? history,
  LLMOptions? generationConfig,
}) => ChatSession._(
  generateContent,
  generateContentStream,
  history ?? [],
  generationConfig,
);

typedef ChatCallback =
    Future<LLMResult> Function(
      PromptValue prompt, {
      LLMOptions? generationConfig,
    });
typedef StreamingChatCallback =
    Stream<LLMResult> Function(
      PromptValue prompt, {
      LLMOptions? generationConfig,
    });

final class UnnuAIModel with ChangeNotifier {
  final BaseChatMessageHistory chatMessageHistory;
  final BaseLLM model;
  final StreamSink<String>? responseSink;

  UnnuAIModel({
    required this.model,
    BaseChatMessageHistory? chatMessageHistory,
    this.responseSink,

  }) : this.chatMessageHistory =
           chatMessageHistory ??
           ChatMessageHistory(
             messages: List<cm.ChatMessage>.empty(growable: true),
           );

  UnnuAIModel copyWith({
    BaseChatMessageHistory? chatMessageHistory,
    BaseLLM? model,
    StreamSink<String>? responseSink,
    String? modelName,
  }) {
    return UnnuAIModel(
      chatMessageHistory: chatMessageHistory ?? this.chatMessageHistory,
      model: model ?? this.model,
      responseSink: responseSink ?? this.responseSink,
    );
  }

  Stream<LLMResult> prompt(
    List<cm.ChatMessage> request, {
    LLMOptions? options,
  }) async* {
    final messages = await chatMessageHistory.getChatMessages().then(
      (value) => value.followedBy(request),
    );

    String response = '';
    final stream =
        ((options ??
                    LcppOptions(
                      defaultIsStreaming: true,
                      concurrencyLimit: 1000,
                    ))
                as LcppOptions)
            .defaultIsStreaming;
    if (stream) {
      yield* model
          .stream(ChatPromptValue(messages.toList(growable: false)))
          .map((result) {
            if (result.streaming) {
              response += result.output;
              responseSink?.add(result.output);
            }
            return result;
          });
    } else {
      yield* model
          .invoke(ChatPromptValue(messages.toList(growable: false)))
          .asStream()
          .map((result) {
            response += result.output;
            responseSink?.add(result.output);

            return result;
          });
    }

    responseSink?.add(''); //send empty string to flush Dialoguizer
    cm.ChatMessage llmMessage = cm.ChatMessage.ai(response);
    if (kDebugMode) {
      print('prompt:response $llmMessage');
    }

    for (final message in request) {
      await chatMessageHistory.addChatMessage(message);
    }
    await chatMessageHistory.addChatMessage(llmMessage);

    if (kDebugMode) {
      print('UnnuAIModel::prompt:>');
    }
  }

  ChatSession getChatSession({
    List<cm.ChatMessage>? history,
    LLMOptions? generationConfig,
  }) {
    if (kDebugMode) {
      print('UnnuAIModel::getChatSession()');
    }
    return _startChat(
      _content,
      _streaming,
      history: history ?? [],
      generationConfig: generationConfig,
    );
  }

  Future<LLMResult> _content(
    PromptValue contents, {
    LLMOptions? generationConfig,
  }) async {
    if (kDebugMode) {
      print('UnnuAIModel::_transcription()');
    }
    LcppOptions options = LcppOptions(
      model: model.modelType,
      concurrencyLimit:
          generationConfig?.concurrencyLimit ??
          model.defaultOptions.concurrencyLimit,
      defaultIsStreaming: false,
    );

    prompt(contents.toChatMessages(), options: options);

    return await prompt(contents.toChatMessages()).reduce((
      LLMResult prev,
      LLMResult curr,
    ) {
      return prev.concat(curr);
    });
  }

  Stream<LLMResult> _streaming(
    PromptValue contents, {
    LLMOptions? generationConfig,
  }) async* {
    if (kDebugMode) {
      print('UnnuAIModel::_streaming()');
    }

    LcppOptions options = LcppOptions(
      model: model.modelType,
      concurrencyLimit:
          generationConfig?.concurrencyLimit ??
          model.defaultOptions.concurrencyLimit,
      defaultIsStreaming: true,
    );

    yield* prompt(contents.toChatMessages(), options: options);

    if (kDebugMode) {
      print('UnnuAIModel::_streaming:>');
    }
  }

  set history(List<cm.ChatMessage> messages) {
    chatMessageHistory.clear();
    for (final msg in messages) {
      chatMessageHistory.addChatMessage(msg);
    }
    notifyListeners();
  }

  Future<List<cm.ChatMessage>> get messages async {
    return await chatMessageHistory.getChatMessages();
  }

  Future<void> reset() async {
    if (model is LlamaCppProvider) {
      (model as LlamaCppProvider).reset();
    }
    await chatMessageHistory.clear();
  }
}
