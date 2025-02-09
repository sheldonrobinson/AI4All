import 'dart:async';

import 'package:collection/collection.dart';
import 'package:june/june.dart';
import 'package:unnu_sap/unnu_asr.dart';
import 'package:unnu_sap/unnu_tts.dart';
import 'package:unnu_shared/unnu_shared.dart';

import 'config.dart';

enum InteractiveMode {
  Live(0),
  OnDemand(1),
  Text(2);

  final int value;
  const InteractiveMode(this.value);
  static InteractiveMode fromValue(int value) => switch (value) {
    0 => Live,
    1 => OnDemand,
    2 => Text,
    _ => throw ArgumentError('Unknown value for InteractiveMode: $value'),
  };
}

typedef NoiseLevel = ({double amplitude, double speed});

typedef SpeechWidgetSettings = ({bool hasMicrophone, bool hasSpeaker});

typedef InteractivitySettings = ({InteractiveMode mode, bool mute});

class OnlineAsrConfigModel {
  VadModelConfig vad;
  OnlineRecognizerConfig recognizer;
  OnlinePunctuationConfig punctuation;

  OnlineAsrConfigModel({
    required this.vad,
    required this.recognizer,
    required this.punctuation,
  });

  OnlineAsrConfigModel copyWith({
    VadModelConfig? vad,
    OnlineRecognizerConfig? recognizer,
    OnlinePunctuationConfig? punctuation,
  }) {
    return OnlineAsrConfigModel(
      vad: vad ?? this.vad,
      recognizer: recognizer ?? this.recognizer,
      punctuation: punctuation ?? this.punctuation,
    );
  }

  static OnlineAsrConfigModel getDefaults() {
    final modelConfig = OnlineModelConfig(
      transducer: OnlineTransducerModelConfig(),
      paraformer: OnlineParaformerModelConfig(),
      zipformer2Ctc: OnlineZipformer2CtcModelConfig(),
      tokens: '',
      numThreads: 1,
      provider: 'cpu',
      debug: false,
      modelType: '',
      modelingUnit: '',
      bpeVocab: '',
    );
    final vadConfig = VadModelConfig(
      sileroVad: SileroVadModelConfig(),
      sampleRate: 16000,
      numThreads: 1,
      provider: 'cpu',
      debug: false,
    );
    final recognizerConfig = getOnlineRecognizerConfig(modelConfig);

    final punctuationConfig = OnlinePunctuationConfig(
      model: OnlinePunctuationModelConfig(
        cnnBiLstm: '',
        bpeVocab: '',
        numThreads: 1,
        provider: 'cpu',
        debug: false,
      ),
    );

    return OnlineAsrConfigModel(
      vad: vadConfig,
      recognizer: recognizerConfig,
      punctuation: punctuationConfig,
    );
  }

  @override
  String toString() =>
      'OnlineAsrConfigModel(vad: $vad, recognizer: $recognizer, punctuation: $punctuation)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OnlineAsrConfigModel &&
        other.vad == vad &&
        other.recognizer == recognizer &&
        other.punctuation == punctuation;
  }

  @override
  int get hashCode => vad.hashCode ^ recognizer.hashCode ^ punctuation.hashCode;
}

class OnlineAsrController extends JuneState {
  OnlineAsrConfigModel config = OnlineAsrConfigModel.getDefaults();

  void reconfigure() {
    UnnuAsr.destroy();
    UnnuAsr.configure(config.recognizer, config.vad, config.punctuation);
  }

  void onLocale(String shortLocale) {
    switch (shortLocale) {
      case 'en':
      case 'de':
      case 'es':
      case 'fr':
      case 'pt':
      case 'it':
        UnnuAsr.instance.punctuated = true;
        break;
      default:
        UnnuAsr.instance.punctuated = false;
        break;
    }
  }
}

class OfflineTtsConfigModel {
  OfflineTtsModelConfig model;
  String ruleFst;
  String ruleFars;
  String locale;
  int maxNumSentences;
  double silenceScale;
  Map<String, Voice> panel;
  bool isMultilingual;
  bool isMultiSpeaker;
  Dialoguizer dialoguizer;

  OfflineTtsConfigModel({
    required this.model,
    required this.ruleFst,
    required this.ruleFars,
    this.locale = '',
    this.maxNumSentences = 1,
    this.silenceScale = 0.2,
    this.panel = const <String, Voice>{},
    this.isMultilingual = false,
    this.isMultiSpeaker = false,
    required this.dialoguizer,
  });

