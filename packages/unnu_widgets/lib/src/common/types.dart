import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:june/june.dart';
import 'package:langchain_core/chat_models.dart' as cm;
import 'package:langchain_core/llms.dart';
import 'package:quiver/collection.dart';
import 'package:unnu_ai_model/unnu_ai_model.dart';
import 'package:unnu_shared/unnu_shared.dart';
import 'package:uuid/uuid.dart';

import 'config.dart';
import '../components/sembast_chat_controller.dart';
import '../components/composer_action_bar.dart';
import '../components/unnu_stream_manager.dart';

enum TranscriptionFragmentType { start, chunk, partial, complete, end }

typedef StreamingTranscript = ({TranscriptionFragmentType type, String text});

typedef StreamMessageProperties =
    ({String streamId, String sessionId, DateTime createdTime});

enum SendIconState {
  idle(0),
  busy(1),
  loading(2),
  transcribing(3);

  final int value;

  const SendIconState(this.value);

  static SendIconState fromValue(int value) => switch (value) {
    0 => idle,
    1 => busy,
    2 => loading,
    3 => transcribing,
    _ => throw ArgumentError('Unknown value for SendIconState: $value'),
  };
}

class StreamingMessageVM {
  UnnuStreamManager streamManager;
  Map<String, TextStreamMessage> active;
  Map<String, StreamSubscription<LLMResult>> subscriptions;
  StreamSubscription<LLMResult> assistant;
  ChatController chatController;
  BiMap<String, String> responses;
  String sessionId;
  Dialoguizer parser;

  StreamingMessageVM({
    required this.streamManager,
    required this.active,
    required this.subscriptions,
    required this.assistant,
    required this.chatController,
    required this.responses,
    required this.sessionId,
    required this.parser,
  });

  StreamingMessageVM copyWith({
    UnnuStreamManager? streamManager,
    Map<String, TextStreamMessage>? active,
    Map<String, StreamSubscription<LLMResult>>? subscriptions,
    StreamSubscription<LLMResult>? assistant,
    SembastChatController? chatController,
    BiMap<String, String>? responses,
    String? sessionId,
    Dialoguizer? parser,
  }) {
    return StreamingMessageVM(
      streamManager: streamManager ?? this.streamManager,
      active: active ?? this.active,
      subscriptions: subscriptions ?? this.subscriptions,
      assistant: assistant ?? this.assistant,
      chatController: chatController ?? this.chatController,
      responses: responses ?? this.responses,
      sessionId: sessionId ?? this.sessionId,
      parser: parser ?? this.parser,
    );
  }
   static StreamingMessageVM getDefaults() {

    return StreamingMessageVM(
      sessionId: Uuid().v4(),
      streamManager: UnnuStreamManager(
        chatController: InMemoryChatController(),
        chunkAnimationDuration: Durations.medium1,
      ),
      subscriptions: <String, StreamSubscription<LLMResult>>{},
      active: <String, TextStreamMessage>{},
      responses: HashBiMap<String, String>(),
      assistant: Stream<LLMResult>.empty().listen((event) {}),
      chatController: InMemoryChatController(),
      parser: Dialoguizer(
        separators: RegExp(''),
        reasoning: false,
        thinking: (start_tag: '<think>', end_tag: '</think>'),
      ),
    );
  }

  @override
  String toString() {
    return 'StreamingMessageVM(streamManager: $streamManager, active: $active, subscriptions: $subscriptions, assistant: $assistant, chatController: $chatController, responses: $responses, sessionId: $sessionId, parser: $parser)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is StreamingMessageVM &&
        other.streamManager == streamManager &&
        mapEquals(other.active, active) &&
        mapEquals(other.subscriptions, subscriptions) &&
        other.assistant == assistant &&
        other.chatController == chatController &&
        other.responses == responses &&
        other.sessionId == sessionId &&
        other.parser == parser;
  }

  @override
  int get hashCode {
    return streamManager.hashCode ^
        active.hashCode ^
        subscriptions.hashCode ^
        assistant.hashCode ^
        chatController.hashCode ^
        responses.hashCode ^
        sessionId.hashCode ^
        parser.hashCode;
  }
}

class StreamingMessageController extends JuneState {
  static final _uuid = Uuid();
  StreamingMessageVM messagingModel = StreamingMessageVM.getDefaults();

  static String newUuid() {
    return _uuid.v4();
  }

  String get sessionId => messagingModel.sessionId;

  void setChatController(SembastChatController chatController) {
    messagingModel = messagingModel.copyWith(
      chatController: chatController,
      streamManager: UnnuStreamManager(
        chatController: chatController,
        chunkAnimationDuration: Durations.medium1,
      ),
    );
  }

