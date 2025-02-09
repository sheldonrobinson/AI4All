import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:siri_wave/siri_wave.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:glow_container/glow_container.dart';

import '../common/types.dart';

class UnnuSpeechWidget extends StatefulWidget {
  final Widget? chyron;
  final Widget? label;
  final void Function(bool mute)? onMute;
  final void Function(InteractiveMode mode)? onModeChange;
  final VoidCallback? onNudge;
  final Stream<double>? noise;
  final Stream<bool>? eavesdropping;
  final SpeechWidgetSettings settings;
  final Map<String, String> tooltips;
  const UnnuSpeechWidget({
    super.key,
    required this.settings,
    this.chyron,
    this.onMute,
    this.onModeChange,
    this.noise,
    this.eavesdropping,
    this.onNudge,
    this.label,
    required this.tooltips,
  });

  @override
  State<UnnuSpeechWidget> createState() => _UnnuSpeechWidgetState();
}

class _UnnuSpeechWidgetState extends State<UnnuSpeechWidget> {
  bool listening = false;
  bool mute = false;
  InteractiveMode _mode = InteractiveMode.OnDemand;

  NoiseLevel _noise = (amplitude: 0.0, speed: 0.0);

  @override
  void initState() {
    if (kDebugMode) {
      print('UnnuSpeechWidget::initState()');
    }
    super.initState();

    _mode =
        widget.settings.hasMicrophone
            ? InteractiveMode.OnDemand
            : InteractiveMode.Text;

    if (widget.onModeChange != null) {
      widget.onModeChange!(_mode);
    }

    if (widget.onMute != null) {
      widget.onMute!(mute);
    }

    // Starting in on-demand mode
    if (kDebugMode) {
      print('UnnuSpeechWidget::initState:>');
    }
  }

  @override
  Widget build(BuildContext context) {
    final chyron =
        widget.chyron ??
        AnimatedTextKit(
          animatedTexts: [
            FadeAnimatedText(
              '(❨﹙﹚❩)',
              textStyle: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontFamily: 'Noto Sans Mono'),
              textAlign: TextAlign.center,
            ),
          ],
          stopPauseOnTap: false,
          displayFullTextOnTap: false,
          isRepeatingAnimation: true,
          repeatForever: true,
        );

