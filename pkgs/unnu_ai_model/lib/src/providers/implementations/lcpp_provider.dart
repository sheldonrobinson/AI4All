import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';
import 'package:june/june.dart';
import 'package:langchain/langchain.dart';
import 'package:lcpp_ngin/lcpp_ngin.dart' as lcpp;
import 'package:remove_emoji/remove_emoji.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:unnu_shared/unnu_shared.dart';

import 'types.dart';

final thinkingSpan = RegExp(
  '^<think>(.*)</think>',
  multiLine: true,
  dotAll: true,
);

final removeEmoji = RemoveEmoji();

class ProviderChannel<T> with StreamChannelMixin<T> {
  final controller = StreamController<T>();

  @override
  StreamSink<T> get sink => controller.sink;

  @override
  Stream<T> get stream => controller.stream;
}

/// A back-and-forth chat with a generative model.
///
/// Records messages sent and received in [history]. The history will always
/// record the content from the first candidate in the
/// [GenerateContentResponse], other candidates may be available on the returned
/// response.
///
///
final class LlamaCppProvider extends BaseChatModel<LcppOptions> {
  LlamaCppProvider({
    lcpp.ContextParams? contextParams,
    lcpp.LlamaCppParams? lcppParams,
    super.defaultOptions = const LcppOptions(),
  }) : _model = lcpp.LlamaCpp(
         contextParams: contextParams ?? lcpp.ContextParams.defaultParams(),
         lcppParams: lcppParams ?? lcpp.LlamaCppParams.defaultParams(),
       );
  final lcpp.LlamaCpp _model;
  final Map<String, Tool> _tools = <String, Tool>{};

  final SamplerChainSettingsController _samplerChain = June.getState(
    SamplerChainSettingsController.new,
  );

  final _sampling_defaults = lcpp.LlamaCppSamplingParams.defaultParams();

  StreamController<ChatResult>? _responseStreamController;
  Future<void> setup({List<Tool> tools = const <Tool>[]}) async {
    if (tools.isNotEmpty) {
      _tools.addEntries(
        tools.map((element) => MapEntry(element.name, element)),
      );
    } else {
      _tools.clear();
    }

    if (!(_responseStreamController?.isClosed ?? true)) {
      await _responseStreamController?.close();
    }
    _responseStreamController = StreamController<ChatResult>(sync: true);
  }

  Stream<ChatResult> get responses => _model.responses;

  final ProviderChannel<ChatResult> channel = ProviderChannel<ChatResult>();

  Future<void> teardown() async {
    if (!(_responseStreamController?.isClosed ?? true)) {
      await _responseStreamController?.close();
    }
    _responseStreamController = null;
    _tools.clear();
  }

  Stream<ChatResult> get chat =>
      _responseStreamController?.stream ?? const Stream<ChatResult>.empty();

