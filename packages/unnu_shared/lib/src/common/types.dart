import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:june/june.dart';
import 'package:markdown/markdown.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:remove_emoji/remove_emoji.dart';
import 'package:unnu_aux/unnu_aux.dart';
import 'package:unnu_shared/unnu_shared.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

typedef Voice = ({int sid, double speed});

enum ResponseSegmentType { Context, Thinking, Answer }

final class Oratory {
  const Oratory(this.type, this.text);
  final ResponseSegmentType type;
  final String text;
}

final class Dialoguizer {
   Dialoguizer({
    required this.separators,
    required this.reasoning,
  });

  Pattern separators;
  final StringBuffer _fragment = StringBuffer();
  final bool reasoning;

  final xmlStartOfThinking = RegExp('<think>');
   final xmlEndOfThinking = RegExp('</think>');

  bool _startOfThought = false;
  bool _startOfAnswer = false;

  ResponseSegmentType _responseStatus = ResponseSegmentType.Context;

  List<Oratory> _tokenizeSentences(String text) {
    _fragment.write(text);
    final fragments = <String>[];

    final paragraph = _fragment.toString().splitMapJoin(
      separators,
      onMatch: (value) {
        final val = value.group(0)!;
        if (fragments.isNotEmpty) {
          fragments.last += val.removEmojiNoTrim;
        }
        return val;
      },
      onNonMatch: (value) {
        fragments.add(value.removEmojiNoTrim);
        return value;
      },
    );
    if (reasoning) {
      if (paragraph.contains(xmlStartOfThinking) &&
          _responseStatus == ResponseSegmentType.Context) {
        _responseStatus = ResponseSegmentType.Thinking;
        _startOfThought = true;
      }
      if (paragraph.contains(xmlEndOfThinking)) {
        _responseStatus = ResponseSegmentType.Answer;
        _startOfAnswer = true;
      }
    } else {
      _responseStatus = ResponseSegmentType.Answer;
      _startOfThought = true;
      _startOfAnswer = true;
    }
    _fragment.clear();
    final sentences = <Oratory>[];
    final int j = max(fragments.length - 1, 0);
    for (var i = 0; i < j; i++) {
      final segments =
          reasoning ? _segments(fragments[i]) : {'response': fragments[i]};

      if (segments.containsKey('context') ||
          _responseStatus == ResponseSegmentType.Context) {
        final context =
            BeautifulSoup(
              markdownToHtml(segments['context'] ?? segments['response'] ?? ''),
            ).body!.p!.text;
        if (context.isNotEmpty) {
          sentences.add(
            Oratory(ResponseSegmentType.Context, context.replaceAll('**', '')),
          );
        }
      }

      if (_responseStatus == ResponseSegmentType.Thinking ||
          segments.containsKey('thought')) {
        final thoughts =
            BeautifulSoup(
              markdownToHtml(segments['thought'] ?? segments['response'] ?? ''),
            ).body!.p!.text;
        if (thoughts.isNotEmpty) {
          sentences.add(
            Oratory(
              ResponseSegmentType.Thinking,
              thoughts.replaceAll('**', ''),
            ),
          );
        }
      }
      if (_responseStatus == ResponseSegmentType.Answer) {
        if (kDebugMode) {
          final _found =
              BeautifulSoup(markdownToHtml(segments['response'] ?? '')).body!;
          final _etext = _found.text;
          print('_etext: $_etext');
        }

        final sentence =
            BeautifulSoup(
              markdownToHtml(segments['response'] ?? ''),
            ).body!.p!.text;
        if (sentence.isNotEmpty) {
          sentences.add(
            Oratory(_responseStatus, sentence.replaceAll('**', '')),
          );
          if (kDebugMode) {
            print(
              'Dialoguizer reasoning: $reasoning ${_responseStatus.name}: $sentence',
            );
          }
        }
      }
    }
    for (int i = j; i < fragments.length; i++) {
      _fragment.write(fragments[i]);
    }
    return sentences;
  }

  Oratory reset() {
    final last =
        _fragment.isNotEmpty
            ? Oratory(
              _responseStatus,
              BeautifulSoup(
                markdownToHtml(_fragment.toString()),
              ).body!.p!.text.replaceAll('**', ''),
            )
            : const Oratory(ResponseSegmentType.Answer, '');
    _fragment.clear();
    _responseStatus = ResponseSegmentType.Context;
    _startOfThought = false;
    _startOfAnswer = false;
    return last;
  }

  List<Oratory> process(String text) {
    final result = _tokenizeSentences(text);
    if (text.isEmpty) {
      result.add(reset());
    }
    return result;
  }

