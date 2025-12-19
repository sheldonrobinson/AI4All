part of '../unnu_ai_model.dart';

typedef ChatCallback =
    Future<ChatResult> Function(
      PromptValue prompt, {
      ChatModelOptions? generationConfig,
    });
typedef StreamingChatCallback =
    Stream<ChatResult> Function(
      PromptValue prompt, {
      ChatModelOptions? generationConfig,
    });

final class UnnuAIModel with ChangeNotifier {
  UnnuAIModel({
    required this.model,
    required this.memory,
    this.responseSink,
  });
  final BaseChatMemory memory;
  final BaseChatModel model;
  final StreamSink<String>? responseSink;
  final Map<String, Tool> _tools = <String, Tool>{};

  UnnuAIModel copyWith({
    BaseChatMemory? memory,
    BaseChatModel? model,
    StreamSink<String>? responseSink,
  }) {
    return UnnuAIModel(
      memory: memory ?? this.memory,
      model: model ?? this.model,
      responseSink: responseSink ?? this.responseSink,
    );
  }

  ChatModelOptions get options => switch (model.defaultOptions) {
    LcppOptions() => model.defaultOptions.copyWith(
      model: model.modelType,
    ),
    _ => const LcppOptions().copyWith(
      model: model.modelType,
      concurrencyLimit: model.defaultOptions.concurrencyLimit,
      tools: _tools.values.toList(),
      defaultIsStreaming: true,
      toolChoice: _tools.isNotEmpty ? ChatToolChoice.auto : ChatToolChoice.none,
    ),
  };

  ToolsAgent get agent => ToolsAgent.fromLLMAndTools(
    llm: model,
    memory: memory,
    tools: _tools.values.toList(),
  );

  Future<void> setup({List<Tool> tools = const <Tool>[]}) async {
    if (tools.isNotEmpty ){
      _tools.addEntries(
        tools.map((element) => MapEntry(element.name, element)),
      );
    } else {
      _tools.clear();
    }
    if (model is LlamaCppProvider) {
      await (model as LlamaCppProvider).setup(tools: tools);
    }

  }

  Future<void> teardown() async {
    if (model is LlamaCppProvider) {
      await (model as LlamaCppProvider).teardown();
    }
    _tools.clear();
  }

  Stream<ChatResult> get chat =>
      (model is LlamaCppProvider)
          ? (model as LlamaCppProvider).chat.tap(
            (message) => responseSink?.add(
              !(message.finishReason == FinishReason.stop ||
                      message.finishReason == FinishReason.toolCalls)
                  ? message.output.content
                  : '',
            ),
          )
          : const Stream<ChatResult>.empty();

  static ChatMessage transformToRAG(
    ChatMessage message, {
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final data =
        (metadata['rag.data'] ?? const <String, dynamic>{})
            as Map<String, dynamic>;
    final enabled = (metadata['rag.enabled'] ?? false) as bool;
    return switch (message) {
      SystemChatMessage() =>
        enabled && data.isNotEmpty
            ? ChatMessage.system(
              ((data[UnnuQueryFragmentType.CURRENT_INFO.name] ?? '') as String)
                      .trim()
                      .isNotEmpty
                  ? fmt.format(
                    UNNU_RAG_SYSTEM_PROMPT,
                    {
                      ...data,
                      'RANDOM': 'R${const Uuid().v1().replaceAll('-', '')}',
                    },
                  )
                  : (data[UnnuQueryFragmentType.USER_QUERY.name] ?? '')
                      as String,
            )
            : ChatMessage.system('\n\n${message.content}'),
      HumanChatMessage() =>
        enabled && data.isNotEmpty
            ? ChatMessage.humanText(
              ((data[UnnuQueryFragmentType.CURRENT_INFO.name] ?? '') as String)
                      .trim()
                      .isNotEmpty
                  ? fmt.format(
                    UNNU_RAG_COT_PROMPT,
                    {
                      ...data,
                      'RANDOM': 'R${const Uuid().v1().replaceAll('-', '')}',
                    },
                  )
                  : (data[UnnuQueryFragmentType.USER_QUERY.name] ?? '')
                      as String,
            )
            : ChatMessage.humanText('\n\n${message.content}'),
      AIChatMessage() => message,
      ToolChatMessage() => message,
      CustomChatMessage() => message,
    };
  }

  ChatPromptTemplate prompt(String query) {
    model.bind(options);
    final promptTemplate = ChatPromptTemplate.fromTemplates(const []);

    return promptTemplate;
  }

  Future<void> _setHistory(List<ChatMessage> messages) async {
    await memory.clear().whenComplete(
      () => messages.forEach(memory.chatHistory.addChatMessage),
    );
  }

  set history(List<ChatMessage> messages) {
    unawaited(_setHistory(messages).then((value) => notifyListeners()));
  }

  Future<List<ChatMessage>> get messages async {
    return memory.chatHistory.getChatMessages();
  }

  Future<void> reset() async {
    if (model is LlamaCppProvider) {
      (model as LlamaCppProvider).reset();
    }
    await memory.clear();
  }
}