  @override
  void dispose() {
    messagingModel.assistant.cancel();
    super.dispose();
  }

  Map<String, List<Message>> get chats =>
      UnmodifiableMapView<String, List<Message>>(
        groupBy<Message, String>(
          (messagingModel.chatController as SembastChatController).allMessages,
          (element) => element.metadata?['session.id'] ?? '',
        ),
      );

  List<Message> get messages => UnmodifiableListView(
    messagingModel.chatController.messages.where(
      (element) =>
          messagingModel.sessionId == element.metadata!['session.id'] &&
          element.runtimeType != TextStreamMessage,
    ),
  );

  Message? findById(String id) {
    return messagingModel.chatController.messages.firstWhereOrNull(
      (element) => element.id == id,
    );
  }

  Future<void> insert(Message message) async {
    final records = chats[sessionId] ?? [];
    await messagingModel.chatController.insertMessage(
      message,
      index: records.length,
    );
  }

  void resubscribe() {
    messagingModel.assistant.onData((event) async {
      if (event.metadata.containsKey('message.id')) {
        if (kDebugMode) {
          print('StrmngMsgCntrl:onData $event');
        }
        final messageId = event.metadata['message.id'] as String;
        final streamId = getStreamId(messageId);
        if (streamId != null) {
          final oldMessage = getMessage(streamId);
          final oldMetadata =
              oldMessage?.metadata ??
              {'session.id': messagingModel.sessionId, 'message.id': messageId};
          final newMetadata = <String, dynamic>{};
          newMetadata.addEntries(oldMetadata.entries);
          newMetadata['allow.updates'] = false;
          newMetadata['is.streaming'] = false;
          if (chat_core.isOnlyEmoji(event.output)) {
            newMetadata['isOnlyEmoji'] = true;
          }

          if (messagingModel.parser.tags != null) {
            if (event.output.startsWith(
              RegExp(
                messagingModel.parser.tags!.start_tag,
                caseSensitive: false,
              ),
            )) {
              if (kDebugMode) {
                print('messagingModel:resubscribe parsing ...');
              }
              final segments = messagingModel.parser.extract(event.output);
              if (segments.containsKey('thought')) {
                newMetadata['parsed.thx'] = segments['thought'] ?? '';
              }

              if (segments.containsKey('context')) {
                newMetadata['parsed.ctx'] = segments['context'] ?? '';
              }
              if (kDebugMode) {
                final resp = segments['response'];
                print('UnnuChatWidget::responses.listen $resp');
              }
              newMetadata['parsed.out'] = segments['response'];
            }
          }
          if (kDebugMode) {
            print('messagingModel:resubscribe newMetadata $newMetadata');
          }
          final newMessage = chat_core.TextMessage(
            id: oldMessage!.id,
            authorId: Avatars.Assistant.id,
            createdAt: oldMessage.createdAt,
            sentAt: DateTime.now().toUtc(),
            replyToMessageId: oldMessage.replyToMessageId,
            text:
                newMetadata.containsKey('parsed.out')
                    ? newMetadata['parsed.out'] as String
                    : event.output,
            metadata: newMetadata,
          );
          if (kDebugMode) {
            print(
              'UnnuChat::responses.listen() updateMessages:\nold: $oldMessage\nnew: $newMessage',
            );
          }
          await messagingModel.chatController.updateMessage(
            oldMessage,
            newMessage,
          );
          messagingModel.responses.remove(messageId);
          messagingModel.active.remove(streamId);
          setState();
        }
      }
    });
  }

  void addSubscription(
    String streamId,
    StreamSubscription<LLMResult> subscriber,
  ) {
    messagingModel.subscriptions[streamId] = subscriber;
  }

  void addChunk(String streamId, String chunk) {
    messagingModel.streamManager.addChunk(streamId, chunk);
  }

  Future<void> onStartStream(String streamId, TextStreamMessage message) async {
    await messagingModel.chatController.insertMessage(message);
    messagingModel.streamManager.startStream(streamId, message);
    messagingModel.active[streamId] = message;
    if (message.metadata != null &&
        message.metadata!.containsKey('message.id')) {
      final msgId = message.metadata!['message.id'] as String;
      messagingModel.responses[msgId] = streamId;
      if (kDebugMode) {
        print('onStartStream $msgId <-> $streamId | ${message.streamId}');
      }
    }
  }

  StreamSubscription<LLMResult>? getSubscription(String streamId) {
    return messagingModel.subscriptions[streamId];
  }

  String? getStreamId(String messageId) {
    return messagingModel.responses[messageId];
  }

  Message? getMessage(String streamId) {
    return messagingModel.active[streamId];
  }

