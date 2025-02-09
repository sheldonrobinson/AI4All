import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_glow/ai_glow.dart';
import 'package:asset_cache/asset_cache.dart';
import 'package:disclosure/disclosure.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:june/june.dart';
import 'package:langchain/langchain.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:readmore_expandable_text/readmore_expandable_text.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:unnu_ai_model/unnu_ai_model.dart';
import 'package:unnu_sap/unnu_asr.dart';
import 'package:unnu_sap/unnu_tts.dart';
import 'package:unnu_shared/unnu_shared.dart';
import 'package:unnu_speech/unnu_speech.dart';
import 'package:unnu_widgets/unnu_widgets.dart';
import 'package:feedback_gitlab/feedback_gitlab.dart';

class RAGSettings {
  final String documentsFolder;
  const RAGSettings({required this.documentsFolder});
}

const double LAYOUT_BODYRATIO = 0.7;

final _disclosureKeys = [
  ('disclosure-eula', 'End-User License Agreement'),
  ('disclosure-toc', 'Terms and Conditions'),
  ('disclosure-privacy_policy', 'Privacy Policy'),
  ('disclosure-disclaimer', 'Disclaimer'),
];

enum ApplicationPanel {
  history(0, Icons.history),
  models(1, Icons.functions);

  final int value;
  final IconData icondata;

  const ApplicationPanel(this.value, this.icondata);

  static ApplicationPanel fromValue(int value) => switch (value) {
    0 => history,
    1 => models,
    _ => throw ArgumentError('Unknown value for ApplicationPanel: $value'),
  };
}

enum AppPrimaryNavigation {
  NewChat(0, Icons.chat),
  SwitchModel(1, Icons.file_open),
  About(2, Icons.info),
  Feedback(3, Icons.edit_note);

  final IconData icondata;
  final int value;
  const AppPrimaryNavigation(this.value, this.icondata);

  IconData get icon => icondata;

  static AppPrimaryNavigation fromValue(int value) => switch (value) {
    0 => NewChat,
    1 => SwitchModel,
    2 => About,
    3 => Feedback,
    _ => throw ArgumentError('Unknown value for AppPrimaryNavigation: $value'),
  };
}

/*
class EnvironmentConfig {
  static const FEEDBACK_GITLAB_PROJECT = String.fromEnvironment(
    'FEEDBACK_GITLAB_PROJECT',
  );
  static const FEEDBACK_GITLAB_TOKEN = String.fromEnvironment(
    'FEEDBACK_GITLAB_TOKEN',
  );
}
*/
class ApplicationLayoutModel {
  bool showSecondaryBody;
  bool isSpeaking;
  double bodyRatio;
  ApplicationPanel selectedTabbedPanel;
  String shortLocale;
  //  LlmMetaInfo llmMetaInfo;
  PackageInfo packageInfo;
  Map<String, String> localizations;
  Map<String, String> disclosures;
  ApplicationLayoutModel({
    required this.showSecondaryBody,
    required this.isSpeaking,
    required this.bodyRatio,
    required this.selectedTabbedPanel,
    required this.shortLocale,
    //    required this.llmMetaInfo,
    required this.packageInfo,
    required this.localizations,
    required this.disclosures,
  });

  static ApplicationLayoutModel getDefaults() {
    return ApplicationLayoutModel(
      selectedTabbedPanel: ApplicationPanel.history,
      isSpeaking: false,
      showSecondaryBody: false,
      bodyRatio: 1.0,
      shortLocale: 'en',
      localizations: const <String, String>{},
      disclosures: const <String, String>{},
      packageInfo: PackageInfo(
        appName: 'Unknown',
        packageName: 'Unknown',
        version: 'Unknown',
        buildNumber: 'Unknown',
        buildSignature: 'Unknown',
        installerStore: 'Unknown',
      ),
      //      llmMetaInfo: LlmMetaInfo.empty(),
    );
  }

