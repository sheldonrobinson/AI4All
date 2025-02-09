import 'dart:async';
import 'dart:core';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:june/june.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unnu_ai_model/unnu_ai_model.dart';
import 'package:unnu_common/unnu_common.dart';
import 'package:unnu_sap/unnu_asr.dart';
import 'package:unnu_sap/unnu_tts.dart';
import 'package:unnu_shared/unnu_shared.dart';
import 'package:unnu_speech/unnu_speech.dart';
import 'package:unnu_widgets/unnu_widgets.dart';

import 'generated/i18n/app_localizations.dart';
import 'types.dart';

class MyHomePage extends StatefulWidget {
  /// Creates a const [MyHomePage].
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  final LLMProviderController llmProviderController = June.getState(
    LLMProviderController.new,
  );
  final StreamingMessageController streamingMessageController = June.getState(
    StreamingMessageController.new,
  );

  @override
  void initState() {
    super.initState();

    // Close splash screen after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final _ = June.getState(
        ApplicationLayoutModelController.new,
      )..onInitDisclosures();

      // Helper to create and insert the message, ensuring it only happens once.
      Future<void> loadInitialModel() async {
        final chatSessionController = June.getState(
          ChatSessionController.new,
        );

        final ret = await ModelUtils.switchModel(
          UnnuModelDetails(
            info: llmProviderController.activeModel.info,
            specifications: llmProviderController.activeModel.specifications,
          ),
        );
        if (ret == 0) {
          await chatSessionController.newChat();
          await streamingMessageController.newChat();
        }
      }

      await loadInitialModel();
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    streamingMessageController.messagingModel.chatController.dispose();
    streamingMessageController.messagingModel.streamManager.dispose();
    super.dispose();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    WidgetsBinding.instance.removeObserver(this);
    UnnuTts.destroy();
    UnnuAsr.destroy();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'model.active',
      llmProviderController.activeModel.uri,
    );
    llmProviderController.provider.destroy();
    final configurationController = June.getState(
      ConfigurationController.new,
    );
    await configurationController.save();
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
    final navBarTheme = NavigationBarTheme.of(context).copyWith(
      indicatorColor: Colors.transparent,
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
      navigationBarTheme: navBarTheme,
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
      navigationBarTheme: navBarTheme,
    );

    final _ = June.getState(() => OfflineTtsController())
      ..onLocale(Intl.getCurrentLocale());

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
                    "copy": appLocalizations.copy,
                    "share": appLocalizations.share,
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
          final colorScheme = ColorScheme.of(context);

          return Container(
            constraints: const BoxConstraints(minHeight: 480, minWidth: 360),
            color: colorScheme.surface,
            child: Scaffold(
              backgroundColor: colorScheme.surface,
              appBar: AppBar(
                title: Text(
                  r'A\V',
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
                                (
                                  context,
                                ) => AdaptiveScaffold.standardNavigationRail(
                                  leading: Container(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: 4,
                                      children: [
                                        IconButton.outlined(
                                          tooltip:
                                              tooltips['newChat'] ?? 'New Chat',
                                          style: IconButton.styleFrom(
                                            shape:
                                                const RoundedRectangleBorder(),
                                            padding: const EdgeInsets.all(4),
                                          ),
                                          onPressed:
                                              () => layout.onPrimaryNavigation(
                                                context,
                                                AppPrimaryNavigation
                                                    .NewChat
                                                    .value,
                                              ),
                                          icon: const Icon(Icons.add_circle),
                                        ),
                                        IconButton.outlined(
                                          tooltip:
                                              tooltips['switchModel'] ??
                                              'Switch Model',
                                          style: IconButton.styleFrom(
                                            shape:
                                                const RoundedRectangleBorder(),
                                            padding: const EdgeInsets.all(4),
                                          ),
                                          onPressed:
                                              () => layout.onPrimaryNavigation(
                                                context,
                                                AppPrimaryNavigation
                                                    .SwitchModel
                                                    .value,
                                              ),
                                          icon: const Icon(Icons.file_open),
                                        ),
                                        IconButton.outlined(
                                          tooltip: tooltips['about'] ?? 'About',
                                          style: IconButton.styleFrom(
                                            shape:
                                                const RoundedRectangleBorder(),
                                            padding: const EdgeInsets.all(4),
                                          ),
                                          onPressed:
                                              () => layout.onPrimaryNavigation(
                                                context,
                                                AppPrimaryNavigation
                                                    .About
                                                    .value,
                                              ),
                                          icon: const Icon(Icons.info),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Container(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: 4,
                                      children: [
                                        IconButton.outlined(
                                          tooltip:
                                              tooltips['feedback'] ??
                                              'Feedback',
                                          style: IconButton.styleFrom(
                                            shape:
                                                const RoundedRectangleBorder(),
                                            padding: const EdgeInsets.all(4),
                                          ),
                                          onPressed:
                                              () => layout.onPrimaryNavigation(
                                                context,
                                                AppPrimaryNavigation
                                                    .Feedback
                                                    .value,
                                              ),
                                          icon: const Icon(Icons.feedback),
                                        ),
                                      ],
                                    ),
                                  ),
                                  destinations: <NavigationRailDestination>[],
                                  labelType: NavigationRailLabelType.none,
                                  selectedIndex: null,
                                  backgroundColor:
                                      ColorScheme.of(context).surface,
                                  onDestinationSelected:
                                      (selected) => layout.onPrimaryNavigation(
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