  Map<String, String> _segments(String text) {
    Iterable<String> words = [];
    final parts = <String, String>{};
    var context = '';
    var thought = '';
    var parsed = text;
    if (_startOfThought) {
      _startOfThought = false;
      words = parsed.split(xmlStartOfThinking);
      words = words.map(
        (value) => value.replaceAll(xmlStartOfThinking, ''),
      );
      if (words.length > 1) {
        context = words.first;
        parsed = words.last;
      }
    }
    if (_startOfAnswer) {
      _startOfAnswer = false;
      words = parsed.split(xmlEndOfThinking);
      words = words.map(
        (value) =>
            value.replaceAll(xmlEndOfThinking, ''),
      );
      if (words.length > 1) {
        thought = words.first;
        parsed = words.last;
      }
    }
    if (context.isNotEmpty) {
      parts['context'] = context;
    }
    if (thought.isNotEmpty) {
      parts['thought'] = thought;
    }
    parts['response'] = parsed;
    return parts;
  }

  Map<String, String> extract(String text) {
    Map<String, String> parts = <String, String>{};
    var parsed = text;
    if (reasoning) {
      final segments = text.split(xmlStartOfThinking);
      if (segments.length > 1) {
        parts['context'] = segments.first.replaceAll(
          xmlStartOfThinking,
          '',
        );
        parsed = segments.last.replaceAll(
          xmlStartOfThinking,
          '',
        );
      }
      final answer = parsed.split(xmlEndOfThinking);
      if (answer.length > 1) {
        parts['thought'] = answer.first.replaceAll(
          xmlEndOfThinking,
          '',
        );
        parsed = answer.last.replaceAll(
          xmlEndOfThinking,
          '',
        );
      }
    }
    parts['response'] = parsed;
    return parts;
  }
}

@immutable
final class ChatAttachmentView {
  const ChatAttachmentView({
    required this.uri,
    required this.sessionId,
    required this.id,
  });

  factory ChatAttachmentView.fromJson(String source) =>
      ChatAttachmentView.fromMap(json.decode(source) as Map<String, dynamic>);

  factory ChatAttachmentView.fromMap(Map<String, dynamic> map) {
    return ChatAttachmentView(
      uri: Uri.tryParse((map['uri'] ?? '') as String) ?? Uri(),
      sessionId: (map['sessionId'] ?? '') as String,
      id: Set<String>.from((map['id'] ?? <String>[]) as List<String>),
    );
  }
  final Uri uri;
  final String sessionId;
  final Set<String> id;

  static ChatAttachmentView empty() {
    return ChatAttachmentView(
      uri: Uri(),
      sessionId: '',
      id: const <String>{},
    );
  }