  ApplicationLayoutModel copyWith({
    bool? showSecondaryBody,
    bool? isSpeaking,
    double? bodyRatio,
    ApplicationPanel? selectedTabbedPanel,
    String? shortLocale,
    Widget? body,
    Widget? secondaryBody,
    //    LlmMetaInfo? llmMetaInfo,
    PackageInfo? packageInfo,
    Map<String, String>? localizations,
    Map<String, String>? disclosures,
  }) {
    return ApplicationLayoutModel(
      showSecondaryBody: showSecondaryBody ?? this.showSecondaryBody,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      bodyRatio: bodyRatio ?? this.bodyRatio,
      selectedTabbedPanel: selectedTabbedPanel ?? this.selectedTabbedPanel,
      shortLocale: shortLocale ?? this.shortLocale,
      //     llmMetaInfo: llmMetaInfo ?? this.llmMetaInfo,
      packageInfo: packageInfo ?? this.packageInfo,
      localizations: localizations ?? this.localizations,
      disclosures: disclosures ?? this.disclosures,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({
      'showSecondaryBody': showSecondaryBody,
      'isSpeaking': isSpeaking,
      'bodyRatio': bodyRatio,
      'selectedTabbedPanel': selectedTabbedPanel.value,
      'shortLocale': shortLocale,
      'localizations': localizations,
      'disclosures': disclosures,
    });

    return result;
  }

  factory ApplicationLayoutModel.fromMap(Map<String, dynamic> map) {
    return ApplicationLayoutModel(
      showSecondaryBody: map['showSecondaryBody'] ?? false,
      isSpeaking: map['isSpeaking'] ?? false,
      bodyRatio: map['bodyRatio']?.toDouble() ?? 0.0,
      selectedTabbedPanel: ApplicationPanel.fromValue(
        map['selectedTabbedPanel'],
      ),
      shortLocale: map['shortLocale'] ?? '',
      //     llmMetaInfo: LlmMetaInfo.fromMap(map['llmMetaInfo']),
      packageInfo: PackageInfo(
        appName: 'Unknown',
        packageName: 'Unknown',
        version: 'Unknown',
        buildNumber: 'Unknown',
        buildSignature: 'Unknown',
        installerStore: 'Unknown',
      ),
      localizations: Map<String, String>.from(map['localizations']),
      disclosures: Map<String, String>.from(map['disclosures']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ApplicationLayoutModel.fromJson(String source) =>
      ApplicationLayoutModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'ApplicationLayoutModel(showSecondaryBody: $showSecondaryBody, bodyRatio: $bodyRatio, selectedTabbedPanel: $selectedTabbedPanel, shortLocale: $shortLocale)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ApplicationLayoutModel &&
        other.showSecondaryBody == showSecondaryBody &&
        other.isSpeaking == isSpeaking &&
        other.bodyRatio == bodyRatio &&
        other.selectedTabbedPanel == selectedTabbedPanel &&
        other.shortLocale == shortLocale;
  }

  @override
  int get hashCode {
    return showSecondaryBody.hashCode ^
        isSpeaking.hashCode ^
        bodyRatio.hashCode ^
        selectedTabbedPanel.hashCode ^
        shortLocale.hashCode;
  }
}

class ApplicationLayoutModelController extends JuneState {
  // Initialize transition time variable.
  static final _nudgeTimeoutInMillisecond = 2000;

  static final List<Color> _colorsIOS = [
    Color(0xFFD166D3),
    Color(0xFFF7BF69),
    Color(0xFFE2A0CB),
    Color(0xFFC982F7),
    Color(0xFFC580F3),
    Color(0xFFF1BFEB),
    Color(0xFF939AF9),
    Color(0xFFA97DF5),
  ];

  final transcripts = UnnuAsr.instance.transcription.transform(
    StreamTransformer<Transcript, StreamingTranscript>.fromHandlers(
      handleData: (data, sink) {
        switch (data.type) {
          case TranscriptType.START:
            {
              sink.add((
                type: TranscriptionFragmentType.start,
                text: data.text,
              ));
            }
            break;
          case TranscriptType.CHUNK:
            {
              sink.add((
                type: TranscriptionFragmentType.chunk,
                text: data.text,
              ));
            }
            break;
          case TranscriptType.PARTIAL:
            {
              sink.add((
                type: TranscriptionFragmentType.partial,
                text: data.text,
              ));
            }
            break;
          case TranscriptType.FINAL:
            {
              sink.add((
                type: TranscriptionFragmentType.complete,
                text: data.text,
              ));
            }
            break;
          case TranscriptType.END:
            {
              sink.add((type: TranscriptionFragmentType.end, text: data.text));
            }
            break;
        }
      },
    ),
  );

  final jsonAssets = JsonAssetCache(
    assetBundle: rootBundle,
    basePath: 'assets/json/',
  );

  ApplicationLayoutModel appConfiguration =
      ApplicationLayoutModel.getDefaults();

  bool get showSecondary => appConfiguration.showSecondaryBody;

  bool get isSpeaking => appConfiguration.isSpeaking;

  Widget body(BuildContext context) {
    return Breakpoints.largeAndUp.isActive(context)
        ? _getBody(context)
        : showSecondary
        ? _getSecondaryBody(context)
        : _getBody(context);
  }

  Widget secondaryBody(BuildContext context) {
    return !showSecondary
        ? SizedBox.shrink()
        : Breakpoints.largeAndUp.isActive(context)
        ? _getSecondaryBody(context)
        : SizedBox.shrink();
  }

  double get bodyRatio => appConfiguration.bodyRatio;

  void onInitPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    appConfiguration = appConfiguration.copyWith(packageInfo: info);
  }

  void onInitDisclosures() async {
    final textAssetList = TextAssetCache(basePath: 'assets/resources/');

    final disclosures = <String, String>{};

    await textAssetList.preload([
      'privacy_policy.md',
      'toc.md',
      'eula.md',
      'disclaimer.md',
    ]);

    disclosures['End-User License Agreement'] = await textAssetList.loadAsset(
      'eula.md',
    );
    disclosures['Terms and Conditions'] = await textAssetList.loadAsset(
      'toc.md',
    );
    disclosures['Privacy Policy'] = await textAssetList.loadAsset(
      'privacy_policy.md',
    );
    disclosures['Disclaimer'] = await textAssetList.loadAsset('disclaimer.md');

    appConfiguration = appConfiguration.copyWith(disclosures: disclosures);
  }

  void onInitAudio() async {
    UnnuTts.instance.speakingEvents.listen((event) {
      appConfiguration = appConfiguration.copyWith(isSpeaking: event);
    });
  }

  void onL10nUpdate(Map<String, String> l10n) {
    appConfiguration = appConfiguration.copyWith(localizations: l10n);
  }

  void onLocale(String shortLocale) {
    switch (shortLocale) {
      case 'fr':
        {
          timeago.setLocaleMessages(shortLocale, timeago.FrMessages());
        }
        break;
      case 'es':
        {
          timeago.setLocaleMessages(shortLocale, timeago.EsMessages());
        }
        break;
      case 'pt':
        {
          timeago.setLocaleMessages(shortLocale, timeago.PtBrMessages());
        }
        break;
      case 'zh':
        {
          timeago.setLocaleMessages(shortLocale, timeago.ZhMessages());
        }
        break;
      default:
        timeago.setLocaleMessages(shortLocale, timeago.EnMessages());
    }

    appConfiguration = appConfiguration.copyWith(shortLocale: shortLocale);
  }

  Future<void> configureModel(
    LlmMetaInfo info, {
    StreamSink<double>? callback,
  }) {
    final llmProviderController = June.getState(() => LLMProviderController());
    final progress = llmProviderController.switchModel(info);

    final reasoningCtx = info.reasoningContext;

    final segmenter = Dialoguizer(
      separators: RegExp(
        r'[.!?]+\s+',
        caseSensitive: false,
        multiLine: true,
        unicode: true,
      ),
      reasoning: reasoningCtx.reasoning,
      thinking: (
        start_tag: reasoningCtx.startTag ?? '<think>',
        end_tag: reasoningCtx.endTag ?? '</think>',
      ),
    );

    final offlineTtsController = June.getState(() => OfflineTtsController());

    offlineTtsController.config = offlineTtsController.config.copyWith(
      dialoguizer: segmenter,
    );
    offlineTtsController.setState();
    final tts = StreamController<String>(sync: true);
    offlineTtsController.subscribe(tts.stream);

    final completer = Completer<void>();
    progress.listen(
      (data) {
        if (kDebugMode) {
          print('SwitchModel:_llmController.progress($data)');
        }
        if (callback != null) {
          callback.add(data);
        }
      },
      onDone: () async {
        if (kDebugMode) {
          print('SwitchModel:_llmController.progress.onDone');
        }
        final chatSessionController = June.getState(
          () => ChatSessionController(),
        );
        final streamingMessageController = June.getState(
          () => StreamingMessageController(),
        );
        final messages =
            streamingMessageController.messages
                .whereType<TextMessage>()
                .map(
                  (message) =>
                      message.authorId == Avatars.User.id
                          ? ChatMessage.humanText(message.text)
                          : message.authorId == Avatars.Assistant.id
                          ? ChatMessage.ai(message.text)
                          : ChatMessage.system(message.text),
                )
                .toList();

        final aI = UnnuAIModel(
          model: llmProviderController.activeModel.llm,
          chatMessageHistory: ChatMessageHistory(messages: messages),
          responseSink: tts.sink,
        );

        streamingMessageController.messagingModel = streamingMessageController
            .messagingModel
            .copyWith(
              parser: segmenter,
              assistant: llmProviderController.responses.listen((onData) {}),
            );
        streamingMessageController.resubscribe();
        streamingMessageController.setState();

        chatSessionController.chatSessionVM = chatSessionController
            .chatSessionVM
            .copyWith(
              ai: aI,
              activeSession: aI.getChatSession(history: messages),
            );

        chatSessionController.setState();
        llmProviderController.setState();
        completer.complete();
      },
    );
    return completer.future;
  }

  Future<LlmMetaInfo?> loadModelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['gguf'],
      lockParentWindow: true,
    );
    if (result != null) {
      // All files
      File file = File(result.files.single.path!);
      return LLMProviderController.asLlMetaInfo(
        file.path,
        resource: LlmResource.LocalFile,
      );
    }
    return null;
  }

