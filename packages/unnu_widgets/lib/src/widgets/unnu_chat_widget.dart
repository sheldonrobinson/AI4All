import 'dart:async';
import 'dart:io';

import 'package:cross_cache/cross_cache.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:flutter_popup_card/flutter_popup_card.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flyer_chat_file_message/flyer_chat_file_message.dart';
import 'package:flyer_chat_image_message/flyer_chat_image_message.dart';
import 'package:flyer_chat_system_message/flyer_chat_system_message.dart';
import 'package:flyer_chat_text_message/flyer_chat_text_message.dart';
import 'package:flyer_chat_text_stream_message/flyer_chat_text_stream_message.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:june/june.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:motion_toast/motion_toast.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:unnu_ai_model/unnu_ai_model.dart';
import 'package:unnu_mi5/unnu_mi5.dart';
import 'package:unnu_shared/unnu_shared.dart';

import '../common/config.dart';
import '../common/types.dart';
import '../components/message_action_bar.dart';
import '../components/unnu_stream_manager.dart';

class SendIcon extends StatelessWidget {
  const SendIcon({
    super.key,
    required this.state,
    required this.nonblocking,
    required this.tooltips,
  });
  final SendIconState state;
  final bool nonblocking;
  final Map<String, String> tooltips;
  @override
  Widget build(BuildContext context) {
    return state != SendIconState.idle
        ? Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Tooltip(
            message: switch (state) {
              SendIconState.idle => tooltips['send'] ?? 'Send',
              SendIconState.busy => tooltips['cancel'] ?? 'Cancel',
              SendIconState.loading => tooltips['busy'] ?? 'Busy',
              SendIconState.transcribing => tooltips['send'] ?? 'Send',
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                SpinKitDualRing(
                  color: Theme.of(context).colorScheme.primary,
                ),
                Icon(
                  switch (state) {
                    SendIconState.idle => Icons.send,
                    SendIconState.busy => Icons.stop_circle,
                    SendIconState.loading => Icons.hourglass_empty,
                    SendIconState.transcribing => Icons.chat,
                  },
                  color: nonblocking ? Colors.red : Colors.grey,
                  size: 32,
                ),
              ],
            ),
          ),
        )
        : Tooltip(
          message: tooltips['send'] ?? 'Send',
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: BoxBorder.all(style: BorderStyle.none),
            ),
            child: const Icon(Icons.send),
          ),
        );
  }
}

class UnnuActionBar extends StatelessWidget {
  UnnuActionBar({super.key, required this.tooltips});
  final Map<String, String> tooltips;
  final ChatSessionController _chatSessionController = June.getState(
    ChatSessionController.new,
  );
  final ChatWidgetController _widgetController = June.getState(
    ChatWidgetController.new,
  );

  @override
  Widget build(BuildContext context) {
    return MessageActionBar(
      buttons: <MessageActionButton>[
        MessageActionButton(
          icon: Icons.cleaning_services, //Icons.delete_sweep,
          title: tooltips['clearAll'] ?? 'Clear All',
          onPressed: () async {
            final chatSessionController = June.getState(
              ChatSessionController.new,
            );
            final streamingMessageController = June.getState(
              StreamingMessageController.new,
            );
            await chatSessionController.clearMessages();
            await streamingMessageController.clearMessages();
          },
          destructive: true,
          nature: ButtonNature.Holdable,
          variant: ButtonVariant.Filled,
        ),
        MessageActionButton(
          icon: Icons.copy_all, //Icons.delete_sweep,
          title: tooltips['copy'] ?? 'Copy',
          onPressed: () async {
            final clipboard = SystemClipboard.instance;
            if (clipboard != null) {
              final chatSessionController = June.getState(
                ChatSessionController.new,
              );
              final messages = await chatSessionController.asMarkdown();
              final item = DataWriterItem()..add(Formats.plainText(messages));
              await clipboard.write([item]);
              if (context.mounted) {
                MotionToast.success(
                  description: Text(tooltips['copied'] ?? 'Copied'),
                ).show(context);
              }
            }
          },
          type: ButtonType.IconOnly,
          variant: ButtonVariant.Outlined,
        ),
        MessageActionButton(
          icon: Icons.share, //Icons.delete_sweep,
          title: tooltips['share'] ?? 'Share',
          onPressed: () async {
            final chatSessionController = June.getState(
              ChatSessionController.new,
            );
            final messages = await chatSessionController.asMarkdown();
            if (messages.isNotEmpty) {
              final params = ShareParams(
                text: messages,
                downloadFallbackEnabled: false,
              );
              final result = await SharePlus.instance.share(params);
              if (context.mounted) {
                if (result.status == ShareResultStatus.success) {
                  MotionToast.success(
                    description: Text(tooltips['shared'] ?? 'Shared'),
                  ).show(context);
                }
              }
            }
          },
          type: ButtonType.IconOnly,
          variant: ButtonVariant.Outlined,
        ),
      ],
    );
  }
}

