import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:diffutil_dart/diffutil.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:sembast/sembast.dart';

class SembastChatController
    with UploadProgressMixin, ScrollToMessageMixin
    implements ChatController {

  SembastChatController(this.database);
  final Database database;
  final _operationsController = StreamController<ChatOperation>.broadcast();
  String _activeSessionId = '';
  set activeSessionId(String value) {
    _activeSessionId = value;
  }

  @override
  Future<void> insertMessage(Message message, {int? index}) async {
    final store = intMapStoreFactory.store();
    final records = store.findSync(
      database,
      finder: Finder(
        filter: Filter.custom((record) {
          final data = Message.fromJson(record.value as Map<String, dynamic>);
          return data.metadata != null &&
                  data.metadata!.containsKey('session.id')
              ? message.metadata!['session.id'] == data.metadata!['session.id']
              : message.id == data.id;
        }),
        sortOrders: [SortOrder('createdAt')],
      ),
    );
    int idx = records.length;
    if (records.isNotEmpty) {
      final result = records.where(
        (element) => element.value['id'] == message.id,
      );

      if (result.isNotEmpty) return;
    }
    await store.add(database, message.toJson());
    if ((message.metadata?['session.id'] ?? '') ==  _activeSessionId) {
      _operationsController.add(ChatOperation.insert(message, index ?? idx));
    }
  }

  @override
  Future<void> removeMessage(Message message) async {
    final store = intMapStoreFactory.store();
    final records = store.findSync(
      database,
      finder: Finder(
        filter: Filter.custom((record) {
          final data = Message.fromJson(record.value as Map<String, dynamic>);
          return message.metadata != null &&
                  message.metadata!.containsKey('session.id')
              ? message.metadata!['session.id'] == data.metadata!['session.id']
              : message.id == data.id;
        }),
        sortOrders: [SortOrder('createdAt')],
      ),
    );
    final record =
        records.indexed
            .where((element) => element.$2['id'] == message.id)
            .firstOrNull;
    if (record != null) {
      int idx = record.$1;
      final deleted = await store.record(record.$2.key).delete(database);
      if ((message.metadata?['session.id'] ?? '') ==  _activeSessionId) {
        _operationsController.add(ChatOperation.remove(message, idx));
      }
    }
  }

  @override
  Future<void> updateMessage(Message oldMessage, Message newMessage) async {
    if (oldMessage == newMessage) return;

    final store = intMapStoreFactory.store();

    final records = await store.find(
      database,
      finder: Finder(
        filter: Filter.custom((record) {
          final message = Message.fromJson(
            (record.value ?? <String, dynamic>{}) as Map<String, dynamic>,
          );
          return message.metadata != null &&
                  message.metadata!.containsKey('session.id')
              ? message.metadata!['session.id'] ==
                  oldMessage.metadata!['session.id']
              : message.id == oldMessage.id;
        }),
        sortOrders: [SortOrder('createdAt')],
      ),
    );
    if (records.isNotEmpty) {
      final result = records.indexed.where(
        (element) => element.$2.value['id'] == oldMessage.id,
      );

      if (result.isNotEmpty) {
        final msg = Message.fromJson(result.first.$2.value);
        final oldIsStreaming =
            !(msg.metadata != null && msg.metadata!.containsKey('allow.updates'))
                || msg.metadata!['allow.updates'] as bool;
        if (oldIsStreaming) {
          await store
              .record(result.first.$2.key)
              .update(database, newMessage.toJson());
          if ((newMessage.metadata?['session.id'] ?? '') ==  _activeSessionId) {
            _operationsController.add(
              ChatOperation.update(oldMessage, newMessage, result.first.$1),
            );
          }
        }
      }
    }
  }

  @override
  Future<void> setMessages(List<Message> newMessages) async {
    if (newMessages.isEmpty) {
      _operationsController.add(ChatOperation.set(const []));
      return;
    } else {
      final store = intMapStoreFactory.store();
      Set<String> ids =
          newMessages.map<String>((element) => element.id).toSet();
      final records = await store.find(
        database,
        finder: Finder(
          filter: Filter.custom((record) {
            final data = Message.fromJson(record.value as Map<String, dynamic>);
            return ids.contains(data.id);
          }),
          sortOrders: [SortOrder('createdAt')],
        ),
      );

      final oldMessages =
          records.map((record) => Message.fromJson(record.value)).toList();

      final diffResult = calculateListDiff(
        oldMessages,
        newMessages,
        detectMoves: false,
      );

      final differences = diffResult.getUpdatesWithData();
      final additions = <Message>[];
      final updates = <MapEntry<Message, Message>>[];
      for (var msg in differences) {
        msg.when(
          insert: (position, data) {
            additions.add(data);
          },
          remove: (position, data) {},
          change: (position, olddata, newdata) {
            updates.add(MapEntry(olddata, newdata));
          },
          move: (oldpos, newpos, data) {},
        );
      }

      final keys = await store.addAll(
        database,
        additions.map((message) => message.toJson()).toList(),
      );

      for (var msg in updates) {
        await store.update(
          database,
          msg.value.toJson(),
          finder: Finder(
            filter: Filter.custom((record) {
              return msg.key.id == record['id'];
            }),
          ),
        );
      }
      _operationsController.add(ChatOperation.set(newMessages));
    }
  }

  List<Message> get allMessages {
    final store = intMapStoreFactory.store();
    return store
        .findSync(
          database,
          finder: Finder(sortOrders: [SortOrder('createdAt')]),
        )
        .map((record) => Message.fromJson(record.value))
        .toList();
  }

  @override
  List<Message> get messages {
    final store = intMapStoreFactory.store();
    return store
        .findSync(
          database,
          finder: Finder(
            filter: Filter.custom((record) {
              final message = Message.fromJson(
                record.value as Map<String, dynamic>,
              );
              return message.metadata != null &&
                      message.metadata!.containsKey('session.id')
                  && message.metadata!['session.id'] == _activeSessionId;
            }),
            sortOrders: [SortOrder('createdAt')],
          ),
        )
        .map((record) => Message.fromJson(record.value))
        .toList();
  }

  @override
  Stream<ChatOperation> get operationsStream => _operationsController.stream;

  @override
  void dispose() {
    _operationsController.close();
    disposeUploadProgress();
    disposeScrollMethods();
  }

  @override
  Future<void> insertAllMessages(
    List<Message> newMessages, {
    int? index,
  }) async {
    if (newMessages.isEmpty) return;
    final store = intMapStoreFactory.store();
    final ids = newMessages.groupSetsBy(
      (element) => element.metadata?['session.id'],
    );
    var length = 0;
    for (final value in ids.values) {
      length = max(length, value.length);
    }

    await store.addAll(
      database,
      newMessages.map((message) => message.toJson()).toList(),
    );
    _operationsController.add(ChatOperation.insertAll(newMessages, length));
  }
}