  OfflineTtsConfigModel copyWith({
    OfflineTtsModelConfig? model,
    String? ruleFst,
    String? ruleFars,
    String? locale,
    int? maxNumSentences,
    double? silenceScale,
    Map<String, Voice>? panel,
    bool? isMultilingual,
    bool? isMultiSpeaker,

    Dialoguizer? dialoguizer,
  }) {
    return OfflineTtsConfigModel(
      model: model ?? this.model,
      ruleFst: ruleFst ?? this.ruleFst,
      ruleFars: ruleFars ?? this.ruleFars,
      locale: locale ?? this.locale,
      maxNumSentences: maxNumSentences ?? this.maxNumSentences,
      silenceScale: silenceScale ?? this.silenceScale,
      panel: panel ?? this.panel,
      isMultilingual: isMultilingual ?? this.isMultilingual,
      isMultiSpeaker: isMultiSpeaker ?? this.isMultiSpeaker,
      dialoguizer: dialoguizer ?? this.dialoguizer,
    );
  }

  static OfflineTtsConfigModel getDefaults() {
    final matcha = OfflineTtsMatchaModelConfig();
    final kokoro = OfflineTtsKokoroModelConfig();
    final vits = OfflineTtsVitsModelConfig();
    final offlineTts = OfflineTtsModelConfig(
      vits: vits,
      kokoro: kokoro,
      matcha: matcha,
      numThreads: 2,
      provider: 'cpu',
      debug: false,
    );

    return OfflineTtsConfigModel(
      model: offlineTts,
      ruleFars: '',
      ruleFst: '',
      locale: '',
      maxNumSentences: 1,
      silenceScale: 0.2,
      panel: <String, Voice>{},
      isMultilingual: false,
      isMultiSpeaker: false,
      dialoguizer: Dialoguizer(separators: RegExp(''), reasoning: false),
    );
  }

  @override
  String toString() {
    return 'OfflineTtsConfigModel(model: $model, ruleFst: $ruleFst, ruleFars: $ruleFars, locale: $locale, maxNumSentences: $maxNumSentences, silenceScale: $silenceScale, panel: $panel, isMultilingual: $isMultilingual, isMultiSpeaker: $isMultiSpeaker, dialoguizer: $dialoguizer)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is OfflineTtsConfigModel &&
        other.model == model &&
        other.ruleFst == ruleFst &&
        other.ruleFars == ruleFars &&
        other.locale == locale &&
        other.maxNumSentences == maxNumSentences &&
        other.silenceScale == silenceScale &&
        mapEquals(other.panel, panel) &&
        other.isMultilingual == isMultilingual &&
        other.isMultiSpeaker == isMultiSpeaker &&
        other.dialoguizer == dialoguizer;
  }

  @override
  int get hashCode {
    return model.hashCode ^
        ruleFst.hashCode ^
        ruleFars.hashCode ^
        locale.hashCode ^
        maxNumSentences.hashCode ^
        silenceScale.hashCode ^
        panel.hashCode ^
        isMultilingual.hashCode ^
        isMultiSpeaker.hashCode ^
        dialoguizer.hashCode;
  }
}

class OfflineTtsController extends JuneState {
  OfflineTtsConfigModel config = OfflineTtsConfigModel.getDefaults();
  StreamSubscription<List<Oratory>> speaking = Stream<List<Oratory>>.empty(broadcast: true).listen((event) {});
  // StreamSink<String> get TextToSpeak => textInput.sink;

  void reconfigure() {
    UnnuTts.destroy();
    UnnuTts.configure(
      OfflineTtsConfig(
        model: config.model,
        silenceScale: config.silenceScale,
        maxNumSenetences: config.maxNumSentences,
        ruleFars: config.ruleFars,
        ruleFsts: config.ruleFst,
      ),
    );

    setState();
  }

  static Pattern sentenceSeparator(String lang) {
    final parts = lang.split('_');
    switch (parts.first) {
      case 'en':
      case 'es':
      case 'fr':
      case 'de':
      case 'pt':
      case 'it':
      case 'nl':
        return RegExp(
          r'[.!?]+\s+',
          caseSensitive: false,
          multiLine: true,
          unicode: true,
        );
      default:
        return RegExp(
          r'\s+',
          caseSensitive: false,
          multiLine: true,
          unicode: true,
        );
    }
  }