    if (widget.noise != null) {
      final _ = widget.noise!.listen(
        (value) {
          final val = min(max(value, 0.0), 1.0);
          setState(() {
            _noise = (amplitude: val, speed: val > 0.0 ? 0.2 : 0.0);
          });
        },

        onDone: () {
          setState(() {
            _noise = (amplitude: 0.0, speed: 0.0);
          });
        },
      );
    }
    if (widget.eavesdropping != null) {
      widget.eavesdropping!.listen((onData) {
        if (kDebugMode) {
          print('UnnuSpeechWidget widget.eavesdropping!($onData)');
        }
        setState(() {
          listening = onData;
        });
      });
    }
    final theme = Theme.of(context);
    final colorScheme = ColorScheme.of(context);
    return Platform.isAndroid || Platform.isIOS
        ? Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20,
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.topCenter,
                // constraints: BoxConstraints.expand(),
                height: MediaQuery.sizeOf(context).height,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(width: 2.0),
                  borderRadius: BorderRadius.zero,
                  color: colorScheme.surface,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: SizedBox(
                        height: 70,
                        child: Container(
                          padding: const EdgeInsets.all(3.0),
                          alignment: Alignment.topCenter,
                          color: colorScheme.surface,
                          child: chyron,
                        ),
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        height: 35,
                        child: GlowContainer(
                          glowRadius: 5,
                          gradientColors: [
                            Colors.blue,
                            Colors.purple,
                            Colors.pink,
                          ],
                          rotationDuration: Duration(seconds: 3),
                          glowLocation: GlowLocation.both,
                          containerOptions: ContainerOptions(
                            width: MediaQuery.sizeOf(context).width * 0.5,
                            height: 35,
                            borderRadius: 5,
                            backgroundColor: Colors.transparent,
                            borderSide: BorderSide(
                              width: 1.0,
                              color: Colors.transparent,
                              style:
                                  widget.settings.hasMicrophone && listening
                                      ? BorderStyle.solid
                                      : BorderStyle.none,
                            ),
                          ),
                          transitionDuration: Duration(milliseconds: 300),
                          showAnimatedBorder:
                              widget.settings.hasMicrophone && listening,
                          child: Container(
                            padding: const EdgeInsets.all(2.0),
                            alignment: Alignment.bottomCenter,
                            height: 40,
                            width: MediaQuery.sizeOf(context).width * 0.6,
                            color: colorScheme.surface,
                            child: switch (_mode) {
                              InteractiveMode.Live =>
                                widget.settings.hasMicrophone
                                    ? SiriWaveform.ios9(
                                      controller: IOS9SiriWaveformController(
                                        amplitude: _noise.amplitude,
                                        speed: _noise.speed,
                                      ),
                                      options: IOS9SiriWaveformOptions(
                                        height:
                                            MediaQuery.sizeOf(context).height,
                                        width: MediaQuery.sizeOf(context).width,
                                        showSupportBar: false,
                                      ),
                                    )
                                    : Container(),
                              InteractiveMode.OnDemand =>
                                widget.settings.hasMicrophone
                                    ? !listening
                                        ? SizedBox.expand(
                                          child: ElevatedButton(
                                            onPressed: widget.onNudge,
                                            child: Text(
                                              widget.tooltips['tapToSpeak'] ??
                                                  'Tap to Speak',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )
                                        : Container()
                                    : Container(),
                              InteractiveMode.Text => Container(),
                            },
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(2.0),
                        alignment: Alignment.bottomCenter,
                        height: 30,
                        width: MediaQuery.sizeOf(context).width,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 30,
                              alignment: Alignment.topLeft,
                              color: colorScheme.surface,
                              child: InteractionChoice(
                                // interactive: widget.settings,
                                hasMicrophone: widget.settings.hasMicrophone,
                                tooltips: widget.tooltips,
                                onChanged: _onModeChanged,
                                initialMode: _mode,
                              ),
                            ),
                            widget.label != null
                                ? Expanded(child: widget.label ?? Spacer())
                                : Spacer(),
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(1),
                                ),
                                border: Border.all(width: 1.0),
                                color: colorScheme.surface,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(1),
                                child: Center(
                                  child: FloatingActionButton(
                                    onPressed:
                                        widget.settings.hasSpeaker
                                            ? () => _toggleMute()
                                            : null,
                                    tooltip:
                                        widget.settings.hasSpeaker
                                            ? mute
                                                ? widget.tooltips['unmute'] ??
                                                    'Unmute'
                                                : widget.tooltips['mute'] ??
                                                    'Mute'
                                            : widget.tooltips['textOnly'] ??
                                                'Text Only',
                                    child:
                                        widget.settings.hasSpeaker
                                            ? mute
                                                ? const Icon(
                                                  Icons.voice_over_off,
                                                  size: 24,
                                                )
                                                : const Icon(
                                                  Icons.record_voice_over,
                                                  size: 24,
                                                )
                                            : const Icon(
                                              Icons.voice_over_off,
                                              size: 24,
                                            ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
        : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 10,
          children: [
            Container(
              width: 60,
              alignment: Alignment.centerLeft,
              color: colorScheme.surface,
              child: Padding(
                padding: EdgeInsets.only(left: 5),
                child: InteractionChoice(
                  // interactive: widget.settings,
                  hasMicrophone: widget.settings.hasMicrophone,
                  tooltips: widget.tooltips,
                  onChanged: _onModeChanged,
                  initialMode: _mode,
                ),
              ),
            ),
            Expanded(
              child: Container(
                alignment: Alignment.topCenter,
                // constraints: BoxConstraints.expand(),
                height: MediaQuery.sizeOf(context).height,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  border: Border.all(width: 2.0),
                  borderRadius: BorderRadius.zero,
                  color: colorScheme.surface,
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: SizedBox(
                        height: 70,
                        child: Container(
                          padding: const EdgeInsets.all(3.0),
                          alignment: Alignment.topCenter,
                          color: colorScheme.surface,
                          // constraints: BoxConstraints(minHeight: 45, minWidth: 70),
                          // width: MediaQuery.sizeOf(context).width * 0.9,
                          child: chyron,
                        ),
                      ),
                    ),
                    Center(
                      child: SizedBox(
                        height: 35,
                        child: GlowContainer(
                          glowRadius: 5,
                          gradientColors: [
                            Colors.blue,
                            Colors.purple,
                            Colors.pink,
                          ],
                          rotationDuration: Duration(seconds: 3),
                          glowLocation: GlowLocation.both,
                          containerOptions: ContainerOptions(
                            width: MediaQuery.sizeOf(context).width * 0.5,
                            height:
                                35, //MediaQuery.sizeOf(context).height *0.9,
                            borderRadius: 5,
                            backgroundColor: Colors.transparent,
                            borderSide: BorderSide(
                              width: 1.0,
                              color: Colors.transparent,
                              style:
                                  widget.settings.hasMicrophone && listening
                                      ? BorderStyle.solid
                                      : BorderStyle.none,
                            ),
                          ),
                          transitionDuration: Duration(milliseconds: 300),
                          showAnimatedBorder:
                              widget.settings.hasMicrophone && listening,
                          child: Container(
                            padding: const EdgeInsets.all(2.0),
                            alignment: Alignment.bottomCenter,
                            height: 40,
                            width: MediaQuery.sizeOf(context).width * 0.6,
                            color: colorScheme.surface,
                            child: switch (_mode) {
                              InteractiveMode.Live =>
                                widget.settings.hasMicrophone
                                    ? SiriWaveform.ios9(
                                      controller: IOS9SiriWaveformController(
                                        amplitude: _noise.amplitude,
                                        speed: _noise.speed,
                                      ),
                                      options: IOS9SiriWaveformOptions(
                                        height:
                                            MediaQuery.sizeOf(context).height,
                                        width: MediaQuery.sizeOf(context).width,
                                        showSupportBar: false,
                                      ),
                                    )
                                    : Container(),
                              InteractiveMode.OnDemand =>
                                widget.settings.hasMicrophone
                                    ? !listening
                                        ? SizedBox.expand(
                                          child: ElevatedButton(
                                            onPressed: widget.onNudge,
                                            child: Text(
                                              widget.tooltips['tapToSpeak'] ??
                                                  'Tap to Speak',
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        )
                                        : Container()
                                    : Container(),
                              InteractiveMode.Text => Container(),
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 5),
              child: Container(
                width: 100,
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  border: Border.all(width: 2.0),
                  color: colorScheme.surface,
                ),

                child: Padding(
                  padding: EdgeInsets.all(5),
                  child: Center(
                    child: FloatingActionButton(
                      onPressed:
                          widget.settings.hasSpeaker
                              ? () => _toggleMute()
                              : null,
                      tooltip:
                          widget.settings.hasSpeaker
                              ? mute
                                  ? widget.tooltips['unmute'] ?? 'Unmute'
                                  : widget.tooltips['mute'] ?? 'Mute'
                              : widget.tooltips['textOnly'] ?? 'Text Only',
                      child:
                          widget.settings.hasSpeaker
                              ? mute
                                  ? const Icon(Icons.voice_over_off, size: 75)
                                  : const Icon(
                                    Icons.record_voice_over,
                                    size: 75,
                                  )
                              : const Icon(Icons.voice_over_off, size: 75),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
  }

  void _toggleMute() {
    final tmp = !mute;
    setState(() {
      mute = tmp;
    });
    if (widget.onMute != null) {
      widget.onMute!(tmp);
    }
  }

  void _onModeChanged(InteractiveMode mode) {
    setState(() {
      _mode = mode;
    });

    if (widget.onModeChange != null) {
      widget.onModeChange!(mode);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class InteractionChoice extends StatefulWidget {
  final void Function(InteractiveMode)? onChanged;
  final bool hasMicrophone;
  final InteractiveMode initialMode;
  final Map<String, String> tooltips;

  const InteractionChoice({
    super.key,
    required this.hasMicrophone,
    this.initialMode = InteractiveMode.OnDemand,
    required this.tooltips,
    this.onChanged,
  });

  @override
  State<InteractionChoice> createState() => _InteractionChoiceState();
}

class _InteractionChoiceState extends State<InteractionChoice> {
  InteractiveMode mode = InteractiveMode.OnDemand;

  @override
  void initState() {
    super.initState();

    setState(() {
      mode = widget.hasMicrophone ? widget.initialMode : InteractiveMode.Text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<InteractiveMode>(
      multiSelectionEnabled: false,
      emptySelectionAllowed: false,

      segments: <ButtonSegment<InteractiveMode>>[
        ButtonSegment<InteractiveMode>(
          value: InteractiveMode.Live,
          icon: const Icon(Icons.graphic_eq, size: 14.0),
          tooltip:
              widget.hasMicrophone
                  ? widget.tooltips['live'] ?? 'live'
                  : widget.tooltips['noMic'] ?? 'no-mic',
        ),
        ButtonSegment<InteractiveMode>(
          value: InteractiveMode.OnDemand,
          icon: const Icon(Icons.interpreter_mode, size: 14.0),
          tooltip:
              widget.hasMicrophone
                  ? widget.tooltips['onDemand'] ?? 'on-demand'
                  : widget.tooltips['noMic'] ?? 'no-mic',
        ),
        ButtonSegment<InteractiveMode>(
          value: InteractiveMode.Text,
          icon: const Icon(Icons.notes, size: 14.0),
          tooltip:
              widget.hasMicrophone
                  ? widget.tooltips['textOnly'] ?? 'text-only'
                  : widget.tooltips['no-mic'] ?? 'no-mic',
        ),
      ],
      // expandedInsets: EdgeInsets.only(left: 1.0, right: 1.0, top: 1.0, bottom: 1.0),
      style: ButtonStyle(
        // Customize the button style for vertical orientation
        padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          EdgeInsets.only(left: 1.0, right: 1.0, top: 1.0, bottom: 1.0),
        ),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(1.0)),
            side: BorderSide(color: Colors.blueGrey),
          ),
        ),
      ),
      direction:
          Platform.isAndroid || Platform.isIOS
              ? Axis.horizontal
              : Axis.vertical,
      selected: <InteractiveMode>{mode},
      onSelectionChanged:
          widget.hasMicrophone
              ? (Set<InteractiveMode> newSelection) {
                // By default there is only a single segment that can be
                // selected at one time, so its value is always the first
                // item in the selected set.

                final selection =
                    widget.hasMicrophone
                        ? newSelection.first
                        : InteractiveMode.Text;

                setState(() {
                  mode = selection;
                });
                if (widget.onChanged != null) {
                  widget.onChanged!(selection);
                }
              }
              : null,
    );
  }
}