  void switchModel(LlmMetaInfo info) async {
    {
      final chatWidgetController = June.getState(() => ChatWidgetController());
      chatWidgetController.viewModel = chatWidgetController.viewModel.copyWith(
        status: SendIconState.loading,
        nonblocking: false,
      );
      chatWidgetController.setState();
    }

    if (kDebugMode) {
      print('SwitchModel()');
    }

    await configureModel(info);
    setState();

    {
      final chatWidgetController = June.getState(() => ChatWidgetController());
      chatWidgetController.viewModel = chatWidgetController.viewModel.copyWith(
        status: SendIconState.idle,
        nonblocking: true,
      );
      chatWidgetController.setState();
    }

    if (kDebugMode) {
      print('SwitchModel:>');
    }
  }

  Future<void> onPrimaryNavigation(BuildContext context, int selected) async {
    final nav = AppPrimaryNavigation.fromValue(selected);
    switch (nav) {
      case AppPrimaryNavigation.NewChat:
        {
          final chatSessionController = June.getState(
            () => ChatSessionController(),
          );
          final streamingMessageController = June.getState(
            () => StreamingMessageController(),
          );
          chatSessionController.newChat();
          streamingMessageController.newChat();
        }
        break;
      case AppPrimaryNavigation.SwitchModel:
        {
          LlmMetaInfo? info = await loadModelFile();
          if (info != null) {
            switchModel(info);
          }
        }
        break;
      case AppPrimaryNavigation.About:
        _showAboutDialog(context);
        break;
      case AppPrimaryNavigation.Feedback:
        {
          final Map<String, dynamic> config = await jsonAssets.loadAsset(
            'config.json',
          );
          BetterFeedback.of(context).showAndUploadToGitLab(
            projectId: config['FEEDBACK_GITLAB_PROJECT'] ?? '',
            // Required, use your GitLab project id
            apiToken: config['FEEDBACK_GITLAB_TOKEN'] ?? '',
            // Required, use your GitLab API token
            gitlabUrl: 'gitlab.com', // Optional, defaults to 'gitlab.com'
          );
        }
        break;
    }
  }

