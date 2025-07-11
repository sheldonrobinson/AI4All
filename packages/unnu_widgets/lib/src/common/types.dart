import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:june/june.dart';
import 'package:langchain_core/chat_models.dart' as cm;
import 'package:langchain_core/llms.dart';
import 'package:quiver/collection.dart';
import 'package:unnu_ai_model/unnu_ai_model.dart';
import 'package:unnu_shared/unnu_shared.dart';
import 'package:uuid/uuid.dart';

import '../components/sembast_chat_controller.dart';
import '../components/unnu_stream_manager.dart';
import 'config.dart';

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

@immutable
class StreamingMessageView {
  const StreamingMessageView({
    required this.streamManager,
    required this.active,
    required this.subscriptions,
    required this.assistant,
    required this.chatController,
    required this.responses,
    required this.sessionId,
    required this.parser,
  });
  final UnnuStreamManager streamManager;
  final Map<String, TextStreamMessage> active;
  final Map<String, StreamSubscription<LLMResult>> subscriptions;
  final StreamSubscription<LLMResult> assistant;
  final ChatController chatController;
  final BiMap<String, String> responses;
  final String sessionId;
  final Dialoguizer parser;

  StreamingMessageView copyWith({
    UnnuStreamManager? streamManager,
    Map<String, TextStreamMessage>? active,
    Map<String, StreamSubscription<LLMResult>>? subscriptions,
    StreamSubscription<LLMResult>? assistant,
    ChatController? chatController,
    BiMap<String, String>? responses,
    String? sessionId,
    Dialoguizer? parser,
  }) {
    return StreamingMessageView(
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

  static StreamingMessageView getDefaults() {
    return StreamingMessageView(
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
      ),
    );
  }

  @override
  String toString() {
    return '''
    StreamingMessageVM(streamManager: $streamManager, active: $active,
    subscriptions:  $subscriptions, assistant: $assistant, 
    chatController: $chatController, responses: $responses, 
    sessionId: $sessionId, parser: $parser)
    ''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is StreamingMessageView &&
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
  StreamingMessageView messagingModel = StreamingMessageView.getDefaults();

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
          messagingModel.chatController is SembastChatController
              ? (messagingModel.chatController as SembastChatController)
                  .allMessages
              : messagingModel.chatController.messages,
          (element) => (element.metadata?['session.id'] ?? '') as String,
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
        final messageId = event.metadata['message.id'] as String;
        final streamId = getStreamId(messageId);
        if (streamId != null) {
          final oldMessage = getMessage(streamId);
          final oldMetadata =
              oldMessage?.metadata ??
              {'session.id': messagingModel.sessionId, 'message.id': messageId};
          final newMetadata =
              <String, dynamic>{}..addEntries(oldMetadata.entries);
          newMetadata['allow.updates'] = false;
          newMetadata['is.streaming'] = false;
          if (chat_core.isOnlyEmoji(event.output)) {
            newMetadata['isOnlyEmoji'] = true;
          }

          if (messagingModel.parser.reasoning) {
            if (event.output.startsWith(
              RegExp(
                '<think>',
                caseSensitive: false,
              ),
            )) {
              final segments = messagingModel.parser.extract(event.output);
              if (segments.containsKey('thought')) {
                newMetadata['parsed.thx'] = segments['thought'] ?? '';
              }

              if (segments.containsKey('context')) {
                newMetadata['parsed.ctx'] = segments['context'] ?? '';
              }
              newMetadata['parsed.out'] = segments['response'];
            }
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
    if (messagingModel.active.containsKey(streamId)) {
      await messagingModel.streamManager.completeStream(streamId);
    }
    if (messagingModel.subscriptions.containsKey(streamId)) {
      await messagingModel.subscriptions[streamId]!.cancel();
      messagingModel.subscriptions.remove(streamId);
    }
    setState();
  }

  void cleanup(String streamId) {
    messagingModel.responses.inverse.remove(streamId);
    messagingModel.subscriptions.remove(streamId);
    messagingModel.active.remove(streamId);
    setState();
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
  }

  Future<void> clearMessages() async {
    final sessionMessages =
        messagingModel.chatController.messages
            .where(
              (element) =>
                  messagingModel.sessionId == element.metadata!['session.id'],
            )
            .toList();
    for (final element in sessionMessages) {
      await messagingModel.chatController.removeMessage(element);
    }
    final newSessionId = newUuid();
    messagingModel = messagingModel.copyWith(sessionId: newSessionId);
    (messagingModel.chatController as SembastChatController).activeSessionId =
        newSessionId;
    await messagingModel.chatController.setMessages([]);
    setState();
  }

  Future<void> newChat() async {
    final newSessionId = newUuid();
    messagingModel = messagingModel.copyWith(sessionId: newSessionId);
    (messagingModel.chatController as SembastChatController).activeSessionId =
        newSessionId;
    await messagingModel.chatController.setMessages([]);
    setState();
  }

  Future<void> loadChat(String sessionId) async {
    final sessionMessages = chats[sessionId] ?? <Message>[];

    await messagingModel.chatController.setMessages(sessionMessages);
    (messagingModel.chatController as SembastChatController).activeSessionId =
        sessionId;
    messagingModel = messagingModel.copyWith(sessionId: sessionId);
    setState();
  }
}

@immutable
class ChatSessionView {
  const ChatSessionView({
    required this.activeSession,
    required this.ai,
    required this.webSearch,
    required this.documentSearch,
  });
  final ChatSession activeSession;
  final UnnuAIModel ai;
  final bool webSearch;
  final bool documentSearch;

  static ChatSessionView getDefaults() {
    return ChatSessionView(
      activeSession: ChatSession.dummy(),
      ai: UnnuAIModel(
        model: LlamaCppProvider(
          defaultOptions: const LcppOptions(),
        ),
      ),
      webSearch: false,
      documentSearch: false,
    );
  }

  ChatSessionView copyWith({
    ChatSession? activeSession,
    UnnuAIModel? ai,
    bool? webSearch,
    bool? documentSearch,
  }) {
    return ChatSessionView(
      activeSession: activeSession ?? this.activeSession,
      ai: ai ?? this.ai,
      webSearch: webSearch ?? this.webSearch,
      documentSearch: documentSearch ?? this.documentSearch,
    );
  }

  @override
  String toString() =>
      'ChatSessionVM(activeSession: $activeSession, ai: $ai, webSearch: $webSearch, documentSearch: $documentSearch)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatSessionView &&
        other.activeSession == activeSession &&
        other.ai == ai &&
        other.webSearch == webSearch &&
        other.documentSearch == documentSearch;
  }

  @override
  int get hashCode =>
      activeSession.hashCode ^
      ai.hashCode ^
      webSearch.hashCode ^
      documentSearch.hashCode;
}

class ChatSessionController extends JuneState {
  ChatSessionView chatSessionVM = ChatSessionView.getDefaults();

  Future<void> newChat({bool? search}) async {
    await chatSessionVM.ai.reset();
    chatSessionVM = chatSessionVM.copyWith(
      activeSession: chatSessionVM.ai.getChatSession(history: []),
      webSearch: search ?? false,
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

  Future<String> asMarkdown() async {
    final List<cm.ChatMessage> chatMessages = await chatSessionVM.ai.messages;
    return chatMessages.isNotEmpty ? chatMessagesToMarkdown(chatMessages) : '';
  }

  static String chatMessagesToMarkdown(List<cm.ChatMessage> chatMessages) {
    final buffer = StringBuffer();
    for (final message in chatMessages) {
      switch (message) {
        case cm.HumanChatMessage():
          switch (message.content) {
            case cm.ChatMessageContentText():
              buffer.write(
                '\n> ##### User\n---\n\n${(message.content as cm.ChatMessageContentText).text}\n',
              );
            default:
              break;
          }
        case cm.AIChatMessage():
          buffer.write('\n> ##### Assistant\n---\n\n${message.content}\n');
        default:
          break;
      }
    }
    return buffer.toString();
  }
}

typedef CopiedMessage = ({String content, DateTime startDate});

// @immutable
// final class ChatWidgetView {
//   const ChatWidgetView({
//     required this.status,
//     required this.nonblocking,
//     required this.search,
//   });
//
//   factory ChatWidgetView.fromMap(Map<String, dynamic> map) {
//     return ChatWidgetView(
//       status: SendIconState.fromValue((map['status'] ?? 0) as int),
//       nonblocking: (map['nonblocking'] ?? false) as bool,
//       search: (map['search'] ?? false) as bool,
//     );
//   }
//
//   factory ChatWidgetView.fromJson(String source) =>
//       ChatWidgetView.fromMap(json.decode(source) as Map<String, dynamic>);
//   final SendIconState status;
//   final bool nonblocking;
//   final bool search;
//
//   static ChatWidgetView getDefaults() {
//     return ChatWidgetView(
//       status: SendIconState.idle,
//       nonblocking: true,
//       search: false,
//     );
//   }
//
//   ChatWidgetView copyWith({
//     SendIconState? status,
//     bool? nonblocking,
//     bool? search,
//   }) {
//     return ChatWidgetView(
//       status: status ?? this.status,
//       nonblocking: nonblocking ?? this.nonblocking,
//       search: search ?? this.search,
//     );
//   }
//
//   Map<String, dynamic> toMap() {
//     final result =
//         <String, dynamic>{}..addAll({
//           'status': status.value,
//           'nonblocking': nonblocking,
//           'search': search,
//         });
//
//     return result;
//   }
//
//   String toJson() => json.encode(toMap());
//
//   @override
//   String toString() =>
//       'ChatWidgetVM(status: $status, nonblocking: $nonblocking, search: $search)';
//
//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//
//     return other is ChatWidgetView &&
//         other.status == status &&
//         other.nonblocking == nonblocking &&
//         other.search == search;
//   }
//
//   @override
//   int get hashCode => status.hashCode ^ nonblocking.hashCode ^ search.hashCode;
// }

class ChatWidgetChangeNotifier {
  SendIconState _status = SendIconState.idle;
  bool _nonblocking = true;
  bool _search = false;
  ChatWidgetChangeNotifier({
    SendIconState status = SendIconState.idle,
    bool nonblocking = true,
    bool search = false,
  }) : _status = status,
       _nonblocking = nonblocking,
       _search = search;

  SendIconState get status => _status;

  set status(SendIconState status) {
    _status = status;
  }

  bool get nonblocking => _nonblocking;

  set nonblocking(bool nonblocking) {
    _nonblocking = nonblocking;
  }

  bool get search => _search;

  set search(bool search) {
    _search = _search;
  }

  void update({SendIconState? status, bool? nonblocking, bool? search}) {
    _status = status ?? this._status;
    _nonblocking = nonblocking ?? this._nonblocking;
    _search = search ?? this._search;
  }

  ChatWidgetChangeNotifier copyWith({
    SendIconState? status,
    bool? nonblocking,
    bool? search,
  }) {
    return ChatWidgetChangeNotifier(
      status: status ?? this._status,
      nonblocking: nonblocking ?? this._nonblocking,
      search: search ?? this._search,
    );
  }

  @override
  String toString() =>
      'ChatWidgetChangeNotifier(status: $_status, nonblocking: $_nonblocking, search: $_search)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatWidgetChangeNotifier &&
        other._status == _status &&
        other._nonblocking == _nonblocking &&
        other._search == _search;
  }

  @override
  int get hashCode =>
      _status.hashCode ^ _nonblocking.hashCode ^ _search.hashCode;
}

class ChatWidgetController extends JuneState {
  final ChatWidgetChangeNotifier changeNotifier = ChatWidgetChangeNotifier();

  void update({SendIconState? status, bool? nonblocking, bool? search}) {
    changeNotifier.update(
      status: status,
      nonblocking: nonblocking,
      search: search,
    );
    setState();
  }
}
