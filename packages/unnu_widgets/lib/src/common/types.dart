import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:june/june.dart';
import 'package:langchain/langchain.dart';
import 'package:quiver/collection.dart';
import 'package:unnu_ai_model/unnu_ai_model.dart';
import 'package:unnu_mi5/unnu_mi5.dart';
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
    required this.chatController,
    required this.responses,
    required this.sessionId,
    required this.parser,
  });
  final UnnuStreamManager streamManager;
  final Map<String, TextStreamMessage> active;
  final ChatController chatController;
  final BiMap<String, String> responses;
  final String sessionId;
  final Dialoguizer parser;

  StreamingMessageView copyWith({
    UnnuStreamManager? streamManager,
    Map<String, TextStreamMessage>? active,
    // SubscriptionStream<ChatResult>? assistant,
    ChatController? chatController,
    BiMap<String, String>? responses,
    String? sessionId,
    Dialoguizer? parser,
  }) {
    return StreamingMessageView(
      streamManager: streamManager ?? this.streamManager,
      active: active ?? this.active,
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
      active: <String, TextStreamMessage>{},
      responses: HashBiMap<String, String>(),
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
        other.chatController == chatController &&
        other.responses == responses &&
        other.sessionId == sessionId &&
        other.parser == parser;
  }

  @override
  int get hashCode {
    return streamManager.hashCode ^
        active.hashCode ^
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

  Future<void> onChatResult(ChatResult event) async {
    final message = event.output;
    if (event.metadata.containsKey('message.id')) {
      final messageId = event.metadata['message.id'] as String;
      final messageType = (event.metadata['message.type'] ?? '') as String;
      if (messageType == 'response') {
        final streamId = getStreamId(messageId);
        if (streamId != null) {
          final oldMessage = getMessage(streamId);
          final oldMetadata =
              oldMessage?.metadata ??
                  {
                    'session.id': sessionId,
                    'message.id': messageId,
                  };
          final replyType = (oldMetadata['replyTo.type'] ?? '') as String;
          if (replyType == 'tool') {
            final toolMsgId = (oldMetadata['replyTo.id'] ?? '') as String;
            final toolMetadata = {
              'session.id': sessionId,
              'message.id': (oldMetadata['message.id'] ?? '') as String,
            };
            final toolMessage = chat_core.TextMessage(
              id: toolMsgId,
              authorId: Avatars.Assistant.id,
              createdAt: DateTime.now().toUtc(),
              sentAt: DateTime.now().toUtc(),
              text: '',
              metadata: toolMetadata,
            );
            await messagingModel.chatController.removeMessage(toolMessage);
          }

          final newMetadata = <String, dynamic>{...oldMetadata}..addAll({
            'allow.updates': message.toolCalls.isNotEmpty,
            'is.streaming': false,
            if (message.toolCalls.isNotEmpty)
              'tool.calls': jsonEncode(
                message.toolCalls
                    .map(
                      (e) => e.toMap(),
                    )
                    .toList(),
              ),
            if (chat_core.isOnlyEmoji(event.output.content))
              'isOnlyEmoji': true,
          });

          if (messagingModel.parser.reasoning &&
              message.content.startsWith('<think>')) {
            final segments = messagingModel.parser.extract(
              message.content,
            );
            newMetadata.addAll({
              if (segments.containsKey('thought'))
                'parsed.thx': segments['thought'] ?? '',
              if (segments.containsKey('context'))
                'parsed.ctx': segments['context'] ?? '',
              if (segments.containsKey('response'))
                'parsed.out': segments['response'] ?? '',
            });
          }
          final text =
              ((newMetadata['parsed.out'] ?? '') as String).isNotEmpty
                  ? newMetadata['parsed.out'] as String
                  : message.content.isNotEmpty
                  ? message.content
                  : message.toolCalls.isNotEmpty
                  ? "Executing tool${message.toolCalls.length > 1 ? "s" : ""}: ${message.toolCalls.map(
                    (e) => e.name.replaceAll('_', ' '),
                  ).join(",")}"
                  : '';
          final newMessage = chat_core.TextMessage(
            id: oldMessage!.id,
            authorId: Avatars.Assistant.id,
            createdAt: oldMessage.createdAt,
            sentAt: DateTime.now().toUtc(),
            replyToMessageId: oldMessage.replyToMessageId,
            text: text,
            metadata: newMetadata,
          );
          await messagingModel.chatController.updateMessage(
            oldMessage,
            newMessage,
          );
          messagingModel.responses.remove(messageId);
          messagingModel.active.remove(streamId);
          setState();
        } else {
          final newMetadata = <String, dynamic>{
            'session.id': sessionId,
            'message.id': messageId,
            'allow.updates': false,
            'is.streaming': false,
            if (chat_core.isOnlyEmoji(message.content)) 'isOnlyEmoji': true,
          };

          if (messagingModel.parser.reasoning &&
              message.content.startsWith('<think>')) {
            final segments = messagingModel.parser.extract(
              message.content,
            );
            newMetadata.addAll({
              if (segments.containsKey('thought'))
                'parsed.thx': segments['thought'] ?? '',
              if (segments.containsKey('context'))
                'parsed.ctx': segments['context'] ?? '',
              if (segments.containsKey('response'))
                'parsed.out': segments['response'] ?? '',
            });
          }
          final newMessage = chat_core.TextMessage(
            id: messageId,
            authorId: Avatars.Assistant.id,
            createdAt: DateTime.now().toUtc(),
            sentAt: DateTime.now().toUtc(),
            text:
                ((newMetadata['parsed.out'] ?? '') as String).isNotEmpty
                    ? newMetadata['parsed.out'] as String
                    : message.content,
            metadata: newMetadata,
          );
          await messagingModel.chatController.insertMessage(
            newMessage,
          );
        }
      } else if (messageType == 'error') {
        final streamId = getStreamId(messageId);
        if (streamId != null) {
          final oldMessage = getMessage(streamId);

          if (oldMessage != null) {
            final userMessageId =
                (event.metadata['replyTo.id'] ?? '') as String;
            final errCode =
                (event.metadata['message.exit_code'] ?? '') as String;
            final userMsg = chat_core.TextMessage(
              id: userMessageId,
              authorId: 'application',
              text: '',
              metadata: {
                'session.id': sessionId,
                'allow.updates': true,
                'is.streaming': false,
              },
            );
            final appMsg = chat_core.TextMessage(
              id: userMessageId,
              authorId: 'application',
              text: 'Status: $errCode',
              metadata: {
                'session.id': sessionId,
                'allow.updates': false,
                'is.streaming': false,
              },
            );
            await messagingModel.chatController.removeMessage(oldMessage);
            if (userMsg.id.isNotEmpty) {
              await messagingModel.chatController.updateMessage(
                userMsg,
                appMsg,
              );
            }
            messagingModel.responses.remove(messageId);
            messagingModel.active.remove(streamId);
            final ids = [messageId, userMessageId, streamId];
            StatusMonitor.sendStatus((
              status: StatusEventCode.PROMPT_GENERATION_ERROR,
              attachment: EventAttributes(
                id: ids.toSet(),
                sessionId: sessionId,
                uri: Uri(),
              ),
            ));
            setState();
          }
        }
      }
    }
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
    setState();
  }

  void cleanup(String streamId) {
    messagingModel.responses.inverse.remove(streamId);
    messagingModel.active.remove(streamId);
    setState();
  }

  Future<void> onError(String streamId, Object err) async {
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
    final toolsController = June.getState(
      McpToolsController.new,
    );
    final newSessionId = newUuid();
    messagingModel = messagingModel.copyWith(sessionId: newSessionId);
    (messagingModel.chatController as SembastChatController).activeSessionId =
        newSessionId;
    await messagingModel.chatController.setMessages([]);
    await toolsController.registerLocal(newSessionId);
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
    required this.ai,
    required this.documentSearch,
  });
  final UnnuAIModel ai;
  final bool documentSearch;

  static ChatSessionView getDefaults() {
    return ChatSessionView(
      ai: UnnuAIModel(
        model: LlamaCppProvider(),
        memory: ConversationBufferMemory(
          chatHistory: ChatMessageHistory(),
          returnMessages: true,
        ),
      ),
      documentSearch: false,
    );
  }

  ChatSessionView copyWith({
    UnnuAIModel? ai,
    bool? webSearch,
    bool? documentSearch,
  }) {
    return ChatSessionView(
      // activeSession: activeSession ?? this.activeSession,
      ai: ai ?? this.ai,
      documentSearch: documentSearch ?? this.documentSearch,
    );
  }

  @override
  String toString() =>
      'ChatSessionVM(ai: $ai, documentSearch: $documentSearch)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatSessionView &&
        other.ai == ai &&
        other.documentSearch == documentSearch;
  }

  @override
  int get hashCode => ai.hashCode ^ documentSearch.hashCode;
}