  Stream<ChatResult> generateStream(
    PromptValue prompt, {
    LcppOptions? options,
  }) async* {
    final settings = _samplerChain.settings;
    final params = _sampling_defaults.copyWith(
      topK: settings.core.topK,
      topP: settings.core.topP,
      temperature: settings.core.temperature,
      minP: settings.core.minP,
      typicalP: settings.core.typicalP,
      minKeep: settings.core.minKeep,
      seed: settings.core.seed,
      mirostat: settings.mirostat.mode.value,
      mirostatEta: settings.mirostat.eta,
      mirostatTau: settings.mirostat.tau,
      dryBase: settings.dry.base,
      dryMultiplier: settings.dry.multiplier,
      dryAllowedLength: settings.dry.allowedLength,
      dryPenaltyLastN: settings.dry.penaltyLastN,
      penaltyFrequency: settings.penalty.frequency,
      penaltyPresent: settings.penalty.presence,
      penaltyLastN: settings.penalty.lastN,
      penaltyRepeat: settings.penalty.repeat,
      xtcThreshold: settings.xtc.threshold,
      xtcProbability: settings.xtc.probability,
      topNsigma: settings.topNSigma.topNSigma,
      samplers:
          settings.disabled
              ? <int>[
                lcpp
                    .lcpp_common_sampler_type
                    .LCPP_COMMON_SAMPLER_TYPE_NONE
                    .value,
              ]
              : <int>[
                if (settings.withPenalty)
                  lcpp
                      .lcpp_common_sampler_type
                      .LCPP_COMMON_SAMPLER_TYPE_PENALTIES
                      .value,
                if (settings.withDRY)
                  lcpp
                      .lcpp_common_sampler_type
                      .LCPP_COMMON_SAMPLER_TYPE_DRY
                      .value,
                if (settings.withTopNSigma)
                  lcpp
                      .lcpp_common_sampler_type
                      .LCPP_COMMON_SAMPLER_TYPE_TOP_N_SIGMA
                      .value,
                lcpp
                    .lcpp_common_sampler_type
                    .LCPP_COMMON_SAMPLER_TYPE_TOP_K
                    .value,
                lcpp
                    .lcpp_common_sampler_type
                    .LCPP_COMMON_SAMPLER_TYPE_TYPICAL_P
                    .value,
                lcpp
                    .lcpp_common_sampler_type
                    .LCPP_COMMON_SAMPLER_TYPE_TOP_P
                    .value,
                lcpp
                    .lcpp_common_sampler_type
                    .LCPP_COMMON_SAMPLER_TYPE_MIN_P
                    .value,
                if (settings.withXTC)
                  lcpp
                      .lcpp_common_sampler_type
                      .LCPP_COMMON_SAMPLER_TYPE_XTC
                      .value,
                lcpp
                    .lcpp_common_sampler_type
                    .LCPP_COMMON_SAMPLER_TYPE_TEMPERATURE
                    .value,
              ],
    );


    yield* _model
        .prompt(
          params,
          prompt,
          streaming: options?.streaming ?? true,
          tools: _tools.values.toList(growable: false),
        )
        .tap(_responseStreamController?.add);
  }

  void reset() {
    _model.reset();
    unawaited(teardown());
  }

  @override
  Stream<ChatResult> stream(PromptValue input, {LcppOptions? options}) async* {
    yield* generateStream(
      input,
      options: options,
    );
  }

  @override
  String get modelType => super.defaultOptions.model ?? '';

  @override
  Future<List<int>> tokenize(
    PromptValue promptValue, {
    ChatModelOptions? options,
  }) {
    return Future.value(_model.tokenize(promptValue.toString()));
  }

  @override
  Future<ChatResult> invoke(PromptValue input, {LcppOptions? options}) async {
    return generateStream(
          input,
          options: options,
        )
        .firstWhere(
          (element) =>
              element.finishReason == FinishReason.toolCalls ||
              element.finishReason == FinishReason.stop,
        )
        .then<ChatResult>(
          (value) => ChatResult(
            usage: value.usage,
            metadata: {
              ...value.metadata,
              if (value.output.content.startsWith('<think>'))
                'reasoning_content':
                    thinkingSpan
                        .matchAsPrefix(value.output.content)
                        ?.group(1) ??
                    value.output.content.substring(7),
            },
            output: AIChatMessage(
              content:
                  value.output.content
                      .replaceFirst(thinkingSpan, '')
                      .removEmojiNoTrim,
              toolCalls: value.output.toolCalls,
            ),
            finishReason: value.finishReason,
            id: value.id,
            streaming: value.streaming,
          ),
          onError:
              (err, StackTrace st) => debugPrintStack(
                stackTrace: st,
                label: err.toString(),
              ),
        );
  }

  Stream<double> reconfigure() async* {
    yield* _model.reconfigure();
  }

  void stop() {
    _model.stop();
  }

  void cancel() {
    _model.cancel();
  }

  void destroy() {
    _model.destroy();
  }

  @override
  void close() {
    _model.destroy();
  }
}