  ChatAttachmentView copyWith({
    Uri? filepath,
    String? sessionId,
    Set<String>? id,
  }) {
    return ChatAttachmentView(
      uri: filepath ?? this.uri,
      sessionId: sessionId ?? this.sessionId,
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toMap() {
    final result =
        <String, dynamic>{}..addAll({
          'uri': uri.toString(),
          'sessionId': sessionId,
          'id': id.toList(growable: false),
        });

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'ChatAttachmentView(uri: $uri, sessionId: $sessionId, id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final setEquals = const DeepCollectionEquality().equals;

    return other is ChatAttachmentView &&
        other.uri == uri &&
        other.sessionId == sessionId &&
        setEquals(other.id, id);
  }

  @override
  int get hashCode => uri.hashCode ^ sessionId.hashCode ^ id.hashCode;
}

@immutable
final class ChatSettings {
  factory ChatSettings.fromJson(String source) =>
      ChatSettings.fromMap(json.decode(source) as Map<String, dynamic>);
  const ChatSettings({
    required this.chatId,
    required this.documents,
    required this.enableSearch,
    required this.weblinks,
  });

  factory ChatSettings.fromMap(Map<String, dynamic> map) {
    return ChatSettings(
      chatId: (map['chatId'] ?? '') as String,
      documents: Set<ChatAttachmentView>.from(
        ((map['documents'] ?? <Map<String, dynamic>>[])
                as List<Map<String, dynamic>>)
            .map(ChatAttachmentView.fromMap),
      ),
      enableSearch: (map['enableSearch'] ?? false) as bool,
      weblinks: Set<Uri>.from(
        ((map['weblinks'] ?? <String>[]) as List<String>).map(
          (x) => Uri.tryParse(x) ?? Uri(),
        ),
      ),
    );
  }
  final String chatId;
  final Set<ChatAttachmentView> documents;
  final bool enableSearch;
  final Set<Uri> weblinks;

  ChatSettings copyWith({
    String? chatId,
    Set<ChatAttachmentView>? documents,
    bool? enableSearch,
    Set<Uri>? weblinks,
  }) {
    return ChatSettings(
      chatId: chatId ?? this.chatId,
      documents: documents ?? this.documents,
      enableSearch: enableSearch ?? this.enableSearch,
      weblinks: weblinks ?? this.weblinks,
    );
  }

  static ChatSettings empty() {
    return const ChatSettings(
      chatId: '',
      documents: <ChatAttachmentView>{},
      enableSearch: true,
      weblinks: <Uri>{},
    );
  }

  Map<String, dynamic> toMap() {
    final result =
        <String, dynamic>{}..addAll({
          'chatId': chatId,
          'documents': documents.map((x) => x.toMap()).toList(),
          'enableSearch': enableSearch,
          'weblinks': weblinks.map((x) => x.toString()).toList(growable: false),
        });

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'ChatSettings(chatId: $chatId, documents: $documents, enableSearch: $enableSearch, weblinks: $weblinks)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final setEquals = const DeepCollectionEquality().equals;

    return other is ChatSettings &&
        other.chatId == chatId &&
        setEquals(other.documents, documents) &&
        other.enableSearch == enableSearch &&
        setEquals(other.weblinks, weblinks);
  }

  @override
  int get hashCode {
    return chatId.hashCode ^
        documents.hashCode ^
        enableSearch.hashCode ^
        weblinks.hashCode;
  }
}

class ConfigurationController extends JuneState {
  UnnuAppConfig config = UnnuAppConfig.getDefaults();

  Future<void> save() async {
    final directory = await getApplicationSupportDirectory();
    final appConfig = p.join(directory.path, 'application.cfg');
    await UnnuAux.saveAppConfig(appConfig, config);
  }

  Future<void> read() async {
    final directory = await getApplicationSupportDirectory();
    final appConfig = p.join(directory.path, 'application.cfg');
    config = await UnnuAux.loadConfiguration(appConfig);
  }

  static Future<YamlDocument> load({required Uri uri}) async {
    final path = uri.toFilePath(windows: Platform.isWindows);
    final filePath =
        p.isAbsolute(path)
            ? path
            : p.join((await getApplicationSupportDirectory()).path, path);

    final content = File(filePath).readAsStringSync();
    return loadYamlDocument(content);
  }

  static Future<String> store({
    required Uri uri,
    required YamlDocument document,
  }) async {
    final path = uri.toFilePath(windows: Platform.isWindows);
    final dst =
        p.isAbsolute(path)
            ? p.dirname(path)
            : p.join(
              (await getApplicationSupportDirectory()).path,
              p.dirname(path),
            );
    if (!Directory(dst).existsSync()) {
      if (kDebugMode) {
        print('ConfigurationController:write $dst');
      }
      await Directory(dst).create(recursive: true);
    }

    final file = File(p.join(dst, p.basename(path)));
    if (!file.existsSync()) {
      await file.create();
    }
    if (kDebugMode) {
      print('ConfigurationController:yaml $document');
    }

    await file.writeAsString(
      document.toString(),
      mode: FileMode.writeOnly,
      flush: true,
    );

    return file.path;
  }
}

enum AttachmentStatus {
  NEW,
  PARSE,
  EMBED,
  REMOVE,
  PROCESSED,
  COMPLETED,
  NOT_FOUND,
  OPERATION_NOT_ALLOWED,
  EXCEEDS_QUOTA,
  NOOP,
}

typedef AttachmentUpdate =
    ({AttachmentStatus status, ChatAttachmentView attachment});

class AttachmentsMonitor {
  static final StreamController<AttachmentUpdate> _updateController =
      StreamController<AttachmentUpdate>.broadcast(sync: false);

  static Stream<AttachmentUpdate> get updates => _updateController.stream;

  static void sendStatus(AttachmentUpdate update) {
    _updateController.add(update);
  }
}

class ChatSettingsController extends JuneState {
  static const uuid = Uuid();

  final Map<String, ChatSettings> settings = <String, ChatSettings>{};

  static const int MAX_ALLOWED_ATTACHMENTS = 5;
  static const int TOTAL_FILE_QUOTA = 256 * 1024 * 1024; // 256MB

  static String newUuid() {
    return uuid.v4();
  }

  Future<void> handleAttach(String sessionId, List<String> extensions) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      lockParentWindow: true,
      allowMultiple: true,
    );

    if (result != null) {
      if (result.isSinglePick) {
        // All files
        final file = File(result.files.single.path!);
        final uri = Uri.file(file.path, windows: Platform.isWindows);
        insert(sessionId, uri);
      } else {
        for (final f in result.files) {
          final file = File(f.path!);
          final uri = Uri.file(file.path, windows: Platform.isWindows);
          insert(sessionId, uri);
        }
      }
    }
  }