class ChatSessionController extends JuneState {
  ChatSessionView chatSessionVM = ChatSessionView.getDefaults();

  Future<void> newChat({bool? search}) async {
    await chatSessionVM.ai.reset();
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
                      ? ChatMessage.humanText(message.text)
                      : message.authorId == Avatars.Assistant.id
                      ? ChatMessage.ai(message.text)
                      : ChatMessage.system(message.text),
            )
            .toList();
    chatSessionVM.ai.history = chatMessages;
    setState();
  }

  Future<void> clearMessages() async {
    await chatSessionVM.ai.memory.clear();
    setState();
  }

  Future<String> asMarkdown() async {
    final List<ChatMessage> chatMessages = await chatSessionVM.ai.messages;
    return chatMessages.isNotEmpty ? chatMessagesToMarkdown(chatMessages) : '';
  }

  static String chatMessagesToMarkdown(List<ChatMessage> chatMessages) {
    final buffer = StringBuffer();
    for (final message in chatMessages) {
      switch (message) {
        case HumanChatMessage():
          switch (message.content) {
            case ChatMessageContentText():
              buffer.write(
                '\n> ##### User\n---\n\n${(message.content as ChatMessageContentText).text}\n',
              );
            default:
              break;
          }
        case AIChatMessage():
          buffer.write('\n> ##### Assistant\n---\n\n${message.content}\n');
        default:
          break;
      }
    }
    return buffer.toString();
  }
}

