import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ai_glow/ai_glow.dart';
import 'package:asset_cache/asset_cache.dart';
import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:card_settings_ui/tile/settings_tile_info.dart';
import 'package:disclosure/disclosure.dart';
import 'package:feedback_gitlab/feedback_gitlab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:hold_to_confirm_button/hold_to_confirm_button.dart';
import 'package:june/june.dart';
import 'package:langchain/langchain.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:readmore_expandable_text/readmore_expandable_text.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:unnu_ai_model/unnu_ai_model.dart';
import 'package:unnu_common/unnu_common.dart';
import 'package:unnu_know/unnu_know.dart';
import 'package:unnu_sap/unnu_asr.dart';
import 'package:unnu_sap/unnu_tts.dart';
import 'package:unnu_shared/unnu_shared.dart';
import 'package:unnu_speech/unnu_speech.dart';
import 'package:unnu_widgets/unnu_widgets.dart';

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
  models(1, Icons.functions),
  settings(2, Icons.settings);

  final int value;
  final IconData icondata;

  const ApplicationPanel(this.value, this.icondata);

  static ApplicationPanel fromValue(int value) => switch (value) {
    0 => history,
    1 => models,
    2 => settings,
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

class SystemInformation {
  String appName;
  String packageName;
  String version;
  String buildNumber;
  String installerStore;
  int totalPhysicalMemorySize;
  int totalVirtualMemorySize;
  SystemInformation({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.installerStore,
    required this.totalPhysicalMemorySize,
    required this.totalVirtualMemorySize,
  });

  SystemInformation copyWith({
    String? appName,
    String? packageName,
    String? version,
    String? buildNumber,
    String? installerStore,
    int? totalPhysicalMemorySize,
    int? totalVirtualMemorySize,
  }) {
    return SystemInformation(
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      version: version ?? this.version,
      buildNumber: buildNumber ?? this.buildNumber,
      installerStore: installerStore ?? this.installerStore,
      totalPhysicalMemorySize:
          totalPhysicalMemorySize ?? this.totalPhysicalMemorySize,
      totalVirtualMemorySize:
          totalVirtualMemorySize ?? this.totalVirtualMemorySize,
    );
  }

  Map<String, dynamic> toMap() {
    final result =
        <String, dynamic>{}..addAll({
          'appName': appName,
          'packageName': packageName,
          'version': version,
          'buildNumber': buildNumber,
          'installerStore': installerStore,
          'totalPhysicalMemorySize': totalPhysicalMemorySize,
          'totalVirtualMemorySize': totalVirtualMemorySize,
        });

    return result;
  }

  static SystemInformation empty() {
    return SystemInformation(
      appName: '',
      packageName: '',
      version: '',
      buildNumber: '',
      installerStore: '',
      totalPhysicalMemorySize: 0,
      totalVirtualMemorySize: 0,
    );
  }

  factory SystemInformation.fromMap(Map<String, dynamic> map) {
    return SystemInformation(
      appName: (map['appName'] ?? '') as String,
      packageName: (map['packageName'] ?? '') as String,
      version: (map['version'] ?? '') as String,
      buildNumber: (map['buildNumber'] ?? '') as String,
      installerStore: (map['installerStore'] ?? '') as String,
      totalPhysicalMemorySize: (map['totalPhysicalMemorySize'] ?? 0) as int,
      totalVirtualMemorySize: (map['totalVirtualMemorySize'] ?? 0) as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory SystemInformation.fromJson(String source) =>
      SystemInformation.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'SystemInformation(appName: $appName, packageName: $packageName, version: $version, buildNumber: $buildNumber, installerStore: $installerStore, totalPhysicalMemorySize: $totalPhysicalMemorySize, totalVirtualMemorySize: $totalVirtualMemorySize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SystemInformation &&
        other.appName == appName &&
        other.packageName == packageName &&
        other.version == version &&
        other.buildNumber == buildNumber &&
        other.installerStore == installerStore &&
        other.totalPhysicalMemorySize == totalPhysicalMemorySize &&
        other.totalVirtualMemorySize == totalVirtualMemorySize;
  }

  @override
  int get hashCode {
    return appName.hashCode ^
        packageName.hashCode ^
        version.hashCode ^
        buildNumber.hashCode ^
        installerStore.hashCode ^
        totalPhysicalMemorySize.hashCode ^
        totalVirtualMemorySize.hashCode;
  }
}

class SystemInformationController extends JuneState {
  SystemInformation info = SystemInformation.empty();

  void fromPackage(PackageInfo packageInfo) {
    info = info.copyWith(
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      installerStore: packageInfo.installerStore,
    );
    setState();
  }

  void fromMemoryInfo({int? PhysicalMemory, int? VirtualMemory}) {
    info = info.copyWith(
      totalPhysicalMemorySize: PhysicalMemory ?? info.totalPhysicalMemorySize,
      totalVirtualMemorySize: VirtualMemory ?? info.totalVirtualMemorySize,
    );
    setState();
  }
}

class ApplicationLayoutModel {
  bool showSecondaryBody;
  bool isSpeaking;
  double bodyRatio;
  ApplicationPanel selectedTabbedPanel;
  String shortLocale;
  Map<String, String> localizations;
  Map<String, String> disclosures;
  ApplicationLayoutModel({
    required this.showSecondaryBody,
    required this.isSpeaking,
    required this.bodyRatio,
    required this.selectedTabbedPanel,
    required this.shortLocale,
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
    Map<String, String>? localizations,
    Map<String, String>? disclosures,
  }) {
    return ApplicationLayoutModel(
      showSecondaryBody: showSecondaryBody ?? this.showSecondaryBody,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      bodyRatio: bodyRatio ?? this.bodyRatio,
      selectedTabbedPanel: selectedTabbedPanel ?? this.selectedTabbedPanel,
      shortLocale: shortLocale ?? this.shortLocale,
      localizations: localizations ?? this.localizations,
      disclosures: disclosures ?? this.disclosures,
    );
  }

  Map<String, dynamic> toMap() {
    final result =
        <String, dynamic>{}..addAll({
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
      showSecondaryBody: (map['showSecondaryBody'] ?? false) as bool,
      isSpeaking: (map['isSpeaking'] ?? false) as bool,
      bodyRatio: (map['bodyRatio']?.toDouble() ?? 0.0) as double,
      selectedTabbedPanel: ApplicationPanel.fromValue(
        map['selectedTabbedPanel'] as int,
      ),
      shortLocale: (map['shortLocale'] ?? '') as String,
      localizations: Map<String, String>.from(
        map['localizations'] as Map<String, String>,
      ),
      disclosures: Map<String, String>.from(
        map['disclosures'] as Map<String, String>,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory ApplicationLayoutModel.fromJson(String source) =>
      ApplicationLayoutModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

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

  final Stream<StreamingTranscript> transcripts = UnnuAsr.instance.transcription
      .transform(
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
              case TranscriptType.CHUNK:
                {
                  sink.add((
                    type: TranscriptionFragmentType.chunk,
                    text: data.text,
                  ));
                }
              case TranscriptType.PARTIAL:
                {
                  sink.add((
                    type: TranscriptionFragmentType.partial,
                    text: data.text,
                  ));
                }
              case TranscriptType.FINAL:
                {
                  sink.add((
                    type: TranscriptionFragmentType.complete,
                    text: data.text,
                  ));
                }
              case TranscriptType.END:
                {
                  sink.add((
                    type: TranscriptionFragmentType.end,
                    text: data.text,
                  ));
                }
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
        ? const SizedBox.shrink()
        : Breakpoints.largeAndUp.isActive(context)
        ? _getSecondaryBody(context)
        : const SizedBox.shrink();
  }

  double get bodyRatio => appConfiguration.bodyRatio;

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

  Future<void> onPrimaryNavigation(BuildContext context, int selected) async {
    final nav = AppPrimaryNavigation.fromValue(selected);
    switch (nav) {
      case AppPrimaryNavigation.NewChat:
        {
          final chatSessionController = June.getState(
            ChatSessionController.new,
          );
          final streamingMessageController = June.getState(
            StreamingMessageController.new,
          );
          await chatSessionController.newChat();
          await streamingMessageController.newChat();
        }
      case AppPrimaryNavigation.SwitchModel:
        {
          final info = await ModelUtils.loadModelFile();
          if (info.uri.isNotEmpty && info.details.info.filePath.isNotEmpty) {
            await ModelUtils.switchModel(info.details);
            final llmProviderController = June.getState(
              LLMProviderController.new,
            );
            llmProviderController.activeModel = llmProviderController
                .activeModel
                .copyWith(uri: info.uri);
          }
        }
      case AppPrimaryNavigation.About:
        _showAboutDialog(context);
      case AppPrimaryNavigation.Feedback:
        {
          final config =
              await jsonAssets.loadAsset(
                    'config.json',
                  )
                  as Map<String, dynamic>;
          if (context.mounted) {
            BetterFeedback.of(context).showAndUploadToGitLab(
              projectId: (config['FEEDBACK_GITLAB_PROJECT'] ?? '') as String,
              // Required, use your GitLab project id
              apiToken: (config['FEEDBACK_GITLAB_TOKEN'] ?? '') as String,
              // Required, use your GitLab API token
              gitlabUrl: 'gitlab.com', // Optional, defaults to 'gitlab.com'
            );
          }
        }
    }
  }

  void onShowTabs(BuildContext context) {
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

  final ({bool hasMicrophone, bool hasSpeaker}) audioInfo = (
    hasMicrophone: UnnuAsr.instance.supported,
    hasSpeaker: UnnuTts.instance.supported,
  );

  Future<List<Document>> _lookup(String query) async {
    final result = await UnnuKnow.instance.search(
      query,
    );
    return result;
  }

  void _onCancelModelResponse() {
    final _ = June.getState(LLMProviderController.new)..stop();
  }

  void switchMode(InteractiveMode mode) {
    switch (mode) {
      case InteractiveMode.Live:
        UnnuTts.instance.enabled = audioInfo.hasSpeaker;
        UnnuAsr.instance.enabled =
            audioInfo.hasMicrophone; //widget.interactivity.value.enabled;
      case InteractiveMode.OnDemand:
        UnnuTts.instance.enabled = audioInfo.hasSpeaker;
        UnnuAsr.instance.enabled = false;
      case InteractiveMode.Text:
        UnnuTts.instance.enabled =
            !audioInfo.hasMicrophone && audioInfo.hasSpeaker;
        UnnuAsr.instance.enabled = false;
    }
    UnnuAsr.instance.muted = mode != InteractiveMode.Live;
  }

  void onMute(bool isMute) {
    if (!audioInfo.hasMicrophone && audioInfo.hasSpeaker) {
      UnnuTts.instance.enabled = !isMute;
    }
    UnnuTts.instance.muted = isMute;
    UnnuAsr.instance.muted = isMute;
  }

  Widget _getBody(BuildContext context) {
    final textTheme = TextTheme.of(context);
    final colorScheme = ColorScheme.of(context);
    final llmProviderController = June.getState(LLMProviderController.new);
    final assistantTheme = textTheme.apply(
      fontFamily: llmProviderController.activeModel.info.modelFamily.text,
    );
    return Container(
      padding: const EdgeInsets.all(4.0),
      alignment: Alignment.topCenter,
      constraints: const BoxConstraints(minWidth: 480, minHeight: 720),
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          SizedBox(
            height: 110,
            child: JuneBuilder(
              ApplicationLayoutModelController.new,
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
                            'unnu™',
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
                            LLMProviderController.new,
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
                      final chatWidgetController = June.getState(
                        ChatWidgetController.new,
                      );
                      if (value) {
                        chatWidgetController.update(
                          status: SendIconState.transcribing,
                        );
                      } else if (chatWidgetController.changeNotifier.status ==
                          SendIconState.transcribing) {
                        chatWidgetController.update(
                          status: SendIconState.idle,
                        );
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
              mimetypes: ['docx', 'pdf'],
              onRetrieve: _lookup,
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
                        border: BoxBorder.all(),
                      ),
                      constraints: const BoxConstraints(minWidth: 200),
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
                          Tab(
                            icon: Icon(ApplicationPanel.settings.icondata),
                            child: Text(
                              appConfiguration.localizations['settings'] ??
                                  'Settings',
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
                          Tab(
                            icon: Icon(ApplicationPanel.settings.icondata),
                            child: Text(
                              appConfiguration.localizations['settings'] ??
                                  'Settings',
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
                  StreamingMessageController.new,
                  builder: (controller) {
                    final layout = June.getState(
                      ApplicationLayoutModelController.new,
                    );
                    layout.appConfiguration = layout.appConfiguration.copyWith(
                      selectedTabbedPanel: ApplicationPanel.history,
                    );
                    final sessions =
                        <String, List<Message>>{}
                          ..addAll(controller.chats)
                          ..putIfAbsent(
                            controller.messagingModel.sessionId,
                            () => <Message>[
                              Message.unsupported(
                                id: '',
                                authorId: '',
                                createdAt: DateTime.now(),
                              ),
                            ],
                          )
                          ..removeWhere(
                            (key, value) => key.isEmpty,
                          );
                    final chats = sessions.entries;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        border: const BoxBorder.symmetric(
                          vertical: BorderSide(width: 0.5),
                        ),
                        color: theme.colorScheme.surface,
                      ),
                      constraints: const BoxConstraints(minWidth: 100),
                      padding: EdgeInsets.zero,
                      height: MediaQuery.sizeOf(context).height,
                      width: MediaQuery.sizeOf(context).width,
                      child: ListView.builder(
                        itemCount: chats.length,
                        prototypeItem: ListTile(
                          onTap: () {},
                          selected: true,
                          title: Badge.count(
                            count: 99,
                            child: Text(
                              timeago.format(
                                DateTime.now()
                                    .subtract(const Duration(days: 396))
                                    .toUtc(),
                                locale: appConfiguration.shortLocale,
                              ),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          subtitle: ReadMoreExpandableText(
                            text:
                                'Lorem ipsum dolor sit amet, consectetur adipiscing elit.\nSed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\nUt enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                            collapseText: '-',
                            expandText: '+',
                            collapseIcon: Icons.arrow_drop_up,
                            expandIcon: Icons.arrow_drop_down,
                            textStyle: theme.textTheme.bodySmall,
                          ),
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final item = chats.elementAt(index);
                          final messageCount =
                              item.value.whereType<TextMessage>().length;
                          final msg = item.value.first;
                          final createdAt = item.value.first.createdAt;
                          final sessionId = item.key;
                          final text = switch (msg) {
                            TextMessage() => msg.text,
                            TextStreamMessage() => '',
                            ImageMessage() => '',
                            FileMessage() => '',
                            VideoMessage() => '',
                            AudioMessage() => '',
                            SystemMessage() => msg.text,
                            CustomMessage() => '',
                            UnsupportedMessage() => '',
                          };
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
                            onTap: () async {
                              final session = June.getState(
                                ChatSessionController.new,
                              );
                              final messaging = June.getState(
                                StreamingMessageController.new,
                              );
                              final settingsController = June.getState(
                                ChatSettingsController.new,
                              );
                              final corpusController = June.getState(
                                UnnuCorpusController.new,
                              );
                              final messages = messaging.chats[sessionId] ?? [];
                              await messaging.loadChat(sessionId);
                              session.loadChat(messages);
                              final setting = settingsController.getSetting(
                                sessionId,
                              );
                              await corpusController.doSwitch(
                                setting.documents
                                    .map((e) => (id: e.id, uri: e.uri))
                                    .toList(),
                              );
                              messaging.setState();
                              session.setState();
                              corpusController.setState();
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
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            subtitle: ReadMoreExpandableText(
                              text: text,
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
                  LLMProviderController.new,
                  builder: (controller) {
                    final models = controller.models;
                    final layout = June.getState(
                      ApplicationLayoutModelController.new,
                    );
                    layout.appConfiguration = layout.appConfiguration.copyWith(
                      selectedTabbedPanel: ApplicationPanel.models,
                    );
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        border: const BoxBorder.symmetric(
                          vertical: BorderSide(width: 0.5),
                        ),
                        color: theme.colorScheme.surface,
                      ),
                      constraints: const BoxConstraints(minWidth: 100),
                      padding: EdgeInsets.zero,
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
                              'Basename of model',
                              style: TextTheme.of(context).titleMedium,
                            ),
                            subtitle: Row(
                              children: <Widget>[
                                const Icon(Icons.calculate),
                                Text(
                                  '99x99B',
                                  style: TextTheme.of(context).labelLarge,
                                ),
                                const Icon(Icons.memory),
                                Text(
                                  '99GB',
                                  style: TextTheme.of(context).labelLarge,
                                ),
                                const Icon(Icons.compress),
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
                              message:
                                  models[index].info.nameInNamingConvention,
                              child: ListTile(
                                enabled:
                                    controller
                                        .activeModel
                                        .info
                                        .nameInNamingConvention !=
                                    models[index].info.nameInNamingConvention,
                                onTap: () async {
                                  await ModelUtils.switchModel(
                                    models[index],
                                  );
                                },
                                selected:
                                    controller
                                        .activeModel
                                        .info
                                        .nameInNamingConvention ==
                                    models[index].info.nameInNamingConvention,
                                selectedTileColor:
                                    ColorScheme.of(context).surfaceDim,
                                title: Text(
                                  models[index].info.nameInNamingConvention,
                                  style: TextTheme.of(context).titleMedium,
                                ),
                                subtitle: Row(
                                  children: <Widget>[
                                    const Icon(Icons.calculate),
                                    Text(
                                      models[index].info.sizeLabel,
                                      style: TextTheme.of(context).labelLarge,
                                    ),
                                    const Icon(Icons.memory),
                                    Text(
                                      models[index].info.vRamAsHumanReadable(),
                                      style: TextTheme.of(context).labelLarge,
                                    ),
                                    const Icon(Icons.compress),
                                    Text(
                                      models[index].info.encoding.isNotEmpty
                                          ? models[index].info.encoding
                                              .toUpperCase()
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
                JuneBuilder(
                  ChatSettingsController.new,
                  builder: (controller) {
                    final messageController = June.getState(
                      StreamingMessageController.new,
                    );
                    final corpusController = June.getState(
                      UnnuCorpusController.new,
                    );
                    return SizedBox(
                      width: MediaQuery.sizeOf(context).width,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SettingsTile<void>.switchTile(
                            title: const Text('RAG'),
                            onToggle: (value) {
                              final setting = controller.getSetting(
                                messageController.sessionId,
                              );
                              final enabled = value ?? !setting.enableSearch;
                              controller.setSearch(
                                setting.chatId,
                                enabled,
                              );
                              setState();
                            },
                            initialValue:
                                controller.settings
                                    .putIfAbsent(
                                      messageController.sessionId,
                                      () => ChatSettings.empty().copyWith(
                                        chatId: messageController.sessionId,
                                        enableSearch: true,
                                      ),
                                    )
                                    .enableSearch,
                            leading: const Icon(
                              Icons.manage_search,
                            ),
                          ),
                          SettingsSection(
                            title: const Text('Attachments'),
                            tiles: [
                              CustomSettingsTile(
                                child:
                                    (SettingsTileInfo info) => Wrap(
                                      spacing:
                                          8.0, // gap between adjacent chips
                                      runSpacing: 4.0, // gap between lines
                                      children: List<Widget>.generate(
                                        controller
                                            .getSetting(
                                              messageController.sessionId,
                                            )
                                            .documents
                                            .length,
                                        (index) {
                                          final val = controller
                                              .getSetting(
                                                messageController.sessionId,
                                              )
                                              .documents
                                              .elementAt(
                                                index,
                                              );
                                          return Tooltip(
                                            message: val.uri.toFilePath(
                                              windows: Platform.isWindows,
                                            ),
                                            child: HoldToConfirmButton(
                                              onProgressCompleted: () {
                                                corpusController.doDelete(
                                                  val.uri.toString(),
                                                );
                                                controller.remove(
                                                  messageController.sessionId,
                                                  val.uri,
                                                );
                                                AttachmentsMonitor.sendStatus((
                                                  status:
                                                      AttachmentStatus.REMOVE,
                                                  attachment: val,
                                                ));
                                              },
                                              hapticFeedback: false,
                                              contentPadding:
                                                  const EdgeInsets.all(
                                                    2,
                                                  ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    20,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.delete,
                                                  ),
                                                  if (p
                                                          .basename(
                                                            val.uri.toFilePath(
                                                              windows:
                                                                  Platform
                                                                      .isWindows,
                                                            ),
                                                          )
                                                          .length >
                                                      24)
                                                    Text(
                                                      p
                                                          .basename(
                                                            val.uri.toFilePath(
                                                              windows:
                                                                  Platform
                                                                      .isWindows,
                                                            ),
                                                          )
                                                          .replaceRange(
                                                            24,
                                                            null,
                                                            '...',
                                                          ),
                                                    )
                                                  else
                                                    Text(
                                                      p.basename(
                                                        val.uri.toFilePath(
                                                          windows:
                                                              Platform
                                                                  .isWindows,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ],
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
    final sysInfo = June.getState(
      SystemInformationController.new,
    );
    final theme = Theme.of(context);
    showAboutDialog(
      context: context,
      applicationName: 'AI4All Core Edition',
      applicationLegalese: '© 2025 Konnek Inc',
      applicationVersion: sysInfo.info.version,
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
