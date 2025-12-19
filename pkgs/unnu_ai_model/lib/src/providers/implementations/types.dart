import 'package:langchain/langchain.dart';

class LcppOptions extends ChatModelOptions {
  const LcppOptions({
    super.model,
    super.tools,
    super.toolChoice,
    super.concurrencyLimit,
    this.streaming = true,
  });
  final bool streaming;

  @override
  LcppOptions copyWith({
    final String? model,
    final List<ToolSpec>? tools,
    final ChatToolChoice? toolChoice,
    final int? concurrencyLimit,
    final bool? defaultIsStreaming,
  }) {
    return LcppOptions(
      model: model ?? this.model,
      toolChoice: toolChoice ?? this.toolChoice,
      tools: tools ?? this.tools,
      concurrencyLimit: concurrencyLimit ?? this.concurrencyLimit,
      streaming: defaultIsStreaming ?? true,
    );
  }

  @override
  LcppOptions merge(covariant LcppOptions? other) {
    return copyWith(
      model: other?.model,
      toolChoice: other?.toolChoice,
      tools: other?.tools,
      concurrencyLimit: other?.concurrencyLimit,
      defaultIsStreaming: other?.streaming,
    );
  }
}