  void onLocale(String shortLocale) {
    Map<String, Voice> speakers = <String, Voice>{};
    speakers.addEntries(config.panel.entries);
    speakers['default'] = forLocale(shortLocale, config.isMultiSpeaker);

    config = config.copyWith(panel: speakers, locale: shortLocale);
    setState();
  }

  static Voice forLocale(String shortLocale, bool isMultiSpeaker) {
    final parts = shortLocale.split('_');
    switch (parts.first) {
      case 'en':
        return isMultiSpeaker
            ? parts.last.toLowerCase() == 'gb'
                ? (sid: 2, speed: 1.0)
                : (sid: 1, speed: 1.0)
            : (sid: 0, speed: 1.0);
      case 'zh':
        return isMultiSpeaker ? (sid: 6, speed: 1.0) : (sid: 0, speed: 1.0);
      case 'de':
      case 'es':
      case 'fr':
      case 'pt':
      case 'it':
      default:
        return (sid: 0, speed: 1.0);
    }
  }

  void speak(Oratory speech) {
    final voice = config.panel['default'] ?? (sid: 0, speed: 1.0);
    UnnuTts.instance.speak(speech.text, voice.sid, voice.speed);
  }

  void subscribe(Stream<String> speech) async {
    await speaking.cancel();
    speaking = speech
         .transform(
       StreamTransformer<String, List<Oratory>>.fromHandlers(
         handleData: (data, sink) {
           // Add your transformation logic here
           if (data.isNotEmpty) {
             final oratory = config.dialoguizer.process(data);
             oratory.removeWhere(
                   (element) =>
               element.type != ResponseSegmentType.Answer ||
                   element.text.isEmpty,
             );

             if (oratory.isNotEmpty) {
               sink.add(oratory);
             }
           } else {
             final value = config.dialoguizer.reset();
             if (value.type == ResponseSegmentType.Answer &&
                 value.text.isNotEmpty) {
               sink.add([value]);
             }
           }
         },
       ),
     ).listen((value) {
       for (final text in value) {
         speak(text);
       }
     });
     setState();
  }
}

class SpeechUIConfigModel {
  bool isMicrophoneMuted;
  bool isSpeakerMuted;
  StreamSubscription<bool> voiceActivityDetected;
  StreamSubscription<bool> speechEvent;
  SpeechUIConfigModel({
    required this.isMicrophoneMuted,
    required this.isSpeakerMuted,
    required this.voiceActivityDetected,
    required this.speechEvent,
  });

  SpeechUIConfigModel copyWith({
    bool? isMicrophoneMuted,
    bool? isSpeakerMuted,
    StreamSubscription<bool>? voiceActivityDetected,
    StreamSubscription<bool>? speechEvent,
  }) {
    return SpeechUIConfigModel(
      isMicrophoneMuted: isMicrophoneMuted ?? this.isMicrophoneMuted,
      isSpeakerMuted: isSpeakerMuted ?? this.isSpeakerMuted,
      voiceActivityDetected:
          voiceActivityDetected ?? this.voiceActivityDetected,
      speechEvent: speechEvent ?? this.speechEvent,
    );
  }

  static SpeechUIConfigModel getDefaults() {
    return SpeechUIConfigModel(
      isMicrophoneMuted: true,
      isSpeakerMuted: false,
      voiceActivityDetected: Stream<bool>.empty(
        broadcast: false,
      ).listen((data) {}),
      speechEvent: Stream<bool>.empty(broadcast: false).listen((data) {}),
    );
  }

  @override
  String toString() {
    return 'SpeechUIConfigModel(micMute: $isMicrophoneMuted, speakerMute: $isSpeakerMuted, voiceActivityDetected: $voiceActivityDetected, speechEvent: $speechEvent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SpeechUIConfigModel &&
        other.isMicrophoneMuted == isMicrophoneMuted &&
        other.isSpeakerMuted == isSpeakerMuted &&
        other.voiceActivityDetected == voiceActivityDetected &&
        other.speechEvent == speechEvent;
  }

  @override
  int get hashCode {
    return isMicrophoneMuted.hashCode ^
        isSpeakerMuted.hashCode ^
        voiceActivityDetected.hashCode ^
        speechEvent.hashCode;
  }
}

class SpeechUIController extends JuneState {
  SpeechUIConfigModel config = SpeechUIConfigModel.getDefaults();

  void muteMic(bool value) {
    config = config.copyWith(isMicrophoneMuted: value);
  }

  void muteSpeaker(bool value) {
    config = config.copyWith(isSpeakerMuted: value);
  }
}
