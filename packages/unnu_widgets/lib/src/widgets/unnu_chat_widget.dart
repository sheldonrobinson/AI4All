import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cross_cache/cross_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:flyer_chat_system_message/flyer_chat_system_message.dart';
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import 'package:june/june.dart';
import 'package:langchain_core/chat_models.dart' as cm;
import 'package:provider/provider.dart';
import 'package:unnu_shared/unnu_shared.dart';

import '../common/config.dart';
import '../common/types.dart';
import '../components/unnu_stream_manager.dart';

class UnnuChatWidget extends StatefulWidget {
  const UnnuChatWidget({
    super.key,
    required this.AssistantTheme,
    this.transcriptions,
    required this.tooltips,
    required this.onCancelModelResponse,
  });

  final Stream<StreamingTranscript>? transcriptions;
  final Map<String, String> tooltips;

  final TextTheme AssistantTheme;
  final void Function() onCancelModelResponse;

  @override
  State<UnnuChatWidget> createState() => _UnnuChatWidgetState();
}

const Duration _kChunkAnimationDuration = Durations.medium1;

class _UnnuChatWidgetState extends State<UnnuChatWidget> {
  final _aiMsgId = IdTracker();
  final _strmTextMsgId = IdTracker();
  final _textMsgId = IdTracker();
  final _crossCache = CrossCache();
  final _scrollController = ScrollController();

  final _streamIdToMessageFragments = <String, List<StreamingTranscript>>{};

  // Store scroll state per stream ID
  final Map<String, double> _initialScrollExtents = {};
  final Map<String, bool> _reachedTargetScroll = {};

  final avatars = <String, String>{};
  void _loadAvatars() async {
    avatars[Avatars.User.id] = await copyAssetFile(Avatars.User.imageSource);
    avatars[Avatars.Assistant.id] = await copyAssetFile(
      Avatars.Assistant.imageSource,
    );
  }