  void onShowTabs(BuildContext context) {
    if (kDebugMode) {
      print('onSecondaryNavigation');
    }
    final toggle = !appConfiguration.showSecondaryBody;
    appConfiguration = appConfiguration.copyWith(
      showSecondaryBody: toggle,
      bodyRatio:
          Breakpoints.largeAndUp.isActive(context)
              ? 1.0
              : toggle
              ? LAYOUT_BODYRATIO
              : 1.0,
    );
    setState();
  }

  void _onSwitchModel() async {
    final info = await loadModelFile();
    if (info != null) {
      switchModel(info);
    }
  }

  final audioInfo = (
    hasMicrophone: UnnuAsr.instance.supported,
    hasSpeaker: UnnuTts.instance.supported,
  );

  void _onCancelModelResponse() {
    final llmProviderController = June.getState(() => LLMProviderController());
    llmProviderController.stop();
  }

  void switchMode(InteractiveMode mode) {
    if (kDebugMode) {
      print('MyHomePageState::switchMode(${mode.name})');
    }
    switch (mode) {
      case InteractiveMode.Live:
        UnnuTts.instance.enabled = audioInfo.hasSpeaker;
        UnnuAsr.instance.enabled =
            audioInfo.hasMicrophone; //widget.interactivity.value.enabled;
        break;
      case InteractiveMode.OnDemand:
        UnnuTts.instance.enabled = audioInfo.hasSpeaker;
        UnnuAsr.instance.enabled = false;
        break;
      case InteractiveMode.Text:
        UnnuTts.instance.enabled =
            !audioInfo.hasMicrophone && audioInfo.hasSpeaker ? true : false;
        UnnuAsr.instance.enabled = false;
        break;
    }
    UnnuAsr.instance.muted = mode != InteractiveMode.Live;
    if (kDebugMode) {
      print('MyHomePageState::switchMode:>');
    }
  }

