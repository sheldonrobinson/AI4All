import 'dart:async';

import 'package:langchain/langchain.dart';
import 'package:llamacpp/llamacpp.dart' as lcpp;

class LcppOptions extends LLMOptions {
  const LcppOptions({
    super.model,
    super.concurrencyLimit,
    this.defaultIsStreaming = true,
  });
  final bool defaultIsStreaming;

  @override
  LcppOptions copyWith({
    final String? model,
    final int? concurrencyLimit,
    final bool? defaultIsStreaming,
  }) {
    return LcppOptions(
      model: model ?? this.model,
      concurrencyLimit: concurrencyLimit ?? this.concurrencyLimit,
      defaultIsStreaming: defaultIsStreaming ?? true,
    );
  }

  @override
  LcppOptions merge(covariant final LcppOptions? other) {
    return copyWith(
      model: other?.model,
      concurrencyLimit: other?.concurrencyLimit,
    );
  }
}

/// A back-and-forth chat with a generative model.
///
/// Records messages sent and received in [history]. The history will always
/// record the content from the first candidate in the
/// [GenerateContentResponse], other candidates may be available on the returned
/// response.
///
///
final class LlamaCppProvider extends BaseLLM<LcppOptions> {
  LlamaCppProvider({
    lcpp.ContextParams? contextParams,
    lcpp.LlamaCppParams? lcppParams,
    super.defaultOptions = const LcppOptions(model: 'unspecified'),
    lcpp.LlamaCppSamplingParams? samplingParams,
  }) : this.model = lcpp.LlamaCpp(
         contextParams: contextParams ?? lcpp.ContextParams.defaultParams(),
         lcppParams: lcppParams ?? lcpp.LlamaCppParams.defaultParams(),
       ),
       this.samplingParams = samplingParams ?? lcpp.LlamaCppSamplingParams();
  lcpp.LlamaCpp model;

  lcpp.LlamaCppSamplingParams samplingParams;

  Stream<LLMResult> get responseStream => model.responses;

  Stream<double> init() async* {
    yield* this.model.reconfigure();
  }

  void update(lcpp.LlamaCppSamplingParams sampling) {
    samplingParams = sampling;
  }

  Stream<LLMResult> generateStream(
    PromptValue prompt, {
    bool streaming = true,
  }) async* {
    final response = model.prompt(samplingParams, prompt, streaming: streaming);
    yield* response;
  }

  void reset() {
    model.reset();
  }

  @override
  Stream<LLMResult> stream(PromptValue input, {LLMOptions? options}) async* {
    final response = generateStream(input);
    yield* response;
  }

  @override
  String get modelType => super.defaultOptions.model ?? '';

  @override
  Future<List<int>> tokenize(PromptValue promptValue, {LLMOptions? options}) {
    return Future.value(model.tokenize(promptValue.toString()));
  }

  @override
  Future<LLMResult> invoke(PromptValue input, {LcppOptions? options}) async {
    return generateStream(input, streaming: false).first;
  }
}
