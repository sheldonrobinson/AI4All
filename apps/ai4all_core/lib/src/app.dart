import 'dart:convert';
import 'dart:core';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unnu_ai_model/unnu_ai_model.dart';
import 'package:unnu_sap/unnu_asr.dart';
import 'package:unnu_sap/unnu_tts.dart';
import 'package:unnu_speech/unnu_speech.dart';
import 'package:june/june.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:unnu_widgets/unnu_widgets.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'generated/i18n/app_localizations.dart';

import 'types.dart';

class MyHomePage extends StatefulWidget {
  /// Creates a const [MyHomePage].
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {

  void _setup() async {
    final llmProviderController = June.getState(
          () => LLMProviderController(),
    );
    final appLayoutController = June.getState(
          () => ApplicationLayoutModelController(),
    );

    appLayoutController.onInitDisclosures();

    appLayoutController.switchModel(
      llmProviderController.activeModel.info,
    );
  }
  @override
  void initState() {
    super.initState();

    _setup();
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

    // Close splash screen after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    UnnuTts.destroy();
    UnnuAsr.destroy();
    final streamingMessageController = June.getState(() => StreamingMessageController());
    streamingMessageController.messagingModel.chatController.dispose();
    streamingMessageController.messagingModel.streamManager.dispose();
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    final llmProviderController = June.getState(() => LLMProviderController());
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString(
      'model.active',
      llmProviderController.activeModel.info.toJson(),
    );

    final listOfModels = jsonEncode(llmProviderController.models);
    prefs.setString('model.registry', listOfModels);

    llmProviderController.llm.close();
    return super.didRequestAppExit();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = TextTheme.of(context).apply(fontFamily: 'Noto Sans');
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple.shade100,
      brightness: Brightness.light,
    );
    final colorSchemeDark = ColorScheme.fromSeed(
      seedColor: Colors.deepPurple.shade900,
      brightness: Brightness.dark,
    );

    final theme = Theme.of(context).copyWith(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryTextTheme: textTheme.apply(
        decorationColor: Colors.black,
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
      textTheme: textTheme.apply(
        decorationColor: Colors.black,
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
    );

    final themeDark = Theme.of(context).copyWith(
      brightness: Brightness.dark,
      colorScheme: colorSchemeDark,
      primaryTextTheme: textTheme.apply(
        decorationColor: Colors.white,
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      textTheme: textTheme.apply(
        decorationColor: Colors.white,
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );

    final offlineTtsController = June.getState(() => OfflineTtsController());

    offlineTtsController.onLocale(Intl.getCurrentLocale());

    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme,
      darkTheme: themeDark,
      themeMode: ThemeMode.system,
      home: JuneBuilder(
        () => ApplicationLayoutModelController(),
        builder: (appLayoutController) {
          final appLocalizations = AppLocalizations.of(context);
          final shortLocale = Intl.shortLocale(
            appLocalizations?.localeName ?? 'en',
          );
          appLayoutController.onLocale(shortLocale);

          final tooltips =
              appLocalizations != null
                  ? <String, String>{
                    'tapToSpeak': appLocalizations.tapToSpeak,
                    'mute': appLocalizations.mute,
                    'unmute': appLocalizations.unmute,
                    'textOnly': appLocalizations.textOnly,
                    'live': appLocalizations.live,
                    'onDemand': appLocalizations.onDemand,
                    'newChat': appLocalizations.newChat,
                    'clearAll': appLocalizations.clearAll,
                    'noMessages': appLocalizations.noMessages,
                    'chatHint': appLocalizations.chatHint,
                    'send': appLocalizations.send,
                    'cancel': appLocalizations.cancel,
                    'stop': appLocalizations.stop,
                    'busy': appLocalizations.busy,
                    'history': appLocalizations.history,
                    'switchModel': appLocalizations.switchModel,
                    'selectFolder': appLocalizations.selectFolder,
                    "noMic": appLocalizations.noMic,
                    "about": appLocalizations.about,
                    "dock": appLocalizations.dock,
                    "feedback": appLocalizations.feedback,
                    "thinking": appLocalizations.thinking,
                  }
                  : <String, String>{};

          appLayoutController.onL10nUpdate(tooltips);
          final destinations = <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.add_circle),
              label: tooltips['newChat'] ?? 'New Chat',
            ),
            NavigationDestination(
              icon: const Icon(Icons.file_open),
              label: tooltips['switchModel'] ?? 'Switch Model',
            ),
            NavigationDestination(
              icon: const Icon(Icons.info),
              label: tooltips['about'] ?? 'About',
            ),
            NavigationDestination(
              icon: const Icon(Icons.feedback),
              label: tooltips['feedback'] ?? 'Feedback',
            ),
          ];

          final railDestinations = destinations
              .map((element) => AdaptiveScaffold.toRailDestination(element))
              .toList(growable: false);
          final colorScheme = ColorScheme.of(context);

          return Container(
            constraints: BoxConstraints(minHeight: 480, minWidth: 360),
            color: colorScheme.surface,
            child: Scaffold(
              backgroundColor: colorScheme.surface,
              appBar: AppBar(
                title: Text(
                  'A\\V',
                  textAlign: TextAlign.center,
                  style: textTheme.displaySmall?.copyWith(
                    fontFamily: 'Horizon',
                    color: colorScheme.primary,
                  ),
                ),
                centerTitle: true,
                actions: <Widget>[
                  IconButton(
                    onPressed: () => appLayoutController.onShowTabs(context),
                    icon: const Icon(Icons.menu),
                    selectedIcon: const Icon(Icons.menu_open),
                    isSelected: appLayoutController.showSecondary,
                    tooltip: tooltips['dock'] ?? 'Dock',
                  ),
                ],
              ),
              body: JuneBuilder(
                () => ApplicationLayoutModelController(),
                builder:
                    (layout) => AdaptiveLayout(
                      bodyRatio:
                          Breakpoints.largeAndUp.isActive(context)
                              ? !layout.showSecondary
                                  ? 1.0
                                  : LAYOUT_BODYRATIO
                              : 1.0,
                      bodyOrientation: Axis.horizontal,
                      primaryNavigation: SlotLayout(
                        config: {
                          Breakpoints.standard: SlotLayout.from(
                            key: const Key('Primary Navigation Standard'),
                            builder: (_) => const SizedBox.shrink(),
                          ),
                          Breakpoints.largeAndUp: SlotLayout.from(
                            key: const Key('Primary Navigation LargeAndUp'),
                            inAnimation: AdaptiveScaffold.stayOnScreen,
                            builder:
                                (context) =>
                                    AdaptiveScaffold.standardNavigationRail(
                                      destinations: railDestinations,
                                      labelType: NavigationRailLabelType.none,
                                      selectedIndex: null,
                                      backgroundColor:
                                          ColorScheme.of(context).surface,
                                      extended: false,
                                      onDestinationSelected:
                                          (selected) =>
                                              layout.onPrimaryNavigation(
                                                context,
                                                selected,
                                              ),
                                    ),
                          ),
                        },
                      ),
                      topNavigation: SlotLayout(
                        config: {
                          Breakpoints.standard: SlotLayout.from(
                            key: const Key('Top Navigation Standard'),
                            inAnimation: AdaptiveScaffold.stayOnScreen,
                            builder:
                                (context) =>
                                    AdaptiveScaffold.standardBottomNavigationBar(
                                      destinations: destinations,
                                      currentIndex: null,
                                      onDestinationSelected:
                                          (selected) =>
                                              layout.onPrimaryNavigation(
                                                context,
                                                selected,
                                              ),
                                    ),
                          ),
                          Breakpoints.largeAndUp: SlotLayout.from(
                            key: const Key('Top Navigation LargeAndUp'),
                            builder: (_) => const SizedBox.shrink(),
                          ),
                        },
                      ),
                      body: SlotLayout(
                        config: {
                          Breakpoints.standard: SlotLayout.from(
                            key: const Key('Body Standard'),
                            builder: (context) => layout.body(context),
                          ),
                        },
                      ),
                      secondaryBody: SlotLayout(
                        config: {
                          Breakpoints.standard: SlotLayout.from(
                            key: const Key('Secondary Standard'),
                            builder: (context) => const SizedBox.shrink(),
                          ),
                          Breakpoints.largeAndUp: SlotLayout.from(
                            key: const Key('Secondary LargeAndUp'),
                            inAnimation: AdaptiveScaffold.stayOnScreen,
                            builder: (context) => layout.secondaryBody(context),
                          ),
                        },
                      ),
                      secondaryNavigation: SlotLayout(
                        config: {
                          Breakpoints.standard: SlotLayout.from(
                            key: const Key('SecondaryNavigation all'),
                            builder: (context) => const SizedBox.shrink(),
                          ),
                        },
                      ),
                      bottomNavigation: SlotLayout(
                        config: {
                          Breakpoints.standard: SlotLayout.from(
                            key: const Key('SecondaryNavigation all'),
                            builder: (context) => const SizedBox.shrink(),
                          ),
                        },
                      ),
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}