class UnnuChatWidget extends StatefulWidget {
  const UnnuChatWidget({
    super.key,
    required this.AssistantTheme,
    this.transcriptions,
    required this.tooltips,
    this.onCancelModelResponse,
    required this.onFeedback,
    this.onRetrieve,
    required this.mimetypes,
  });

  final Stream<StreamingTranscript>? transcriptions;
  final Map<String, String> tooltips;

  final TextTheme AssistantTheme;
  final void Function()? onCancelModelResponse;
  final void Function(String?) onFeedback;
  final Future<List<Document>> Function(String)? onRetrieve;
  final List<String> mimetypes;

  @override
  State<UnnuChatWidget> createState() => _UnnuChatWidgetState();
}

const Duration _kChunkAnimationDuration = Durations.medium1;
typedef AttachmentSubscription =
    ({bool subscribed, StreamSubscription<StatusUpdate> subscription});

class _UnnuChatWidgetState extends State<UnnuChatWidget> {
  final _aiMsgId = IdTracker();
  final _strmTextMsgId = IdTracker();
  final _textMsgId = IdTracker();
  final _crossCache = CrossCache();
  final _userCache = chat_core.UserCache();
  final _scrollController = ScrollController();

  final _streamIdToMessageFragments = <String, List<StreamingTranscript>>{};

  final StreamingMessageController streamingMessageController = June.getState(
    StreamingMessageController.new,
  );
  final ChatWidgetController widgetController = June.getState(
    ChatWidgetController.new,
  );
  final ChatSessionController sessionController = June.getState(
    ChatSessionController.new,
  );
  final ChatSettingsController settingsController = June.getState(
    ChatSettingsController.new,
  );

  final McpToolsController toolsController = June.getState(
    McpToolsController.new,
  );
  // Store scroll state per stream ID
  final Map<String, double> _initialScrollExtents = {};
  final Map<String, bool> _reachedTargetScroll = {};

  final avatars = <String, String>{};
  Future<void> _loadAvatars() async {
    avatars[Avatars.User.id] = await copyAssetFile(Avatars.User.imageSource);
    avatars[Avatars.Assistant.id] = await copyAssetFile(
      Avatars.Assistant.imageSource,
    );
  }

  final currentUser = chat_core.User(
    id: Avatars.User.id,
    imageSource: Avatars.User.imageSource,
    name: Avatars.User.name,
  );
  final assistant = chat_core.User(
    id: Avatars.Assistant.id,
    imageSource: Avatars.Assistant.imageSource,
    name: Avatars.Assistant.name,
  );

  final List<AttachmentSubscription> _attachments = <AttachmentSubscription>[];