  void setSearch(String chatId, bool enabled) {
    final setting = settings.putIfAbsent(
      chatId,
      () => ChatSettings.empty().copyWith(chatId: chatId),
    );
    settings[chatId] = setting.copyWith(enableSearch: enabled);
    setState();
  }

  void insert(String chatId, Uri attachment) {
    final setting = settings.putIfAbsent(
      chatId,
      () => ChatSettings.empty().copyWith(chatId: chatId, enableSearch: true),
    );
    final listOfAttachments = <ChatAttachmentView>[
      ...setting.documents,
    ];
    if (listOfAttachments.length < MAX_ALLOWED_ATTACHMENTS) {
      final alreadyAdded = listOfAttachments.any(
        (element) => element.uri == attachment,
      );
      if (!alreadyAdded) {
        final newAttachment = ChatAttachmentView(
          uri: attachment,
          sessionId: chatId,
          id: const <String>{},
        );

        listOfAttachments.add(newAttachment);
        settings[chatId] = setting.copyWith(
          chatId: chatId,
          documents: listOfAttachments.toSet(),
        );
        AttachmentsMonitor.sendStatus((
          status: AttachmentStatus.NEW,
          attachment: newAttachment,
        ));
        setState();
      }
    }
  }

  void remove(String chatId, Uri attachment) {
    final setting = settings.putIfAbsent(
      chatId,
      () => ChatSettings.empty().copyWith(chatId: chatId),
    );
    final listOfAttachments = [...setting.documents].whereNot(
      (element) => element.uri == attachment,
    );

    settings[chatId] = setting.copyWith(
      documents: listOfAttachments.toSet(),
    );
    setState();
  }

  ChatSettings getSetting(String chatId) {
    return settings.putIfAbsent(
      chatId,
      () => ChatSettings.empty().copyWith(chatId: chatId),
    );
  }

  void update(ChatAttachmentView attachment) {
    final setting = settings.putIfAbsent(
      attachment.sessionId,
      () => ChatSettings.empty().copyWith(
        chatId: attachment.sessionId,
        documents: {attachment},
      ),
    );
    final processed = setting.documents.where(
      (element) => element.id.isNotEmpty,
    );
    final docs = [...processed, attachment];
    settings[attachment.sessionId] = setting.copyWith(
      documents: docs.toSet(),
    );
    AttachmentsMonitor.sendStatus((
      status: AttachmentStatus.COMPLETED,
      attachment: attachment,
    ));
    setState();
  }

  Future<void> load(String? filePath) async {
    final doc = await ConfigurationController.load(
      uri: Uri.file(
        filePath ?? 'conversations.yml',
        windows: Platform.isWindows,
      ),
    );

    final map = doc.contents.value as YamlMap;
    final conversations = map['conversations'] as YamlList;
    for (final c in conversations) {
      final docs = c['documents'] as YamlList;
      final links = c['weblinks'] as YamlList;

      final documents = <Map<String, dynamic>>[];
      final weblinks = <String>[];

      for (final d in docs) {
        final ids = d['id'] as YamlList;
        final docIds = <String>[];

        for (final i in ids) {
          docIds.add(i as String);
        }

        documents.add(
          ChatAttachmentView.fromMap(<String, dynamic>{
            'uri': d['uri'] as String,
            'sessionId': d['sessionId'] as String,
            'id': docIds,
          }).toMap(),
        );
      }

      for (final l in links) {
        weblinks.add(l as String);
      }

      final setting = ChatSettings.fromMap(<String, dynamic>{
        'chatId': c['chatId'] as String,
        'documents': documents,
        'enableSearch': c['enableSearch'] as bool,
        'weblinks': weblinks,
      });
      settings.putIfAbsent(setting.chatId, () => setting);
    }
  }

  void register(List<ChatSettings> settings) {
    for (final chat in settings) {
      this.settings.putIfAbsent(chat.chatId, () => chat);
    }
  }

  Future<void> persist() async {
    // Convert jsonValue to YAML
    final conversations = <String, List<ChatSettings>>{
      'conversations': settings.values
          .where(
            (element) =>
                element.documents.isNotEmpty || element.weblinks.isNotEmpty,
          )
          .toList(growable: false),
    };
    final yamlEditor = YamlEditor('');

    final jsonString = json.encode(conversations);
    final jsonValue = json.decode(jsonString);
    yamlEditor.update([], jsonValue);
    final filePath = await absoluteApplicationSupportPath('conversations.yml');
    final _ = await ConfigurationController.store(
      uri: Uri.file(
        filePath,
        windows: Platform.isWindows,
      ),
      document: loadYamlDocument(yamlEditor.toString()),
    );
  }
}