  Future<void> onComplete(String streamId) async {
    if (kDebugMode) {
      print('StrmngMsgCntrl:onComplete $streamId');
    }
    if (messagingModel.active.containsKey(streamId)) {
      await messagingModel.streamManager.completeStream(streamId);
    }
    if (messagingModel.subscriptions.containsKey(streamId)) {
      await messagingModel.subscriptions[streamId]!.cancel();
      messagingModel.subscriptions.remove(streamId);
    }
    setState();
    if (kDebugMode) {
      print('StrmMsgCtrl:onComplete:>');
    }
  }

  void cleanup(String streamId) {
    messagingModel.responses.inverse.remove(streamId);
    messagingModel.subscriptions.remove(streamId);
    messagingModel.active.remove(streamId);
    setState();
    if (kDebugMode) {
      print('StrmngMsgCntrl:cleanup:>');
    }
  }

  Future<void> onError(String streamId, Object err) async {
    if (messagingModel.subscriptions.containsKey(streamId)) {
      await messagingModel.subscriptions[streamId]!.cancel();
      messagingModel.subscriptions.remove(streamId);
    }
    if (messagingModel.active.containsKey(streamId)) {
      await messagingModel.streamManager.errorStream(streamId, err);
      messagingModel.active.remove(streamId);
    }
    if (messagingModel.responses.inverse.containsKey(streamId)) {
      messagingModel.responses.inverse.remove(streamId);
    }
    setState();
    if (kDebugMode) {
      print('StrmngMsgCntrl:onError:>');
    }
  }

  Future<void> onStopStream(String sessionId) async {
    final cancelables =
        messagingModel.active.values
            .where((elememt) => elememt.metadata?['session.id'] == sessionId)
            .map((element) => element.streamId)
            .toSet();

    for (var streamId in cancelables) {
      if (messagingModel.subscriptions.containsKey(streamId)) {
        await messagingModel.subscriptions[streamId]!.cancel();
        messagingModel.subscriptions.remove(streamId);
      }
      await messagingModel.streamManager.errorStream(
        streamId,
        'Stream stopped by user',
      );
      if (messagingModel.active.containsKey(streamId)) {
        messagingModel.active.remove(streamId);
      }
      if (messagingModel.responses.inverse.containsKey(streamId)) {
        messagingModel.responses.inverse.remove(streamId);
      }
    }
    setState();
    if (kDebugMode) {
      print('StrmngMsgCntrl:onStopStream:>');
    }
  }

  Future<void> clearMessages() async {
    if (kDebugMode) {
      print('clearMessages: ${messagingModel.sessionId}');
    }
    final sessionMessages =
        messagingModel.chatController.messages
            .where(
              (element) =>
                  messagingModel.sessionId == element.metadata!['session.id'],
            )
            .toList();
    for (var element in sessionMessages) {
      await messagingModel.chatController.removeMessage(element);
    }
    final newSessionId = newUuid();
    messagingModel = messagingModel.copyWith(sessionId: newSessionId);
    (messagingModel.chatController as SembastChatController).activeSessionId = newSessionId;
    await messagingModel.chatController.setMessages([]);
    setState();
  }

  Future<void> newChat() async {
    final newSessionId = newUuid();
    messagingModel = messagingModel.copyWith(sessionId: newSessionId);
    (messagingModel.chatController as SembastChatController).activeSessionId = newSessionId;
    await messagingModel.chatController.setMessages([]);
    setState();
  }

  Future<void> loadChat(String sessionId) async {
    if (kDebugMode) {
      print('loadChat $sessionId');
    }
    final sessionMessages = chats[sessionId] ?? <Message>[];
    if (kDebugMode) {
      print('loadChat messages $sessionMessages');
    }
    await messagingModel.chatController.setMessages(sessionMessages);
    (messagingModel.chatController as SembastChatController).activeSessionId = sessionId;
    messagingModel = messagingModel.copyWith(sessionId: sessionId);
    setState();
  }
}

class ChatSessionVM {
  ChatSession activeSession;
  UnnuAIModel ai;

  ChatSessionVM({required this.activeSession, required this.ai});

  static ChatSessionVM getDefaults() {
    return ChatSessionVM(
      activeSession: ChatSession.dummy(),
      ai: UnnuAIModel(
        model: LlamaCppProvider(
          defaultOptions: LcppOptions(
            concurrencyLimit: 1000,
            defaultIsStreaming: true,
          ),
        ),
      ),
      //     sessions: <String, List<Message>>{},
    );
  }

  ChatSessionVM copyWith({ChatSession? activeSession, UnnuAIModel? ai}) {
    return ChatSessionVM(
      activeSession: activeSession ?? this.activeSession,
      ai: ai ?? this.ai,
    );
  }