typedef CopiedMessage = ({String content, DateTime startDate});

class ChatWidgetChangeNotifier {
  SendIconState _status = SendIconState.idle;
  bool _nonblocking = true;
  ChatWidgetChangeNotifier({
    SendIconState status = SendIconState.idle,
    bool nonblocking = true,
  }) : _status = status,
       _nonblocking = nonblocking;

  SendIconState get status => _status;

  set status(SendIconState status) {
    _status = status;
  }

  bool get nonblocking => _nonblocking;

  set nonblocking(bool nonblocking) {
    _nonblocking = nonblocking;
  }

  void update({SendIconState? status, bool? nonblocking}) {
    _status = status ?? this._status;
    _nonblocking = nonblocking ?? this._nonblocking;
  }

  ChatWidgetChangeNotifier copyWith({
    SendIconState? status,
    bool? nonblocking,
  }) {
    return ChatWidgetChangeNotifier(
      status: status ?? this._status,
      nonblocking: nonblocking ?? this._nonblocking,
    );
  }

  @override
  String toString() =>
      'ChatWidgetChangeNotifier(status: $_status, nonblocking: $_nonblocking)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatWidgetChangeNotifier &&
        other._status == _status &&
        other._nonblocking == _nonblocking;
  }

  @override
  int get hashCode => _status.hashCode ^ _nonblocking.hashCode;
}

class ChatWidgetController extends JuneState {
  final ChatWidgetChangeNotifier changeNotifier = ChatWidgetChangeNotifier();

  void update({SendIconState? status, bool? nonblocking}) {
    changeNotifier.update(
      status: status,
      nonblocking: nonblocking,
    );
    setState();
  }
}