  @override
  void initState() {
    super.initState();

    _loadAvatars();
    final streamManager = June.getState(() => StreamingMessageController());
    streamManager.resubscribe();

    if (widget.transcriptions != null) {
      widget.transcriptions!.listen((data) {
        _handleStreamingTranscript(data);
      });
    }

    if (kDebugMode) {
      print('UnnuChatWidgetState::initState:>');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('avatars[Avatars.User.id] = ${avatars[Avatars.User.id]}');
      print('avatars[Avatars.Assistant.id] = ${avatars[Avatars.Assistant.id]}');
    }

    final currentUser = chat_core.User(
      id: Avatars.User.id,
      imageSource:
          avatars[Avatars.User.id] != null
              ? Uri.file(
                avatars[Avatars.User.id]!,
                windows: Platform.isWindows,
              ).toString()
              : Avatars.User.imageSource,
      name: Avatars.User.name,
    );
    final assistant = chat_core.User(
      id: Avatars.Assistant.id,
      imageSource:
          avatars[Avatars.Assistant.id] != null
              ? Uri.file(
                avatars[Avatars.Assistant.id]!,
                windows: Platform.isWindows,
              ).toString()
              : Avatars.Assistant.imageSource,
      name: Avatars.Assistant.name,
    );

    return JuneBuilder(
      () => StreamingMessageController(),
      builder: (streamingMessageController) {
        final chatController =
            streamingMessageController.messagingModel.chatController;
        final theme = Theme.of(context);
        return ChangeNotifierProvider.value(
          value: streamingMessageController.messagingModel.streamManager,
          child: chat_ui.Chat(
            builders: chat_core.Builders(
              chatAnimatedListBuilder:
                  (context, itemBuilder) => chat_ui.ChatAnimatedList(
                    scrollController: _scrollController,
                    itemBuilder: itemBuilder,
                    shouldScrollToEndWhenAtBottom: false,
                    reversed: true,
                  ),
              composerBuilder:
                  (context) => JuneBuilder(
                    () => ChatWidgetController(),
                    builder:
                        (controller) => chat_ui.Composer(
                          topWidget: controller.actionBar(widget.tooltips),
                          hintText:
                              widget.tooltips['chatHint'] ??
                              'Type a message ...',
                          sendIcon: controller.sendIcon(
                            context,
                            widget.tooltips,
                          ),
                          sendButtonDisabled: !controller.viewModel.nonblocking,
                          sendButtonVisibilityMode:
                              chat_ui.SendButtonVisibilityMode.always,
                        ),
                  ),
              imageMessageBuilder:
                  (
                    context,
                    message,
                    index, {
                    groupStatus,
                    required isSentByMe,
                  }) => FlyerChatImageMessage(
                    message: message,
                    index: index,
                    showTime: false,
                    showStatus: false,
                  ),
              systemMessageBuilder:
                  (
                    context,
                    message,
                    index, {
                    groupStatus,
                    required isSentByMe,
                  }) => FlyerChatSystemMessage(message: message, index: index),
              textMessageBuilder:
                  (
                    context,
                    message,
                    index, {
                    groupStatus,
                    required isSentByMe,
                  }) =>
                      message.metadata != null &&
                              (message.metadata!.containsKey('thinking') ||
                                  message.metadata!.containsKey(
                                    'reasoning_context',
                                  ))
                          ? Tooltip(
                            message:
                                message.metadata?['reasoning_context'] ??
                                message.metadata?['thinking']!,
                            textStyle: widget.AssistantTheme.bodySmall,
                            triggerMode: TooltipTriggerMode.tap,
                            enableTapToDismiss: true,
                            child: FlyerChatTextMessage(
                              message: message,
                              index: index,
                              showTime: false,
                              showStatus: false,
                              receivedBackgroundColor:
                                  theme.scaffoldBackgroundColor,
                              sentBackgroundColor: theme.highlightColor,
                              sentTextStyle: theme.textTheme.bodyMedium,
                              receivedTextStyle:
                                  widget.AssistantTheme.bodyMedium,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(2.0),
                              ),
                            ),
                          )
                          : FlyerChatTextMessage(
                            message: message,
                            index: index,
                            showTime: false,
                            showStatus: false,
                            receivedBackgroundColor: theme.highlightColor,
                            sentBackgroundColor: theme.highlightColor,
                            sentTextStyle: theme.textTheme.bodyMedium,
                            receivedTextStyle: widget.AssistantTheme.bodyMedium,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            borderRadius: BorderRadius.all(
                              Radius.circular(2.0),
                            ),
                          ),
              textStreamMessageBuilder: (
                context,
                message,
                index, {
                groupStatus,
                required isSentByMe,
              }) {
                // Watch the manager for state updates
                final streamState = context.watch<UnnuStreamManager>().getState(
                  message.streamId,
                );
                // Return the stream message widget, passing the state
                return FlyerChatTextStreamMessage(
                  message: message,
                  index: index,
                  streamState: streamState,
                  chunkAnimationDuration: _kChunkAnimationDuration,
                  showTime: false,
                  showStatus: false,
                  receivedBackgroundColor: theme.highlightColor,
                  sentBackgroundColor: theme.highlightColor,
                  sentTextStyle: theme.textTheme.bodyMedium,
                  receivedTextStyle: widget.AssistantTheme.bodyMedium,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(2.0)),
                  mode: TextStreamMessageMode.instantMarkdown,
                  loadingText: widget.tooltips['thinking'] ?? 'Thinking',
                );
              },
              emptyChatListBuilder:
                  (context) => chat_ui.EmptyChatList(
                    text: widget.tooltips['noMessages'] ?? 'No messages yet',
                  ),
            ),
            chatController: chatController,
            crossCache: _crossCache,
            onMessageSend: _onSendPressed,
            currentUserId: Avatars.User.id,
            resolveUser:
                (id) => Future.value(switch (id) {
                  'user' => currentUser,
                  'assistant' => assistant,
                  _ => null,
                }),
            theme: chat_core.ChatTheme.fromThemeData(theme),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print('UnnuChatWidget::dispose()');
    }
    // _streamManager.dispose();
    // _scrollController.dispose();
    // _crossCache.dispose();
    super.dispose();
    if (kDebugMode) {
      print('UnnuChatWidget::dispose:>');
    }
  }

  Future<void> _handleMessageSend(String text) async {
    final streamManager = June.getState(() => StreamingMessageController());
    final timeNow = DateTime.now().toUtc();
    final metadata = <String, dynamic>{'session.id': streamManager.sessionId};
    if (chat_core.isOnlyEmoji(text)) {
      metadata['isOnlyEmoji'] = true;
    }

    final message = chat_core.TextMessage(
      id: _textMsgId.nextId(),
      authorId: Avatars.User.id,
      createdAt: timeNow,
      sentAt: timeNow,
      text: text,
      metadata: metadata,
    );
    await streamManager.insert(message);
    if (kDebugMode) {
      print('_handleMessageSend -> _sndmsg: $message');
    }
    await _sendMessage(message);
    if (kDebugMode) {
      print('UnnuChatWidget::_hndmsgsnd:>');
    }
  }

  Future<void> _sendTranscribedMessage() async {
    final streamManager = June.getState(() => StreamingMessageController());
    final widgetController = June.getState(() => ChatWidgetController());
    await streamManager.onComplete(_strmTextMsgId.currentId);
    final msg = streamManager.findById(_strmTextMsgId.currentId);
    if (msg == null) {
      final _msg = chat_core.TextStreamMessage(
        id: _strmTextMsgId.currentId,
        authorId: Avatars.User.id,
        createdAt: DateTime.now().toUtc(),
        streamId: _strmTextMsgId.currentId,
      );
      streamManager.messagingModel.chatController.removeMessage(_msg);
      {
        widgetController.viewModel = widgetController.viewModel.copyWith(
          status: SendIconState.idle,
        );
        widgetController.setState();
      }
    } else {
      switch (msg) {
        case chat_core.TextMessage():
          {
            if (msg.text.isNotEmpty) {
              await _sendMessage(msg);
            } else {
              streamManager.messagingModel.chatController.removeMessage(msg);
            }
          }
          break;
        case chat_core.TextStreamMessage():
        case chat_core.ImageMessage():
        case chat_core.FileMessage():
        case chat_core.VideoMessage():
        case chat_core.AudioMessage():
        case chat_core.SystemMessage():
        case chat_core.CustomMessage():
        case chat_core.UnsupportedMessage():
          break;
      }
    }
  }

  Future<void> _startStreamingTranscript(StreamingTranscript transcript) async {
    final widgetController = June.getState(() => ChatWidgetController());
    final streamManager = June.getState(() => StreamingMessageController());
    {
      widgetController.viewModel = widgetController.viewModel.copyWith(
        status: SendIconState.transcribing,
      );
      widgetController.setState();
    }
    final msg = streamManager.findById(_strmTextMsgId.currentId);

    if (msg != null) {
      switch (msg) {
        case chat_core.TextMessage():
          {
            final _strmId = _strmTextMsgId.nextId();
            Map<String, dynamic> metadata =
                msg.metadata ??
                {
                  'message.id': _strmTextMsgId.currentId,
                  'session.id': streamManager.sessionId,
                };
            metadata['stream_status'] = transcript.type.name;
            metadata['allow.updates'] = true;
            final streamMessage = chat_core.TextStreamMessage(
              id: _strmId,
              authorId: msg.authorId,
              createdAt: msg.createdAt,
              streamId: _strmId,
              metadata: metadata,
              replyToMessageId: msg.replyToMessageId,
              seenAt: msg.seenAt,
              updatedAt: msg.updatedAt,
              reactions: msg.reactions,
            );
            final text = msg.text;
            await streamManager.messagingModel.chatController.removeMessage(
              msg,
            );
            await streamManager.onStartStream(_strmId, streamMessage);
            streamManager.addChunk(_strmId, text);
          }
          break;
        case chat_core.SystemMessage():
          {
            streamManager.addChunk(_strmTextMsgId.currentId, msg.text);
          }
          break;
        case chat_core.TextStreamMessage():
          {
            switch (transcript.type) {
              case TranscriptionFragmentType.start:
              case TranscriptionFragmentType.chunk:
                break;
              case TranscriptionFragmentType.partial:
                {
                  _streamIdToMessageFragments[_strmTextMsgId.currentId] =
                      _streamIdToMessageFragments[_strmTextMsgId.currentId] ??
                      List<StreamingTranscript>.empty(growable: true);
                }
                break;
              case TranscriptionFragmentType.complete:
                {
                  _streamIdToMessageFragments[_strmTextMsgId.currentId] =
                      _streamIdToMessageFragments[_strmTextMsgId.currentId] ??
                      List<StreamingTranscript>.empty(growable: true);
                }
                break;
              case TranscriptionFragmentType.end:
                break;
            }
          }
        case chat_core.AudioMessage():
        case chat_core.ImageMessage():
        case chat_core.FileMessage():
        case chat_core.VideoMessage():
        case chat_core.CustomMessage():
        case chat_core.UnsupportedMessage():
          break;
      }
    } else {
      _strmTextMsgId.nextId();
      final msgId = DateTime.now().toUtc().millisecondsSinceEpoch;
      final streamMessage = chat_core.TextStreamMessage(
        id: _strmTextMsgId.currentId,
        authorId: Avatars.User.id,
        createdAt: DateTime.now().toUtc(),
        streamId: _strmTextMsgId.currentId,
        metadata: {
          'message.id': msgId as String,
          'session.id': streamManager.sessionId,
          'stream_status': transcript.type.name,
          'allow.updates': true,
        },
      );
      await streamManager.onStartStream(
        _strmTextMsgId.currentId,
        streamMessage,
      );
      _streamIdToMessageFragments[_strmTextMsgId
          .currentId] = List<StreamingTranscript>.empty(growable: true);
    }
  }

  Future<void> _handleStreamingTranscript(
    StreamingTranscript transcript,
  ) async {
    final streamManager = June.getState(() => StreamingMessageController());
    switch (transcript.type) {
      case TranscriptionFragmentType.start:
        {
          if (transcript.text.isNotEmpty) {
            if (!_streamIdToMessageFragments.containsKey(
              _strmTextMsgId.currentId,
            )) {
              await _startStreamingTranscript(transcript);
            }
            streamManager.addChunk(_strmTextMsgId.currentId, transcript.text);
          }
        }
        break;
      case TranscriptionFragmentType.chunk:
        {
          if (transcript.text.isNotEmpty) {
            if (!_streamIdToMessageFragments.containsKey(
              _strmTextMsgId.currentId,
            )) {
              await _startStreamingTranscript(transcript);
            }
            streamManager.addChunk(_strmTextMsgId.currentId, transcript.text);
          }
        }
        break;
      case TranscriptionFragmentType.partial:
        {
          if (transcript.text.isNotEmpty) {
            if (!_streamIdToMessageFragments.containsKey(
              _strmTextMsgId.currentId,
            )) {
              await _startStreamingTranscript(transcript);
            }
            _streamIdToMessageFragments[_strmTextMsgId.currentId]?.add(
              transcript,
            );
          }
        }
        break;

      case TranscriptionFragmentType.complete:
        {
          if (transcript.text.isNotEmpty) {
            if (!_streamIdToMessageFragments.containsKey(
              _strmTextMsgId.currentId,
            )) {
              await _startStreamingTranscript(transcript);
            }
          }
          _streamIdToMessageFragments[_strmTextMsgId.currentId]?.add(
            transcript,
          );
          await streamManager.onComplete(_strmTextMsgId.currentId);
          _sendTranscribedMessage();
        }
        break;
      case TranscriptionFragmentType.end:
        {
          if (_streamIdToMessageFragments.containsKey(
            _strmTextMsgId.currentId,
          )) {
            await streamManager.onComplete(_strmTextMsgId.currentId);
            _sendTranscribedMessage();
          }
        }
        break;
    }
  }

  Future<void> _cancelResponse() async {
    final streamManager = June.getState(() => StreamingMessageController());
    final widgetController = June.getState(() => ChatWidgetController());
    {
      widgetController.viewModel = widgetController.viewModel.copyWith(
        nonblocking: true,
      );
      widgetController.setState();
    }
    widget.onCancelModelResponse();
    streamManager.onStopStream(streamManager.messagingModel.sessionId);
    final aiMsg = streamManager.findById(_aiMsgId.currentId);
    if (aiMsg != null) {
      final usrMsg = streamManager.findById(aiMsg.replyToMessageId!);
      streamManager.messagingModel.chatController.removeMessage(aiMsg);
      streamManager.messagingModel.chatController.removeMessage(usrMsg!);

      _initialScrollExtents.remove(aiMsg.id);
      _reachedTargetScroll.remove(aiMsg.id);
    }
    {
      widgetController.viewModel = widgetController.viewModel.copyWith(
        status: SendIconState.idle,
        nonblocking: false,
      );
      widgetController.setState();
    }
  }

  Future<void> _sendMessage(chat_core.Message message) async {
    final widgetController = June.getState(() => ChatWidgetController());
    {
      widgetController.viewModel = widgetController.viewModel.copyWith(
        status: SendIconState.busy,
      );
      widgetController.setState();
    }

    final sessionId = message.metadata!['session.id'];

    final streamId = _aiMsgId.nextId();
    chat_core.TextStreamMessage? streamMessage;
    final streamManager = June.getState(() => StreamingMessageController());
    final sessionController = June.getState(() => ChatSessionController());
    try {
      var isFirstChunk = true;
      _reachedTargetScroll[streamId] = false;
      final chatMessage =
          message is chat_core.TextMessage
              ? message.authorId == Avatars.User.id
                  ? cm.ChatMessage.humanText(message.text)
                  : message.authorId == Avatars.Assistant.id
                  ? cm.ChatMessage.ai(message.text)
                  : cm.ChatMessage.custom(message.text, role: message.authorId)
              : cm.ChatMessage.custom(
                message.toString(),
                role:
                    message.authorId == Avatars.User.id
                        ? cm.ChatMessageRole.human.name
                        : message.authorId == Avatars.Assistant.id
                        ? cm.ChatMessageRole.ai.name
                        : message.authorId,
              );
      if (kDebugMode) {
        print('_sndmsg: $chatMessage');
      }
      final response = sessionController.chatSessionVM.activeSession
          .sendMessageStream(chatMessage);

      // This implements a scrolling behavior where we stop auto-scrolling once the
      // generated message reaches the top of the viewport. For this to work properly,
      // make sure to set `shouldScrollToEndWhenAtBottom` to false in `ChatAnimatedList`.
      streamManager.messagingModel.subscriptions[streamId] = response.listen(
        (chunk) async {
          final textChunk = chunk.output;
          if (textChunk.isNotEmpty) {
            // if (textChunk.isEmpty) continue; // Skip empty chunks

            //if (chunk.output.isNotEmpty) {
            // Store the initial scroll position when user inserts the message.
            // The chat will auto-scroll here since `shouldScrollToEndWhenSendingMessage`
            // is enabled by default.

            if (isFirstChunk) {
              isFirstChunk = false;
              // Create and insert the message ON the first chunk
              final createdWhen = DateTime.now().toUtc();
              final metainfo = {
                'session.id': sessionId,
                'replyTo.id': message.id,
                'allow.updates': true,
                'is.streaming': true,
              };
              if (chunk.metadata.containsKey('message.id')) {
                metainfo['message.id'] = chunk.metadata['message.id'] as String;
              }
              streamMessage = chat_core.TextStreamMessage(
                id: streamId,
                authorId: Avatars.Assistant.id,
                createdAt: createdWhen,
                streamId: streamId,
                replyToMessageId: message.id,
                metadata: metainfo,
              );
              if (kDebugMode) {
                print('_sendMessage: 1st $streamMessage');
              }
              await streamManager.onStartStream(streamId, streamMessage!);
            }

            // Ensure stream message exists before adding chunk
            if (streamMessage != null &&
                streamMessage?.metadata!['message.type'] == 'token') {
              // Send chunk to the manager - this triggers notifyListeners
              streamManager.addChunk(streamId, textChunk);
            }

            // Only attempt scrolling if:
            // 1. We haven't already reached our target scroll position
            // 2. The chat is actually scrollable (maxScrollExtent > 0)
            // Note: This won't work when the UI first renders and isn't scrollable yet.
            // That would require measuring content height instead of maxScrollExtent.
            // Please suggest how to do this if possible.

            // if (!hasReachedTargetScroll && initialMaxScrollExtent > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_scrollController.hasClients || !mounted) return;

              // Retrieve state for this specific stream
              var initialExtent = _initialScrollExtents[streamId];
              final reachedTarget = _reachedTargetScroll[streamId] ?? false;

              if (reachedTarget) return; // Already scrolled to target

              // Store initial extent after first chunk caused rebuild
              initialExtent ??=
                  _initialScrollExtents[streamId] =
                      _scrollController.position.maxScrollExtent;

              // Only scroll if the list is scrollable
              if (initialExtent > 0) {
                // Calculate target scroll position (copied from original logic)
                final targetScroll =
                    initialExtent + // Use the stored initial extent
                    _scrollController.position.viewportDimension -
                    MediaQuery.paddingOf(context).bottom -
                    168; // height of the composer + height of the app bar + visual buffer of 8

                if (_scrollController.position.maxScrollExtent > targetScroll) {
                  _scrollController.animateTo(
                    targetScroll,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.linearToEaseOut,
                  );
                  // Mark that we've reached the target for this stream
                  _reachedTargetScroll[streamId] = true;
                } else {
                  // If we haven't reached target position yet, scroll to bottom
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.linearToEaseOut,
                  );
                }
              }
            });
          }
        },
        onDone: () async {
          // Stream completed successfully (only if message was created)
          if (streamMessage != null) {
            await streamManager.onComplete(streamId);
          }
          {
            widgetController.viewModel = widgetController.viewModel.copyWith(
              status: SendIconState.idle,
            );
            widgetController.setState();
            // updateSendIcon();
          }
        },
        onError: (error) async {
          await streamManager.onError(streamId, error);
          {
            widgetController.viewModel = widgetController.viewModel.copyWith(
              status: SendIconState.idle,
            );
            widgetController.setState();
            // updateSendIcon();
          }
        },
      );
    } catch (error) {
      // Catch other potential errors during stream processing
      await streamManager.onError(streamId, error);
    } finally {
      // Clean up scroll state for this stream ID when done/errored
      _initialScrollExtents.remove(streamId);
      _reachedTargetScroll.remove(streamId);

      if (kDebugMode) {
        print('_sndmsg:finally:>');
      }
    }

    if (kDebugMode) {
      print('_sndmsg:>');
    }
  }

  Future<void> _onSendPressed(String text) async {
    if (kDebugMode) {
      print('_onSendPressed: $text');
    }
    final widgetController = June.getState(() => ChatWidgetController());
    switch (widgetController.viewModel.status) {
      case SendIconState.idle:
        if (text.isNotEmpty) {
          _handleMessageSend(text);
        }
        break;
      case SendIconState.busy:
        _cancelResponse();
        break;
      case SendIconState.transcribing:
        await _sendTranscribedMessage();
        break;
      case SendIconState.loading:
        break;
    }
  }
}