  void onMute(bool isMute) {
    if (kDebugMode) {
      print('MyHomePageState::onMute($isMute)');
    }
    if (!audioInfo.hasMicrophone && audioInfo.hasSpeaker) {
      UnnuTts.instance.enabled = !isMute;
    }
    UnnuTts.instance.muted = isMute;
    UnnuAsr.instance.muted = isMute;
    if (kDebugMode) {
      print('MyHomePageState::onMute:>');
    }
  }

  Widget _getBody(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final colorScheme = ColorScheme.of(context);
    final llmProviderController = June.getState(() => LLMProviderController());
    final assistantTheme = textTheme.apply(
      fontFamily: llmProviderController.activeModel.info.modelFamily.text,
    );
    return Container(
      padding: const EdgeInsets.all(4.0),
      alignment: Alignment.topCenter,
      constraints: BoxConstraints(minWidth: 480, minHeight: 720),
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          SizedBox(
            height: 110,
            child: JuneBuilder(
              () => ApplicationLayoutModelController(),
              builder: (layout) {
                return OuterAiGlow(
                  width: MediaQuery.sizeOf(context).width,
                  height: MediaQuery.sizeOf(context).height,
                  borderRadius: 0.0,
                  glowWidth: layout.isSpeaking ? 8.0 : 0,
                  blure: layout.isSpeaking ? 4.0 : 0.0,
                  colors: _colorsIOS,
                  child: UnnuSpeechWidget(
                    chyron: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 10,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(2.0),
                          height: 60.0,
                          alignment: Alignment.center,
                          child: Text(
                            'unnu',
                            style: textTheme.headlineMedium?.copyWith(
                              fontFamily: 'Audex',
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4.0),
                          alignment: Alignment.center,
                          child: Text(
                            '⨁',
                            style: textTheme.headlineSmall?.copyWith(
                              fontFamily: 'Noto Sans Mono',
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2.0),
                          height: 60,
                          alignment: Alignment.center,
                          child: JuneBuilder(
                            () => LLMProviderController(),
                            builder: (controller) {
                              final modelFamily =
                                  controller.activeModel.info.modelFamily;
                              return Tooltip(
                                message:
                                    controller
                                        .activeModel
                                        .info
                                        .nameInNamingConvention,
                                child: Text(
                                  modelFamily.familyName,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontFamily: modelFamily.logo,
                                    fontStyle: modelFamily.style,
                                    fontWeight: modelFamily.weight,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    noise: UnnuAsr.instance.soundEvents,
                    eavesdropping: UnnuAsr.instance.nowListening.tap((value) {
                      if (kDebugMode) {
                        print('nowListening.tap($value)');
                      }
                      final chatWidgetController = June.getState(
                        () => ChatWidgetController(),
                      );
                      if (value) {
                        chatWidgetController.viewModel = chatWidgetController
                            .viewModel
                            .copyWith(status: SendIconState.transcribing);
                        chatWidgetController.setState();
                      } else {
                        if (chatWidgetController.viewModel.status ==
                            SendIconState.transcribing) {
                          chatWidgetController.viewModel = chatWidgetController
                              .viewModel
                              .copyWith(status: SendIconState.idle);
                          chatWidgetController.setState();
                        }
                      }
                    }),
                    onModeChange: switchMode,
                    onMute: onMute,
                    onNudge: () => UnnuAsr.nudge(_nudgeTimeoutInMillisecond),
                    settings: audioInfo,
                    tooltips: appConfiguration.localizations,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: UnnuChatWidget(
              transcriptions: transcripts,
              AssistantTheme: assistantTheme,
              tooltips: appConfiguration.localizations,
              onCancelModelResponse: _onCancelModelResponse,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSecondaryBody(BuildContext context) {
    final theme = Theme.of(context);
    final tabsInHeader = Breakpoints.largeAndUp.isActive(context);

    return appConfiguration.showSecondaryBody
        ? DefaultTabController(
          length: ApplicationPanel.values.length,
          initialIndex: appConfiguration.selectedTabbedPanel.value,
          child: Scaffold(
            backgroundColor: theme.colorScheme.surface,
            bottomNavigationBar:
                !tabsInHeader
                    ? Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        border: BoxBorder.all(width: 1.0),
                      ),
                      constraints: BoxConstraints(minWidth: 200),
                      child: TabBar(
                        dividerColor: theme.colorScheme.primary,
                        tabs: [
                          Tab(
                            icon: Icon(ApplicationPanel.history.icondata),
                            child: Text(
                              appConfiguration.localizations['history'] ??
                                  'History',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Tab(
                            icon: Icon(ApplicationPanel.models.icondata),
                            child: Text(
                              appConfiguration.localizations['models'] ??
                                  'Models',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                    )
                    : null,
            appBar: AppBar(
              bottom:
                  tabsInHeader
                      ? TabBar(
                        dividerColor: theme.colorScheme.primary,
                        tabs: [
                          Tab(
                            icon: Icon(ApplicationPanel.history.icondata),
                            child: Text(
                              appConfiguration.localizations['history'] ??
                                  'History',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Tab(
                            icon: Icon(ApplicationPanel.models.icondata),
                            child: Text(
                              appConfiguration.localizations['models'] ??
                                  'Models',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ],
                      )
                      : null,
            ),
            body: TabBarView(
              children: [
                JuneBuilder(
                  () => StreamingMessageController(),
                  builder: (controller) {
                    final layout = June.getState(
                      () => ApplicationLayoutModelController(),
                    );
                    layout.appConfiguration = layout.appConfiguration.copyWith(
                      selectedTabbedPanel: ApplicationPanel.history,
                    );
                    final chats = controller.chats.entries.indexed;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        border: BoxBorder.symmetric(
                          vertical: BorderSide(width: 0.5),
                        ),
                        color: theme.colorScheme.surface,
                      ),
                      constraints: BoxConstraints(minWidth: 100),
                      padding: EdgeInsets.all(0.0),
                      height: MediaQuery.sizeOf(context).height - 24,
                      width: MediaQuery.sizeOf(context).width,
                      child: ListView.builder(
                        itemCount: chats.length,
                        prototypeItem: ListTile(
                          enabled: true,
                          onTap: () {},
                          selected: true,
                          title: Badge.count(
                            count: 99,
                            child: Text(
                              timeago.format(
                                DateTime.now().toUtc(),
                                locale: appConfiguration.shortLocale,
                              ),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),

                          subtitle: ReadMoreExpandableText(
                            text:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                            maxLines: 3,
                            collapseText: '',
                            expandText: '',
                            textStyle: theme.textTheme.bodySmall,
                          ),
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final item = chats.elementAt(index);
                          final messageCount = item.$2.value.length;
                          final msg = item.$2.value.first;
                          final createdAt = item.$2.value.first.createdAt;
                          final sessionId = item.$2.key;
                          String text = '';
                          switch (msg) {
                            case TextMessage():
                              {
                                text = msg.text;
                              }
                              break;
                            case TextStreamMessage():
                            case ImageMessage():
                            case FileMessage():
                            case VideoMessage():
                            case AudioMessage():
                            case SystemMessage():
                            case CustomMessage():
                            case UnsupportedMessage():
                              break;
                          }
                          return ListTile(
                            style:
                                theme.listTileTheme
                                    .copyWith(
                                      tileColor: theme.colorScheme.surface,
                                    )
                                    .style,
                            enabled:
                                sessionId !=
                                controller.messagingModel.sessionId,
                            selectedColor: ColorScheme.of(context).surfaceDim,
                            onTap: () {
                              final session = June.getState(
                                () => ChatSessionController(),
                              );
                              final messaging = June.getState(
                                () => StreamingMessageController(),
                              );
                              final messages = messaging.chats[sessionId] ?? [];
                              messaging.loadChat(sessionId);
                              session.loadChat(messages);
                            },
                            selected:
                                sessionId ==
                                controller.messagingModel.sessionId,
                            title: Badge.count(
                              count: (messageCount / 2).toInt(),
                              child: Text(
                                timeago.format(
                                  createdAt!,
                                  locale: appConfiguration.shortLocale,
                                ),
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            subtitle: ReadMoreExpandableText(
                              text: text,
                              maxLines: 3,
                              collapseText: '-',
                              expandText: '+',
                              collapseIcon: Icons.arrow_drop_up,
                              expandIcon: Icons.arrow_drop_down,
                              textStyle: theme.textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                JuneBuilder(
                  () => LLMProviderController(),
                  builder: (controller) {
                    final models = controller.models;
                    final layout = June.getState(
                      () => ApplicationLayoutModelController(),
                    );
                    layout.appConfiguration = layout.appConfiguration.copyWith(
                      selectedTabbedPanel: ApplicationPanel.models,
                    );
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        border: BoxBorder.symmetric(
                          vertical: BorderSide(width: 0.5),
                        ),
                        color: theme.colorScheme.surface,
                      ),
                      constraints: BoxConstraints(minWidth: 100),
                      padding: EdgeInsets.all(0.0),
                      height: MediaQuery.sizeOf(context).height - 24,
                      width: MediaQuery.sizeOf(context).width,
                      child: ListView.builder(
                        itemCount: models.length,
                        prototypeItem: Tooltip(
                          message: 'Name following convention',
                          child: ListTile(
                            enabled: true,
                            onTap: () {},
                            selected: true,
                            title: Text(
                              "Basename of model",
                              style: TextTheme.of(context).titleMedium,
                            ),
                            subtitle: Row(
                              children: <Widget>[
                                Icon(Icons.calculate),
                                Text(
                                  '99x99B',
                                  style: TextTheme.of(context).labelLarge,
                                ),
                                Icon(Icons.memory),
                                Text(
                                  '99GB',
                                  style: TextTheme.of(context).labelLarge,
                                ),
                                Icon(Icons.compress),
                                Text(
                                  'Q4_K_M',
                                  style: TextTheme.of(context).labelLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                        itemBuilder:
                            (BuildContext context, int index) => Tooltip(
                              message: models[index].nameInNamingConvention,
                              child: ListTile(
                                enabled:
                                    controller
                                        .activeModel
                                        .info
                                        .nameInNamingConvention !=
                                    models[index].nameInNamingConvention,
                                onTap: () async {
                                  if (kDebugMode) {
                                    print(
                                      'Models.Tab onTap: switch to model ${models[index]}',
                                    );
                                  }
                                  final appLayoutController = June.getState(
                                    () => ApplicationLayoutModelController(),
                                  );
                                  appLayoutController.switchModel(
                                    models[index],
                                  );
                                },
                                selected:
                                    controller
                                        .activeModel
                                        .info
                                        .nameInNamingConvention ==
                                    models[index].nameInNamingConvention,
                                selectedTileColor: ColorScheme.of(context).surfaceDim,
                                title: Text(
                                  models[index].baseName,
                                  style: TextTheme.of(context).titleMedium,
                                ),
                                subtitle: Row(
                                  children: <Widget>[
                                    Icon(Icons.calculate),
                                    Text(
                                      models[index].sizeLabel,
                                      style: TextTheme.of(context).labelLarge,
                                    ),
                                    Icon(Icons.memory),
                                    Text(
                                      models[index].vRamAsHumanReadable(),
                                      style: TextTheme.of(context).labelLarge,
                                    ),
                                    Icon(Icons.compress),
                                    Text(
                                      models[index].encoding.isNotEmpty
                                          ? models[index].encoding.toUpperCase()
                                          : '_',
                                      style: TextTheme.of(context).labelLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        )
        : const SizedBox.shrink();
  }

  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    showAboutDialog(
      context: context,
      applicationName: 'AI4All Core Edition',
      applicationLegalese: '© 2025 Konnek Inc',
      applicationVersion: appConfiguration.packageInfo.version,
      children: [
        DisclosureGroup(
          multiple: false,
          clearable: true,
          insets: const EdgeInsets.all(15),
          children: <Disclosure>[
            ...List.generate(
              _disclosureKeys.length,
              (idx) => Disclosure(
                key: ValueKey(_disclosureKeys[idx].$1),
                wrapper: (state, child) {
                  return Card.outlined(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color:
                            state.closed ? Colors.black26 : theme.dividerColor,
                        width: state.closed ? 1 : 2,
                      ),
                    ),
                    child: child,
                  );
                },
                header: DisclosureButton(
                  child: ListTile(
                    title: Text(_disclosureKeys[idx].$2),
                    trailing: const DisclosureSwitcher(
                      opened: Icon(Icons.arrow_drop_down_circle),
                      closed: Icon(Icons.arrow_drop_down),
                    ),
                  ),
                ),
                child: GptMarkdown(
                  appConfiguration.disclosures[_disclosureKeys[idx].$2]!,
                ),
              ),
              growable: false,
            ),
          ],
        ),
      ],
    );
  }
}