  @override
  String toString() => 'ChatSessionVM(activeSession: $activeSession, ai: $ai)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatSessionVM &&
        other.activeSession == activeSession &&
        other.ai == ai;
  }

  @override
  int get hashCode => activeSession.hashCode ^ ai.hashCode;
}

class ChatSessionController extends JuneState {
  ChatSessionVM chatSessionVM = ChatSessionVM.getDefaults();

  Future<void> newChat() async {
    await chatSessionVM.ai.reset();
    chatSessionVM = chatSessionVM.copyWith(
      activeSession: chatSessionVM.ai.getChatSession(history: []),
    );
    setState();
  }

  void loadChat(List<Message> messages) {
    chatSessionVM.ai.reset();
    final chatMessages =
        messages
            .whereType<chat_core.TextMessage>()
            .map(
              (message) =>
                  message.authorId == Avatars.User.id
                      ? cm.ChatMessage.humanText(message.text)
                      : message.authorId == Avatars.Assistant.id
                      ? cm.ChatMessage.ai(message.text)
                      : cm.ChatMessage.system(message.text),
            )
            .toList();
    chatSessionVM.ai.history = chatMessages;
    chatSessionVM = chatSessionVM.copyWith(
      activeSession: chatSessionVM.ai.getChatSession(history: chatMessages),
    );
    setState();
  }

  void clearMessages() {
    chatSessionVM.ai.history = [];
    chatSessionVM.activeSession.rewrite([]);
    setState();
  }
}

class ChatWidgetVM {
  SendIconState status;
  bool nonblocking;
  ChatWidgetVM({required this.status, required this.nonblocking});

  static ChatWidgetVM getDefaults() {
    return ChatWidgetVM(status: SendIconState.idle, nonblocking: true);
  }

  ChatWidgetVM copyWith({SendIconState? status, bool? nonblocking}) {
    return ChatWidgetVM(
      status: status ?? this.status,
      nonblocking: nonblocking ?? this.nonblocking,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'status': status.value, 'nonblocking': nonblocking});

    return result;
  }

  factory ChatWidgetVM.fromMap(Map<String, dynamic> map) {
    return ChatWidgetVM(
      status: SendIconState.fromValue(map['status']),
      nonblocking: map['nonblocking'] ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatWidgetVM.fromJson(String source) =>
      ChatWidgetVM.fromMap(json.decode(source));

  @override
  String toString() =>
      'ChatWidgetVM(status: $status, nonblocking: $nonblocking)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatWidgetVM &&
        other.status == status &&
        other.nonblocking == nonblocking;
  }

  @override
  int get hashCode => status.hashCode ^ nonblocking.hashCode;
}

class ChatWidgetController extends JuneState {
  ChatWidgetVM viewModel = ChatWidgetVM.getDefaults();

  Widget emptyChatList(BuildContext context, Map<String, String> tooltips) {
    return EmptyChatList(text: tooltips['noMessages'] ?? 'No messages yet');
  }

  Widget? actionBar(Map<String, String> tooltips) {
    return ComposerActionBar(
      buttons: [
        ComposerActionButton(
          icon: Icons.delete_sweep,
          title: tooltips['clearAll'] ?? 'Clear All',
          onPressed: () {
            final chatSessionController = June.getState(
              () => ChatSessionController(),
            );
            final streamingMessageController = June.getState(
                  () => StreamingMessageController(),
            );
            chatSessionController.clearMessages();
            streamingMessageController.clearMessages();

          },
          destructive: true,
        ),
      ],
    );
  }

  Widget sendIcon(BuildContext context, Map<String, String> tooltips) {
    if (kDebugMode) {
      print('sendIcon (${viewModel.status}, ${viewModel.nonblocking})');
    }
    String message = tooltips['send'] ?? 'Send';
    IconData iconData = Icons.send;

    switch (viewModel.status) {
      case SendIconState.busy:
        message = tooltips['cancel'] ?? 'Cancel';
        iconData = Icons.stop_circle;
        break;
      case SendIconState.loading:
        message = tooltips['busy'] ?? 'Busy';
        ;
        iconData = Icons.hourglass_empty;
        break;
      case SendIconState.transcribing:
        message = tooltips['send'] ?? 'Send';
        iconData = Icons.chat;
        break;
      case SendIconState.idle:
        message = tooltips['send'] ?? 'Send';
        iconData = Icons.send;
        break;
    }

    return viewModel.status != SendIconState.idle
        ? Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Tooltip(
            message: message,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SpinKitDualRing(color: Theme.of(context).colorScheme.primary),
                Icon(
                  iconData,
                  color: viewModel.nonblocking ? Colors.red : Colors.grey,
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