  @override
  void initState() {
    super.initState();
    _loadAvatars().then((value) {
      if (kDebugMode) {
        print('avatars[Avatars.User.id] = ${avatars[Avatars.User.id]}');
        print(
          'avatars[Avatars.Assistant.id] = ${avatars[Avatars.Assistant.id]}',
        );
      }

      _userCache
        ..updateUser(
          Avatars.User.id,
          chat_core.User(
            id: Avatars.User.id,
            imageSource:
                (avatars[Avatars.User.id] ?? '').isNotEmpty
                    ? Uri.file(
                      avatars[Avatars.User.id]!,
                      windows: Platform.isWindows,
                    ).normalizePath().toString()
                    : null,
            name: Avatars.User.Name,
          ),
        )
        ..updateUser(
          Avatars.Assistant.id,
          chat_core.User(
            id: Avatars.Assistant.id,
            imageSource:
                (avatars[Avatars.Assistant.id] ?? '').isNotEmpty
                    ? Uri.file(
                      avatars[Avatars.Assistant.id]!,
                      windows: Platform.isWindows,
                    ).normalizePath().toString()
                    : null,
            name: Avatars.Assistant.Name,
          ),
        )
        ..updateUser(
          'system',
          const chat_core.User(id: 'system', name: 'System'),
        )
        ..updateUser(
          'application',
          const chat_core.User(id: 'application', name: 'Application'),
        );
    });

    // streamingMessageController.resubscribe();

    if (widget.transcriptions != null) {
      widget.transcriptions?.listen(_handleStreamingTranscript);
    }

    if (widget.mimetypes.isNotEmpty &&
        !_attachments.any(
          (element) => element.subscribed,
        )) {
      _attachments.add((
        subscribed: true,
        subscription: StatusMonitor.updates.listen(
          (event) async {
            switch (event.status) {
              case StatusEventCode.NEW:
                if (context.mounted) {
                  MotionToast.success(
                    description: const Text('Adding ...'),
                  ).show(context);
                }
                widgetController.update(
                  status: SendIconState.loading,
                  nonblocking: false,
                );
              case StatusEventCode.PARSE:
                if (context.mounted) {
                  MotionToast.success(
                    description: const Text('Parsing ...'),
                  ).show(context);
                }
              case StatusEventCode.EMBED:
                if (context.mounted) {
                  MotionToast.success(
                    description: const Text('Embedding ...'),
                  ).show(context);
                }
              case StatusEventCode.PROCESSED:
                final file = File(
                  event.attachment.uri.toFilePath(
                    windows: Platform.isWindows,
                  ),
                );
                if (file.existsSync()) {
                  final fileMessage = chat_core.Message.file(
                    source: event.attachment.uri.toString(),
                    name: p.basename(
                      event.attachment.uri.toFilePath(
                        windows: Platform.isWindows,
                      ),
                    ),
                    id: ChatSettingsController.uuid.v7(),
                    createdAt: DateTime.now().toUtc(),
                    size: file.lengthSync(),
                    authorId: 'application',
                    metadata: <String, dynamic>{
                      'session.id': event.attachment.sessionId,
                      'status': event.status.name,
                    },
                  );
                  await streamingMessageController.messagingModel.chatController
                      .insertMessage(
                        fileMessage,
                      );
                }
                if (context.mounted) {
                  MotionToast.success(
                    description: const Text('Done'),
                  ).show(context);
                }
                widgetController.update(
                  status: SendIconState.idle,
                  nonblocking: false,
                );
              case StatusEventCode.COMPLETED:
                if (context.mounted) {
                  MotionToast.success(
                    description: const Text('Completed'),
                  ).show(context);
                }
                widgetController.update(
                  status: SendIconState.idle,
                  nonblocking: false,
                );
              case StatusEventCode.REMOVE:
                final fileName = event.attachment.uri.toFilePath(
                  windows: Platform.isWindows,
                );
                await streamingMessageController.messagingModel.chatController
                    .insertMessage(
                      chat_core.Message.system(
                        id: ChatSettingsController.uuid.v7(),
                        createdAt: DateTime.now().toUtc(),
                        authorId: 'application',
                        metadata: <String, dynamic>{
                          'session.id': event.attachment.sessionId,
                          'status': event.status.name,
                        },
                        text: 'Removed $fileName',
                      ),
                    );
                if (context.mounted) {
                  MotionToast.success(
                    toastDuration: const Duration(seconds: 15),
                    description: const Text('Removed'),
                  ).show(context);
                }
              case StatusEventCode.NOT_FOUND:
                if (context.mounted) {
                  MotionToast.error(
                    description: const Text('Not found'),
                  ).show(context);
                }
              case StatusEventCode.OPERATION_NOT_ALLOWED:
                if (context.mounted) {
                  MotionToast.error(
                    description: const Text('Operation not allowed'),
                  ).show(context);
                }
                widgetController.update(
                  status: SendIconState.idle,
                  nonblocking: false,
                );
              case StatusEventCode.EXCEEDS_QUOTA:
                if (context.mounted) {
                  MotionToast.error(
                    description: const Text('Exceeded quota'),
                  ).show(context);
                }
                widgetController.update(
                  status: SendIconState.idle,
                  nonblocking: false,
                );
              case StatusEventCode.NOOP:
                widgetController.update(
                  status: SendIconState.idle,
                  nonblocking: false,
                );
              case StatusEventCode.ABORTED:
                if (context.mounted) {
                  MotionToast.error(
                    description: const Text('Operation aborted'),
                  ).show(context);
                }
                widgetController.update(
                  status: SendIconState.idle,
                  nonblocking: false,
                );
              case StatusEventCode.PROMPT_GENERATION_ERROR:
                if (context.mounted) {
                  MotionToast.error(
                    description: const Text(
                      'Unable to complete, try reducing the context windows or prompt size',
                    ),
                  ).show(context);
                }
                widgetController.update(
                  status: SendIconState.idle,
                  nonblocking: false,
                );
              case StatusEventCode.MODEL_LOADING_ERROR:
                if (context.mounted) {
                  MotionToast.error(
                    description: const Text('Unable to load model'),
                  ).show(context);
                }
                widgetController.update(
                  status: SendIconState.idle,
                  nonblocking: false,
                );
            }
          },
        ),
      ));
    }

    if (kDebugMode) {
      print('UnnuChatWidgetState::initState:>');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider.value(
      value: streamingMessageController.messagingModel.streamManager,

      builder: (context, child) {
        return chat_ui.Chat(
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
                  ChatWidgetController.new,
                  builder:
                      (controller) => chat_ui.Composer(
                        topWidget: UnnuActionBar(
                          tooltips: widget.tooltips,
                        ),
                        hintText:
                            widget.tooltips['chatHint'] ?? 'Type a message ...',
                        sendIcon: SendIcon(
                          state: controller.changeNotifier.status,
                          nonblocking: controller.changeNotifier.nonblocking,
                          tooltips: widget.tooltips,
                        ),
                        sendButtonDisabled:
                            controller.changeNotifier.status ==
                                SendIconState.busy &&
                            !controller.changeNotifier.nonblocking,
                        sendButtonVisibilityMode:
                            chat_ui.SendButtonVisibilityMode.always,
                      ),
                ),
            imageMessageBuilder:
                (
                  context,
                  message,
                  index, {
                  required isSentByMe,
                  groupStatus,
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
                  required isSentByMe,
                  groupStatus,
                }) => FlyerChatSystemMessage(message: message, index: index),
            textMessageBuilder: (
              context,
              message,
              index, {
              required isSentByMe,
              groupStatus,
            }) {
              return FlyerChatTextMessage(
                message: message,
                index: index,
                showTime: false,
                showStatus: false,
                topWidget:
                    message.text.isNotEmpty
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment:
                              isSentByMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,
                          children: [
                            GNav(
                              iconSize: 16,
                              gap: 2,
                              padding: const EdgeInsets.all(4),
                              tabs: [
                                if (!isSentByMe)
                                  GButton(
                                    icon: Icons.report,
                                    onPressed:
                                        () => widget.onFeedback(message.text),
                                    iconColor: Colors.red,
                                    semanticLabel: widget.tooltips['feedback'] ?? 'Feedback',
                                  ),
                                GButton(
                                  icon: Icons.copy,
                                  active: message.text.isNotEmpty,
                                  onPressed: () async {
                                    final clipboard = SystemClipboard.instance;
                                    if (clipboard != null) {
                                      final text =
                                          '\n> ##### ${isSentByMe ? 'User' : 'Assisant'}\n---\n\n${message.text}\n';
                                      final item =
                                          DataWriterItem()..add(
                                            Formats.plainText(text),
                                          );
                                      await clipboard.write([item]);
                                      MotionToast.success(
                                        description: Text(
                                          widget.tooltips['copy'] ?? 'Copied',
                                        ),
                                      );
                                    }
                                  },
                                  semanticLabel: widget.tooltips['copy'] ?? 'Copied',
                                ),
                                GButton(
                                  icon: Icons.share,
                                  active: message.text.isNotEmpty,
                                  onPressed: () async {
                                    final params = ShareParams(
                                      // text: md.markdownToHtml(messages,
                                      //   extensionSet: md.ExtensionSet.gitHubWeb
                                      // ),
                                      text:
                                          '\n> ##### ${isSentByMe ? 'User' : 'Assisant'}\n---\n\n${message.text}\n',
                                      downloadFallbackEnabled: false,
                                    );
                                    final result = await SharePlus.instance
                                        .share(params);
                                    if (result.status ==
                                        ShareResultStatus.success) {
                                      MotionToast.success(
                                        description: Text(
                                          widget.tooltips['share'] ?? 'Share',
                                        ),
                                      );
                                    }
                                  },
                                  semanticLabel: widget.tooltips['share'] ?? 'Shared',
                                ),
                                if (!isSentByMe &&
                                    message.metadata != null &&
                                    message.metadata!['reasoning_content'] !=
                                        null)
                                  GButton(
                                    icon: Icons.lightbulb,
                                    active:
                                        message.metadata != null &&
                                        message.metadata!['reasoning_content'] !=
                                            null,
                                    onPressed: () async {
                                      if (message.metadata != null &&
                                          message.metadata!['reasoning_content'] !=
                                              null) {
                                        final text =
                                            message.metadata!['reasoning_content']
                                                as String;
                                        await showPopupCard<String>(
                                          context: context,
                                          builder: (context) {
                                            return PopupCard(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                side: BorderSide(
                                                  color:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .outlineVariant,
                                                ),
                                              ),
                                              child: GptMarkdown(text),
                                            );
                                          },
                                        );
                                      }
                                    },
                                    semanticLabel: widget.tooltips['thinking'] ?? 'Thinking',
                                  ),
                              ],
                            ),
                          ],
                        )
                        : null,
                receivedBackgroundColor: theme.highlightColor,
                sentBackgroundColor: theme.highlightColor,
                sentTextStyle: theme.textTheme.bodyMedium,
                receivedTextStyle: widget.AssistantTheme.bodyMedium,
                borderRadius: const BorderRadius.all(
                  Radius.circular(2),
                ),
              );
            },
            textStreamMessageBuilder: (
              context,
              message,
              index, {
              required isSentByMe,
              groupStatus,
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
                borderRadius: const BorderRadius.all(Radius.circular(2)),
                mode: TextStreamMessageMode.instantMarkdown,
                loadingText: widget.tooltips['thinking'] ?? 'Thinking',
              );
            },
            fileMessageBuilder:
                (
                  context,
                  fileMessage,
                  index, {
                  required isSentByMe,
                  groupStatus,
                }) =>
                    streamingMessageController.sessionId ==
                            (fileMessage.metadata?['session.id'] ?? '')
                        ? FlyerChatFileMessage(
                          message: fileMessage,
                          index: index,
                        )
                        : const SizedBox.shrink(),
            emptyChatListBuilder:
                (context) => chat_ui.EmptyChatList(
                  text: widget.tooltips['noMessages'] ?? 'No messages yet',
                ),
          ),
          chatController:
              streamingMessageController.messagingModel.chatController,
          crossCache: _crossCache,
          onMessageSend: _onSendPressed,
          onAttachmentTap:
              widget.mimetypes.isNotEmpty
                  ? () => _handleAttachmentTap(context)
                  : null,
          currentUserId: Avatars.User.id,
          userCache: _userCache,
          resolveUser:
              (id) async => _userCache.getOrResolve(
                id,
                (id) async => switch (id) {
                  'user' => currentUser,
                  'assistant' => assistant,
                  _ => null,
                },
              ),
          theme: chat_core.ChatTheme.fromThemeData(theme),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _sendButtonRouting() async {
    switch (widgetController.changeNotifier.status) {
      case SendIconState.busy:
        await _cancelResponse();
      case SendIconState.transcribing:
        await _sendTranscribedMessage();
      case SendIconState.loading:
        break;
      case SendIconState.idle:
        break;
    }
  }

  Future<void> _sendButtonText(String text) async {
    await _handleMessageSend(text);
  }

  void _onSendPressed(String text) {
    if (kDebugMode) {
      print('_onSendPressed: $text');
    }
    unawaited(text.isNotEmpty ? _sendButtonText(text) : _sendButtonRouting());
  }

  Future<void> _handleMessageSend(String text) async {
    final timeNow = DateTime.now().toUtc();
    final metadata = <String, dynamic>{
      'session.id': streamingMessageController.sessionId,
    };
    if (chat_core.isOnlyEmoji(text)) {
      metadata['isOnlyEmoji'] = true;
    }

    final message = chat_core.TextMessage(
      id: _textMsgId.nextId(),
      authorId: Avatars.User.id,
      createdAt: timeNow,
      sentAt: timeNow,
      text: text.trim(),
      metadata: metadata,
    );
    await streamingMessageController.insert(message);
    await _sendMessage(message);
  }

  Future<void> _sendTranscribedMessage() async {
    await streamingMessageController.onComplete(_strmTextMsgId.currentId);
    final msg = streamingMessageController.findById(_strmTextMsgId.currentId);
    if (msg == null) {
      final _msg = chat_core.TextStreamMessage(
        id: _strmTextMsgId.currentId,
        authorId: Avatars.User.id,
        createdAt: DateTime.now().toUtc(),
        streamId: _strmTextMsgId.currentId,
      );
      streamingMessageController.messagingModel.chatController.removeMessage(
        _msg,
      );
      {
        widgetController.update(
          status: SendIconState.idle,
          nonblocking: false,
        );
      }
    } else {
      switch (msg) {
        case chat_core.TextMessage():
          {
            if (msg.text.isNotEmpty) {
              await _sendMessage(msg);
            } else {
              await streamingMessageController.messagingModel.chatController
                  .removeMessage(
                    msg,
                  );
            }
          }
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
    {
      widgetController.update(
        status: SendIconState.transcribing,
        nonblocking: false,
      );
    }
    final msg = streamingMessageController.findById(_strmTextMsgId.currentId);

    if (msg != null) {
      switch (msg) {
        case chat_core.TextMessage():
          {
            final strmId = _strmTextMsgId.nextId();
            var metadata =
                msg.metadata ??
                {
                  'message.id': _strmTextMsgId.currentId,
                  'session.id': streamingMessageController.sessionId,
                };
            metadata['stream_status'] = transcript.type.name;
            metadata['allow.updates'] = true;
            final streamMessage = chat_core.TextStreamMessage(
              id: strmId,
              authorId: msg.authorId,
              createdAt: msg.createdAt,
              streamId: strmId,
              metadata: metadata,
              replyToMessageId: msg.replyToMessageId,
              seenAt: msg.seenAt,
              updatedAt: msg.updatedAt,
              reactions: msg.reactions,
            );
            final text = msg.text;
            await streamingMessageController.messagingModel.chatController
                .removeMessage(
                  msg,
                );
            await streamingMessageController.onStartStream(
              strmId,
              streamMessage,
            );
            streamingMessageController.addChunk(strmId, text);
          }
        case chat_core.SystemMessage():
          {
            streamingMessageController.addChunk(
              _strmTextMsgId.currentId,
              msg.text,
            );
          }
        case chat_core.TextStreamMessage():
          {
            switch (transcript.type) {
              case TranscriptionFragmentType.start:
                break;
              case TranscriptionFragmentType.chunk:
                break;
              case TranscriptionFragmentType.partial:
                {
                  _streamIdToMessageFragments[_strmTextMsgId.currentId] =
                      _streamIdToMessageFragments[_strmTextMsgId.currentId] ??
                      List<StreamingTranscript>.empty(growable: true);
                }
              case TranscriptionFragmentType.complete:
                {
                  _streamIdToMessageFragments[_strmTextMsgId.currentId] =
                      _streamIdToMessageFragments[_strmTextMsgId.currentId] ??
                      List<StreamingTranscript>.empty(growable: true);
                }
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
          'session.id': streamingMessageController.sessionId,
          'stream_status': transcript.type.name,
          'allow.updates': true,
        },
      );
      await streamingMessageController.onStartStream(
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
    switch (transcript.type) {
      case TranscriptionFragmentType.start:
        {
          if (transcript.text.isNotEmpty) {
            if (!_streamIdToMessageFragments.containsKey(
              _strmTextMsgId.currentId,
            )) {
              await _startStreamingTranscript(transcript);
            }
            streamingMessageController.addChunk(
              _strmTextMsgId.currentId,
              transcript.text,
            );
          }
        }
      case TranscriptionFragmentType.chunk:
        {
          if (transcript.text.isNotEmpty) {
            if (!_streamIdToMessageFragments.containsKey(
              _strmTextMsgId.currentId,
            )) {
              await _startStreamingTranscript(transcript);
            }
            streamingMessageController.addChunk(
              _strmTextMsgId.currentId,
              transcript.text,
            );
          }
        }
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
          await streamingMessageController.onComplete(_strmTextMsgId.currentId);
          await _sendTranscribedMessage();
        }
      case TranscriptionFragmentType.end:
        {
          if (_streamIdToMessageFragments.containsKey(
            _strmTextMsgId.currentId,
          )) {
            await streamingMessageController.onComplete(
              _strmTextMsgId.currentId,
            );
            await _sendTranscribedMessage();
          }
        }
    }
  }

  Future<void> _handleAttachmentTap(BuildContext context) async {
    if (kDebugMode) {
      print('_handleAttachmentTap()');
    }
    switch (widgetController.changeNotifier.status) {
      case SendIconState.idle:
        await settingsController.handleAttach(
          streamingMessageController.sessionId,
          widget.mimetypes,
        );
      case SendIconState.busy:
      case SendIconState.loading:
      case SendIconState.transcribing:
        if (context.mounted) {
          MotionToast.warning(
            toastDuration: const Duration(seconds: 5),
            description: Text(
              widget.tooltips['busy'] ?? 'Busy',
            ),
          ).show(context);
        }
    }
  }

  Future<void> _cancelResponse() async {
    {
      widgetController.update(
        nonblocking: false,
      );
    }

    widget.onCancelModelResponse?.call();

    await streamingMessageController.onStopStream(
      streamingMessageController.messagingModel.sessionId,
    );
    final aiMsg = streamingMessageController.findById(_aiMsgId.currentId);
    if (aiMsg != null) {
      final usrMsg = streamingMessageController.findById(
        aiMsg.replyToMessageId!,
      );
      await streamingMessageController.messagingModel.chatController
          .removeMessage(
            aiMsg,
          );
      await streamingMessageController.messagingModel.chatController
          .removeMessage(
            usrMsg!,
          );

      _initialScrollExtents.remove(aiMsg.id);
      _reachedTargetScroll.remove(aiMsg.id);
    }
    {
      widgetController.update(
        status: SendIconState.idle,
        nonblocking: false,
      );
    }
  }

  Future<void> _sendMessage(chat_core.Message message) async {
    {
      widgetController.update(
        status: SendIconState.busy,
        nonblocking: true,
      );
    }

    final sessionId = message.metadata!['session.id'] as String;

    var streamId = _aiMsgId.nextId();
    chat_core.TextStreamMessage? streamMessage;

    try {
      var isFirstChunk = true;
      _reachedTargetScroll[streamId] = false;

      final ragEnabled = settingsController.getSetting(sessionId).enableSearch;

      final chatMessageTools =
          (toolsController.actives[sessionId] ?? <ActiveTool>[]);
      final toolsRegistry = toolsController.ToolRegistry;
      final clientsRegistry = toolsController.ClientRegistry;
      final tools = chatMessageTools.map(
        (e) => Tool.fromFunction(
          name: e.tool.name,
          description: toolsRegistry[e.tool]?.description ?? '',
          inputJsonSchema:
              toolsRegistry[e.tool]?.inputSchema.toJson() ??
              <String, dynamic>{},
          func:
              (Map<String, dynamic> input) async =>
                  clientsRegistry[Uri.tryParse(e.tool.reference_id) ?? Uri()]
                      ?.callTool(
                        mcp.CallToolRequestParams(
                          name: e.tool.name,
                          arguments: input,
                        ),
                      ) ??
                  mcp.CallToolResult.fromContent(isError: true, content: []),
        ),
      );
      final meta = switch (message) {
        chat_core.TextMessage() =>
          (ragEnabled && widget.onRetrieve != null)
              ? {
                'rag.enabled': ragEnabled,
                'rag.data': {
                  UnnuQueryFragmentType.USER_QUERY.name: message.text,
                  UnnuQueryFragmentType.CURRENT_INFO.name: (await widget
                          .onRetrieve!(message.text))
                      .map(
                        (e) => e.pageContent,
                      )
                      .map(
                        (e) => e.trim(),
                      )
                      .where(
                        (element) => element.isNotEmpty,
                      )
                      .join('\n'),
                },
              }
              : const <String, dynamic>{},
        chat_core.SystemMessage() =>
          (ragEnabled && widget.onRetrieve != null)
              ? {
                'rag.enabled': ragEnabled,
                'rag.data': {
                  UnnuQueryFragmentType.USER_QUERY.name: message.text,
                  UnnuQueryFragmentType.CURRENT_INFO.name: (await widget
                          .onRetrieve!(message.text))
                      .map(
                        (e) => e.pageContent,
                      )
                      .map(
                        (e) => e.trim(),
                      )
                      .where(
                        (element) => element.isNotEmpty,
                      )
                      .join('\n'),
                },
              }
              : const <String, dynamic>{},
        _ => const <String, dynamic>{},
      };

      final chatMessage = switch (message) {
        chat_core.TextMessage() =>
          message.authorId == Avatars.User.id
              ? UnnuAIModel.transformToRAG(
                ChatMessage.humanText(
                  message.text,
                ),
                metadata: meta,
              )
              : message.authorId == Avatars.Assistant.id
              ? ChatMessage.ai(message.text)
              : ChatMessage.custom(message.text, role: message.authorId),
        chat_core.SystemMessage() => UnnuAIModel.transformToRAG(
          ChatMessage.system(
            message.text,
          ),
          metadata: meta,
        ),
        _ => ChatMessage.custom(
          '\n\n$message',
          role:
              message.authorId == Avatars.User.id
                  ? ChatMessageRole.human.name
                  : message.authorId == Avatars.Assistant.id
                  ? ChatMessageRole.ai.name
                  : message.authorId,
        ),
      };

      // This implements a scrolling behavior where we stop auto-scrolling once the
      // generated message reaches the top of the viewport. For this to work properly,
      // make sure to set `shouldScrollToEndWhenAtBottom` to false in `ChatAnimatedList`.
      await sessionController.chatSessionVM.ai.setup(tools: tools.toList());
      var replyToId = message.id;
      var replyToType = 'user';
      final subscription = sessionController.chatSessionVM.ai.chat.listen(
        (chunk) async {
          final textChunk = chunk.output.content;
          // Ensure stream message exists before adding chunk
          if (chunk.metadata['message.type'] == 'response') {
            await streamingMessageController.onChatResult(chunk);
          }
          if (textChunk.isNotEmpty) {
            if (isFirstChunk) {
              // On the first valid chunk, ensure the message is inserted.
              // This handles both non-thinking models and thinking models where
              // the response arrives before the timer.
              isFirstChunk = false;
              // Create and insert the message ON the first chunk
              final createdWhen = DateTime.now().toUtc();
              final metainfo = {
                'session.id': sessionId,
                'replyTo.id': replyToId,
                'replyTo.type': replyToType,
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
              await streamingMessageController.onStartStream(
                streamId,
                streamMessage!,
              );

              // This is needed because we use shouldScrollToEndWhenAtBottom: false,
              // due to custom scroll logic below, so we must also scroll to the
              // thinking label manually.
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!_scrollController.hasClients || !mounted) return;
                _initialScrollExtents[streamId] =
                    _scrollController.position.maxScrollExtent;
                await _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: Durations.short4,
                  curve: Curves.linearToEaseOut,
                );
              });
            }

            // Ensure stream message exists before adding chunk
            if (streamMessage != null &&
                chunk.metadata['message.type'] == 'token') {
              // Send chunk to the manager - this triggers notifyListeners
              streamingMessageController.addChunk(streamId, textChunk);
            }

            // Only attempt scrolling if:
            // 1. We haven't already reached our target scroll position
            // 2. The chat is actually scrollable (maxScrollExtent > 0)
            // Note: This won't work when the UI first renders and isn't scrollable yet.
            // That would require measuring content height instead of maxScrollExtent.
            // Please suggest how to do this if possible.

            WidgetsBinding.instance.addPostFrameCallback((_) async {
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
                  await _scrollController.animateTo(
                    targetScroll,
                    duration: Durations.short4,
                    curve: Curves.linearToEaseOut,
                  );
                  // Mark that we've reached the target for this stream
                  _reachedTargetScroll[streamId] = true;
                } else {
                  // If we haven't reached target position yet, scroll to bottom
                  await _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: Durations.short4,
                    curve: Curves.linearToEaseOut,
                  );
                }
              }
            });
          }
          // Reset on tool call
          if (chunk.output.toolCalls.isNotEmpty) {
            // Clean up scroll state for this stream ID when done/errored
            _initialScrollExtents.remove(streamId);
            _reachedTargetScroll.remove(streamId);

            isFirstChunk = true;
            replyToType = 'tool';
            replyToId = streamId;

            streamId = _aiMsgId.nextId();
            _reachedTargetScroll[streamId] = false;
          }
        },
        onError: (err, stacktrace) async {
          if (kDebugMode) {
            debugPrintStack(label: '$err');
          }
          await streamingMessageController.onError(streamId, err.toString());

          // Clean up scroll state for this stream ID when done/errored
          _initialScrollExtents.remove(streamId);
          _reachedTargetScroll.remove(streamId);
        },
        cancelOnError: true,
      );

      final executor = AgentExecutor(
        agent: sessionController.chatSessionVM.ai.agent,
        memory: ConversationBufferMemory(),
      );
      final completer = Completer<String>();
      Future<Map<String, dynamic>> run(Completer<String> _completer) async {
        final res = await executor.invoke({
          BaseChain.defaultInputKey: chatMessage,
        });
        completer.complete((res[BaseChain.defaultOutputKey] ?? '') as String);
        return res;
      }

      await run(completer);

      await completer.future.whenComplete(() async {
        // Stream completed successfully (only if message was created)
        if (streamMessage != null) {
          await streamingMessageController.onComplete(streamId);
        }

        await subscription.cancel();
        // await sessionController.chatSessionVM.ai.teardown();

        // Clean up scroll state for this stream ID
        // _initialScrollExtents.remove(streamId);
        // _reachedTargetScroll.remove(streamId);
      });
    } on Exception catch (err, stacktrace) {
      if (kDebugMode) {
        debugPrintStack(label: '$err', stackTrace: stacktrace);
      }
      // Catch other potential errors during stream processing
      await streamingMessageController.onError(streamId, err);
    } finally {
      // Clean up scroll state for this stream ID when done/errored
      _initialScrollExtents.remove(streamId);
      _reachedTargetScroll.remove(streamId);

      await sessionController.chatSessionVM.ai.teardown();
    }

    widgetController.update(
      status: SendIconState.idle,
      nonblocking: true,
    );
  }
}
