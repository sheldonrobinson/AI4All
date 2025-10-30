import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

enum ApplicationPanel {
  history(0, Icons.history),
  models(1, Icons.functions),
  settings(2, Icons.settings);

  final int value;
  final IconData icondata;

  const ApplicationPanel(this.value, this.icondata);

  static ApplicationPanel fromValue(int value) => switch (value) {
    0 => history,
    1 => models,
    2 => settings,
    _ => throw ArgumentError('Unknown value for ApplicationPanel: $value'),
  };
}

enum AppPrimaryNavigation {
  NewChat(0, Icons.chat),
  SwitchModel(1, Icons.file_open),
  About(2, Icons.info),
  Feedback(3, Icons.edit_note);

  final IconData icondata;
  final int value;
  const AppPrimaryNavigation(this.value, this.icondata);

  IconData get icon => icondata;

  static AppPrimaryNavigation fromValue(int value) => switch (value) {
    0 => NewChat,
    1 => SwitchModel,
    2 => About,
    3 => Feedback,
    _ => throw ArgumentError('Unknown value for AppPrimaryNavigation: $value'),
  };
}

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
      _startOfThought = false;
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
            ).body?.p?.text ??
            '';
        if (context.isNotEmpty) {
          sentences.add(
            Oratory(
              ResponseSegmentType.Context,
              context.removEmojiNoTrim.replaceAll('**', ''),
            ),
          );
        }
      }

      if (_responseStatus == ResponseSegmentType.Thinking ||
          segments.containsKey('thought')) {
        final value = segments['thought'] ?? segments['response'] ?? '';
        if (value.isNotEmpty) {
          final thoughts =
              BeautifulSoup(
                markdownToHtml(value),
              ).body?.p?.text ??
              '';
          if (thoughts.isNotEmpty) {
            sentences.add(
              Oratory(
                ResponseSegmentType.Thinking,
                thoughts.removEmojiNoTrim.replaceAll('**', ''),
              ),
            );
          }
        }
      }
      if (_responseStatus == ResponseSegmentType.Answer) {
        final value = segments['response'] ?? '';
        if (value.isNotEmpty) {
          final sentence =
              BeautifulSoup(
                markdownToHtml(value),
              ).body?.p?.text ??
              '';
          if (sentence.isNotEmpty) {
            sentences.add(
              Oratory(
                _responseStatus,
                sentence.removEmojiNoTrim.replaceAll('**', ''),
              ),
            );
            // if (kDebugMode) {
            //   print(
            //     'Dialoguizer reasoning: $reasoning ${_responseStatus.name}: $sentence',
            //   );
            // }
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
              (BeautifulSoup(
                        markdownToHtml(_fragment.toString()),
                      ).body?.p?.text ??
                      '')
                  .removEmojiNoTrim
                  .replaceAll('**', ''),
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
        (value) => value.replaceAll(xmlEndOfThinking, ''),
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
    final parts = <String, String>{};
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
final class EventAttributes {
  const EventAttributes({
    required this.uri,
    required this.sessionId,
    required this.id,
  });

  factory EventAttributes.fromJson(String source) =>
      EventAttributes.fromMap(json.decode(source) as Map<String, dynamic>);

  factory EventAttributes.fromMap(Map<String, dynamic> map) {
    return EventAttributes(
      uri: Uri.tryParse((map['uri'] ?? '') as String) ?? Uri(),
      sessionId: (map['sessionId'] ?? '') as String,
      id: Set<String>.from((map['id'] ?? <String>[]) as List<String>),
    );
  }
  final Uri uri;
  final String sessionId;
  final Set<String> id;

  static EventAttributes empty() {
    return EventAttributes(
      uri: Uri(),
      sessionId: '',
      id: const <String>{},
    );
  }

  EventAttributes copyWith({
    Uri? filepath,
    String? sessionId,
    Set<String>? id,
  }) {
    return EventAttributes(
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
      'EventAttributes(uri: $uri, sessionId: $sessionId, id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final setEquals = const DeepCollectionEquality().equals;

    return other is EventAttributes &&
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
      documents: Set<EventAttributes>.from(
        ((map['documents'] ?? <Map<String, dynamic>>[])
                as List<Map<String, dynamic>>)
            .map(EventAttributes.fromMap),
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
  final Set<EventAttributes> documents;
  final bool enableSearch;
  final Set<Uri> weblinks;

  ChatSettings copyWith({
    String? chatId,
    Set<EventAttributes>? documents,
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
      documents: <EventAttributes>{},
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
    return '''
    ChatSettings:
    \tchatId: $chatId
    \tdocuments: $documents
    \tenableSearch: $enableSearch
    \tweblinks: $weblinks
    ''';
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

enum StatusEventCode {
  NEW,
  PARSE,
  EMBED,
  REMOVE,
  PROCESSED,
  COMPLETED,
  ABORTED,
  NOT_FOUND,
  OPERATION_NOT_ALLOWED,
  EXCEEDS_QUOTA,
  PROMPT_GENERATION_ERROR,
  MODEL_LOADING_ERROR,
  NOOP,
}

typedef StatusUpdate = ({StatusEventCode status, EventAttributes attachment});

class StatusMonitor {
  static final StreamController<StatusUpdate> _updateController =
      StreamController<StatusUpdate>.broadcast(sync: false);

  static Stream<StatusUpdate> get updates => _updateController.stream;

  static void sendStatus(StatusUpdate update) {
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
    final listOfAttachments = <EventAttributes>[
      ...setting.documents,
    ];
    if (listOfAttachments.length < MAX_ALLOWED_ATTACHMENTS) {
      final alreadyAdded = listOfAttachments.any(
        (element) => element.uri == attachment,
      );
      if (!alreadyAdded) {
        final newAttachment = EventAttributes(
          uri: attachment,
          sessionId: chatId,
          id: const <String>{},
        );

        listOfAttachments.add(newAttachment);
        settings[chatId] = setting.copyWith(
          chatId: chatId,
          documents: listOfAttachments.toSet(),
        );
        StatusMonitor.sendStatus((
          status: StatusEventCode.NEW,
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

  void update(EventAttributes attachment) {
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
    StatusMonitor.sendStatus((
      status: StatusEventCode.COMPLETED,
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
          EventAttributes.fromMap(<String, dynamic>{
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

@immutable
class CoreSamplingParameters {
  CoreSamplingParameters({
    required this.seed,
    required this.minKeep,
    required this.temperature,
    required this.topK,
    required this.topP,
    required this.minP,
    required this.typicalP,
  });

  factory CoreSamplingParameters.fromMap(Map<String, dynamic> map) {
    return CoreSamplingParameters(
      seed: (map['seed'] ?? 0) as int,
      minKeep: (map['minKeep'] ?? 0) as int,
      temperature: (map['temperature'] ?? 0.0) as double,
      topK: (map['topK'] ?? 0) as int,
      topP: (map['topP'] ?? 0.0) as double,
      minP: (map['minP'] ?? 0.0) as double,
      typicalP: (map['typicalP'] ?? 0.0) as double,
    );
  }

  factory CoreSamplingParameters.fromJson(String source) =>
      CoreSamplingParameters.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// Sets the random number seed to use for generation. Setting this to a
  /// specific number will make the model generate the same text for the same
  /// prompt, seed for random number generation to ensure reproducibility. (Default: 0)
  final int seed;

  /// The minimum number of items to keep in the sample. (Default: 0)
  final int minKeep;

  /// Temperature controls randomness by scaling the logits before applying softmax
  /// (Higher = more random, 0 = greedy, <0 = special mode) (default: 0.8, ragne: -1.0 to ∞).
  /// 1, temp > 0: Standard sampling with scaled logits. Higher values increase randomness.
  /// 2. temp = 0: Greedy sampling - always selects the most likely token
  /// 3. temp < 0: Special mode - applies softmax and samples from distribution without temperature scaling
  final double temperature;

  /// Keeps only top-k most likely tokens, restrictomg the candidate pool to the K tokens with highest probability.
  /// When top_k=40, only the 40 most likely tokens are considered. (default: 40, range: 0 to n_vocab)
  final int topK;

  /// Performs nucleus sampling: keeps tokens with cumulative probability ≤ top_p.
  /// Selects the smallest set of tokens whose cumulative probability exceeds top_p.
  /// This creates a dynamic candidate pool size based on the probability distribution.
  /// (default: 0.95, range: 0.0 to 1.0)
  final double topP;

  /// Filters tokens based on a relative probability threshold.
  /// A token is kept if its probability is at least min_p times the probability of the most likely token
  /// (probability ≥ min_p × max_probability) (default: 0.5, 0.0 to 1.0)
  final double minP;

  /// Locally typical sampling keeps tokens whose information content is close to the expected information content.
  /// When typical_p < 1.0, it filters tokens that are "too surprising" or "too obvious". 1.0 = disabled (defaultL 1.0, range: 0.0 to 1.0)
  final double typicalP;

  static CoreSamplingParameters defaults() {
    return CoreSamplingParameters(
      seed: 0,
      minKeep: 0,
      temperature: 0.8,
      topK: 40,
      topP: 0.95,
      minP: 0.5,
      typicalP: 1.0,
    );
  }

  CoreSamplingParameters copyWith({
    int? seed,
    int? minKeep,
    double? temperature,
    int? topK,
    double? topP,
    double? minP,
    double? typicalP,
  }) {
    return CoreSamplingParameters(
      seed: seed ?? this.seed,
      minKeep: minKeep ?? this.minKeep,
      temperature: temperature ?? this.temperature,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      minP: minP ?? this.minP,
      typicalP: typicalP ?? this.typicalP,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'seed': seed,
      'minKeep': minKeep,
      'temperature': temperature,
      'topK': topK,
      'topP': topP,
      'minP': minP,
      'typicalP': typicalP,
    };

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'CoreSamplingParameters(seed: $seed, minKeep: $minKeep, temperature: $temperature, topK: $topK, topP: $topP, minP: $minP, typicalP: $typicalP)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CoreSamplingParameters &&
        other.seed == seed &&
        other.minKeep == minKeep &&
        other.temperature == temperature &&
        other.topK == topK &&
        other.topP == topP &&
        other.minP == minP &&
        other.typicalP == typicalP;
  }

  @override
  int get hashCode {
    return seed.hashCode ^
        minKeep.hashCode ^
        temperature.hashCode ^
        topK.hashCode ^
        topP.hashCode ^
        minP.hashCode ^
        typicalP.hashCode;
  }
}

/// Penaulty Sampling
/// Penalties discourage repetition and promote diversity by modifying token logits based on generation history.
@immutable
class PenaltySamplingParameters {
  PenaltySamplingParameters({
    required this.repeat,
    required this.frequency,
    required this.presence,
    required this.lastN,
  });

  factory PenaltySamplingParameters.fromMap(Map<String, dynamic> map) {
    return PenaltySamplingParameters(
      repeat: (map['repeat'] ?? 0.0) as double,
      frequency: (map['frequency'] ?? 0.0) as double,
      presence: (map['presence'] ?? 0.0) as double,
      lastN: (map['lastN'] ?? 0) as int,
    );
  }

  factory PenaltySamplingParameters.fromJson(String source) =>
      PenaltySamplingParameters.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// Penalizes tokens that appear in context. >1.0 = discourage, <1.0 = encourage
  /// Applied multiplicatively - divides logit by repeat_penalty for tokens in the last N tokens (default 1.0, range: 0.0 to inf)
  final double repeat;

  /// Penalizes tokens proportional to their frequency in context.
  /// Applied additively - subtracts frequency_penalty × count where count is the number of occurrences
  /// (default: 0, range: -2.0 to 2.0)
  final double frequency;

  /// Penalizes tokens that appear at all in context (binary).
  /// Applied additively - subtracts presence_penalty if token appears at least once
  /// (default: 0, range: -2.0 to 2.0)
  final double presence;

  /// Controls how many recent tokens are examined for penalties,
  /// specifying number of recent tokens to consider for penalties. (default: 64, range: 1 to n_ctx)
  final int lastN;

  static PenaltySamplingParameters defaults() {
    return PenaltySamplingParameters(
      repeat: 1.0,
      frequency: 0,
      presence: 0,
      lastN: 64,
    );
  }

  PenaltySamplingParameters copyWith({
    double? repeat,
    double? frequency,
    double? presence,
    int? lastN,
  }) {
    return PenaltySamplingParameters(
      repeat: repeat ?? this.repeat,
      frequency: frequency ?? this.frequency,
      presence: presence ?? this.presence,
      lastN: lastN ?? this.lastN,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'repeat': repeat,
      'frequency': frequency,
      'presence': presence,
      'lastN': lastN,
    };

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'PenaltySamplingParameters(repeat: $repeat, frequency: $frequency, presence: $presence, lastN: $lastN)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PenaltySamplingParameters &&
        other.repeat == repeat &&
        other.frequency == frequency &&
        other.presence == presence &&
        other.lastN == lastN;
  }

  @override
  int get hashCode {
    return repeat.hashCode ^
        frequency.hashCode ^
        presence.hashCode ^
        lastN.hashCode;
  }
}

enum MirostatMode {
  DISABLED(0),
  V1(1),
  V2(2);

  final int value;
  const MirostatMode(this.value);

  static MirostatMode fromValue(int mode) {
    return switch (mode) {
      0 => MirostatMode.DISABLED,
      1 => MirostatMode.V1,
      2 => MirostatMode.V2,
      _ => MirostatMode.DISABLED,
    };
  }
}

/// Mirostat Sampling
/// Mirostat is an adaptive sampling algorithm that maintains text perplexity
/// around a target value, adjusting the sampling distribution dynamically.
@immutable
class MirostatSamplingParameters {
  MirostatSamplingParameters({
    required this.mode,
    required this.tau,
    required this.eta,
  });

  factory MirostatSamplingParameters.fromMap(Map<String, dynamic> map) {
    return MirostatSamplingParameters(
      mode: MirostatMode.fromValue((map['mode'] ?? 0) as int),
      tau: (map['tau'] ?? 0.0) as double,
      eta: (map['eta'] ?? 0.0) as double,
    );
  }

  factory MirostatSamplingParameters.fromJson(String source) =>
      MirostatSamplingParameters.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// Mirostat maintains a running estimate of text perplexity (stored in self._mirostat_mu) and adjusts sampling to keep it close to mirostat_tau.
  /// 0 = disabled, 1 = Mirostat v1, 2 = Mirostat v2
  final MirostatMode mode;

  /// Controls the balance between coherence and diversity of the output. A
  /// lower value will result in more focused and coherent text.
  /// Target perplexity (τ), default: 5.0
  /// (Default: 5.0)
  final double tau;

  /// Influences how quickly the algorithm responds to feedback from the
  /// generated text. A lower learning rate will result in slower adjustments,
  /// while a higher learning rate will make the algorithm more responsive.
  /// Learning rate (η) for adaptation, default: 0.1
  /// (Default: 0.1)
  final double eta;

  static MirostatSamplingParameters defaults() {
    return MirostatSamplingParameters(
      mode: MirostatMode.DISABLED,
      tau: 5.0,
      eta: 0.1,
    );
  }

  MirostatSamplingParameters copyWith({
    MirostatMode? mode,
    double? tau,
    double? eta,
  }) {
    return MirostatSamplingParameters(
      mode: mode ?? this.mode,
      tau: tau ?? this.tau,
      eta: eta ?? this.eta,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'mode': mode.value,
      'tau': tau,
      'eta': eta,
    };

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'MirostatSamplingParameters(mode: $mode, tau: $tau, eta: $eta)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MirostatSamplingParameters &&
        other.mode == mode &&
        other.tau == tau &&
        other.eta == eta;
  }

  @override
  int get hashCode => mode.hashCode ^ tau.hashCode ^ eta.hashCode;
}

/// XTC Sampling
/// XTC (eXclude Top Choices) is an advanced sampling technique that temporarily excludes the most likely tokens to encourage diversity.
@immutable
class XTCSamplingParameters {
  XTCSamplingParameters({
    required this.probability,
    required this.threshold,
  });

  static XTCSamplingParameters defaults() {
    return XTCSamplingParameters(probability: 0.0, threshold: 0.1);
  }

  factory XTCSamplingParameters.fromMap(Map<String, dynamic> map) {
    return XTCSamplingParameters(
      probability: (map['probability'] ?? 0.0) as double,
      threshold: (map['threshold'] ?? 0.1) as double,
    );
  }

  factory XTCSamplingParameters.fromJson(String source) =>
      XTCSamplingParameters.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// The probability threshold for XTC sampling. (default: 0.0)
  final double probability;

  /// The threshold value for XTC sampling. min_keep (default: 0.1)
  final double threshold;

  XTCSamplingParameters copyWith({
    double? probability,
    double? threshold,
  }) {
    return XTCSamplingParameters(
      probability: probability ?? this.probability,
      threshold: threshold ?? this.threshold,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'probability': probability,
      'threshold': threshold,
    };

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'XTCSamplingParameters(probability: $probability, threshold: $threshold)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is XTCSamplingParameters &&
        other.probability == probability &&
        other.threshold == threshold;
  }

  @override
  int get hashCode => probability.hashCode ^ threshold.hashCode;
}

class TopNSigmaParameters {
  final double topNSigma;
  TopNSigmaParameters({
    required this.topNSigma,
  });

  static TopNSigmaParameters defaults() {
    return TopNSigmaParameters(topNSigma: 0.0);
  }

  TopNSigmaParameters copyWith({
    double? topNSigma,
  }) {
    return TopNSigmaParameters(
      topNSigma: topNSigma ?? this.topNSigma,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'topNSigma': topNSigma});

    return result;
  }

  factory TopNSigmaParameters.fromMap(Map<String, dynamic> map) {
    return TopNSigmaParameters(
      topNSigma: (map['topNSigma'] ?? 0.0) as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory TopNSigmaParameters.fromJson(String source) =>
      TopNSigmaParameters.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'TopNSigmaParameters(topNSigma: $topNSigma)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TopNSigmaParameters && other.topNSigma == topNSigma;
  }

  @override
  int get hashCode => topNSigma.hashCode;
}

/// DRY (Don't Repeat Yourself) Sampling
/// DRY sampling penalizes repetition of sequences rather than individual tokens, helping prevent the model from repeating phrases.
@immutable
class DRYSamplingParameters {
  DRYSamplingParameters({
    required this.multiplier,
    required this.base,
    required this.allowedLength,
    required this.penaltyLastN,
  });

  static DRYSamplingParameters defaults() {
    return DRYSamplingParameters(
      multiplier: 0.0,
      base: 1.75,
      allowedLength: 0,
      penaltyLastN: 0,
    );
  }

  factory DRYSamplingParameters.fromMap(Map<String, dynamic> map) {
    return DRYSamplingParameters(
      multiplier: (map['multiplier'] ?? 0.0) as double,
      base: (map['base'] ?? 1.75) as double,
      allowedLength: (map['allowedLength'] ?? 2) as int,
      penaltyLastN: (map['penaltyLastN'] ?? -1) as int,
    );
  }

  factory DRYSamplingParameters.fromJson(String source) =>
      DRYSamplingParameters.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  /// The multiplier for the penalty. (default: 0.0)
  final double multiplier;

  /// The base value for the penalty. (default: 1.75)
  final double base;

  /// The maximum allowed length for the sequence. (default: 2)
  final int allowedLength;

  /// The penalty for the last N items. (default: -1, disabled)
  final int penaltyLastN;

  DRYSamplingParameters copyWith({
    double? multiplier,
    double? base,
    int? allowedLength,
    int? penaltyLastN,
  }) {
    return DRYSamplingParameters(
      multiplier: multiplier ?? this.multiplier,
      base: base ?? this.base,
      allowedLength: allowedLength ?? this.allowedLength,
      penaltyLastN: penaltyLastN ?? this.penaltyLastN,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{
      'multiplier': multiplier,
      'base': base,
      'allowedLength': allowedLength,
      'penaltyLastN': penaltyLastN,
    };

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'DRYSamplingParameters(multiplier: $multiplier, base: $base, allowedLength: $allowedLength, penaltyLastN: $penaltyLastN)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DRYSamplingParameters &&
        other.multiplier == multiplier &&
        other.base == base &&
        other.allowedLength == allowedLength &&
        other.penaltyLastN == penaltyLastN;
  }

  @override
  int get hashCode {
    return multiplier.hashCode ^
        base.hashCode ^
        allowedLength.hashCode ^
        penaltyLastN.hashCode;
  }
}

/// Controls sampler chain architecture, where multiple sampling operations are applied sequentially to
/// transform the raw logits into a probability distribution from which the next token is selected.
@immutable
class SamplerChainSettings {
  SamplerChainSettings({
    required this.withDRY,
    required this.withXTC,
    required this.withPenalty,
    required this.withTopNSigma,
    required this.disabled,
    required this.contextSize,
    required this.core,
    required this.penalty,
    required this.mirostat,
    required this.dry,
    required this.xtc,
    required this.topNSigma,
  });

  factory SamplerChainSettings.fromMap(Map<String, dynamic> map) {
    return SamplerChainSettings(
      disabled: (map['disabled'] ?? false) as bool,
      withDRY: (map['withDRY'] ?? false) as bool,
      withXTC: (map['withXTC'] ?? false) as bool,
      withPenalty: (map['withPenalty'] ?? false) as bool,
      withTopNSigma: (map['withTopNSigma'] ?? false) as bool,
      contextSize: (map['contextSize'] ?? 0) as int,
      core: CoreSamplingParameters.fromMap(map['core'] as Map<String, dynamic>),
      penalty: PenaltySamplingParameters.fromMap(
        map['penalty'] as Map<String, dynamic>,
      ),
      mirostat: MirostatSamplingParameters.fromMap(
        map['mirostat'] as Map<String, dynamic>,
      ),
      dry: DRYSamplingParameters.fromMap(map['dry'] as Map<String, dynamic>),
      xtc: XTCSamplingParameters.fromMap(map['xtc'] as Map<String, dynamic>),
      topNSigma: TopNSigmaParameters.fromMap(
        map['topNSigma'] as Map<String, dynamic>,
      ),
    );
  }

  factory SamplerChainSettings.fromJson(String source) =>
      SamplerChainSettings.fromMap(json.decode(source) as Map<String, dynamic>);
  final bool withDRY;
  final bool withXTC;
  final bool withPenalty;
  final bool withTopNSigma;
  final bool disabled;
  final int contextSize;

  final CoreSamplingParameters core;
  final PenaltySamplingParameters penalty;
  final MirostatSamplingParameters mirostat;
  final DRYSamplingParameters dry;
  final XTCSamplingParameters xtc;
  final TopNSigmaParameters topNSigma;

  SamplerChainSettings copyWith({
    bool? withDRY,
    bool? withXTC,
    bool? withPenalty,
    bool? withTopNSigma,
    bool? disabled,
    int? contextSize,
    CoreSamplingParameters? core,
    PenaltySamplingParameters? penalty,
    MirostatSamplingParameters? mirostat,
    DRYSamplingParameters? dry,
    XTCSamplingParameters? xtc,
    TopNSigmaParameters? topNSigma,
  }) {
    return SamplerChainSettings(
      disabled: disabled ?? this.disabled,
      withDRY: withDRY ?? this.withDRY,
      withXTC: withXTC ?? this.withXTC,
      withPenalty: withPenalty ?? this.withPenalty,
      withTopNSigma: withTopNSigma ?? this.withTopNSigma,
      contextSize: contextSize ?? this.contextSize,
      core: core ?? this.core,
      penalty: penalty ?? this.penalty,
      mirostat: mirostat ?? this.mirostat,
      dry: dry ?? this.dry,
      xtc: xtc ?? this.xtc,
      topNSigma: topNSigma ?? this.topNSigma,
    );
  }

  static SamplerChainSettings defaults() {
    return SamplerChainSettings(
      withDRY: true,
      withXTC: true,
      withPenalty: true,
      withTopNSigma: false,
      disabled: false,
      contextSize: 0,
      core: CoreSamplingParameters.defaults(),
      penalty: PenaltySamplingParameters.defaults(),
      mirostat: MirostatSamplingParameters.defaults(),
      dry: DRYSamplingParameters.defaults(),
      xtc: XTCSamplingParameters.defaults(),
      topNSigma: TopNSigmaParameters.defaults(),
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'disabled': disabled});
    result.addAll({'withDRY': withDRY});
    result.addAll({'withXTC': withXTC});
    result.addAll({'withPenalty': withPenalty});
    result.addAll({'withTopNSigma': withTopNSigma});
    result.addAll({'contextSize': contextSize});
    result.addAll({'core': core.toMap()});
    result.addAll({'penalty': penalty.toMap()});
    result.addAll({'mirostat': mirostat.toMap()});
    result.addAll({'dry': dry.toMap()});
    result.addAll({'xtc': xtc.toMap()});
    result.addAll({'topNSigma': topNSigma.toMap()});

    return result;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return '''
    SamplerChainSettings:
    \tdisabled: $disabled
    \tDRY.enabled: $withDRY
    \tXTC.enabled: $withXTC
    \tPenalty.enabled: $withPenalty
    \tTopNSigma.enabled: $withTopNSigma
    \tcontextSize: $contextSize
    \tcore: $core
    \tpenalty: $penalty
    \tmirostat: $mirostat
    \tdry: $dry
    \txtc: $xtc
    \ttopNSigma: $topNSigma
    ''';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SamplerChainSettings &&
        other.withDRY == withDRY &&
        other.disabled == disabled &&
        other.withXTC == withXTC &&
        other.withPenalty == withPenalty &&
        other.withTopNSigma == withTopNSigma &&
        other.contextSize == contextSize &&
        other.core == core &&
        other.penalty == penalty &&
        other.mirostat == mirostat &&
        other.dry == dry &&
        other.xtc == xtc &&
        other.topNSigma == topNSigma;
  }

  @override
  int get hashCode {
    return disabled.hashCode ^
        withDRY.hashCode ^
        withXTC.hashCode ^
        withPenalty.hashCode ^
        withTopNSigma.hashCode ^
        contextSize.hashCode ^
        core.hashCode ^
        penalty.hashCode ^
        mirostat.hashCode ^
        dry.hashCode ^
        xtc.hashCode ^
        topNSigma.hashCode;
  }
}

class SamplerChainSettingsController extends JuneState {
  SamplerChainSettings settings = SamplerChainSettings.defaults();

  void update({
    bool? withDRY,
    bool? withXTC,
    bool? withPenalty,
    bool? withTopNSigma,
    bool? disabled,
    int? contextSize,
    int? seed,
    int? minKeep,
    double? temperature,
    int? topK,
    double? topP,
    double? minP,
    double? typicalP,
    double? repeatPenalty,
    double? frequencyPenalty,
    double? presencePenalty,
    int? lastNPenalty,
    MirostatMode? mirostat,
    double? tau,
    double? eta,
    double? dryMultiplier,
    double? dryBase,
    int? dryAllowedLength,
    int? dryPenaltyLastN,
    double? xtcProbability,
    double? xtcThreshold,
    double? topNSigma,
  }) {
    final newXTC = settings.xtc.copyWith(
      probability: xtcProbability,
      threshold: xtcThreshold,
    );
    final newTopNSigma = settings.topNSigma.copyWith(topNSigma: topNSigma);
    final newDRY = settings.dry.copyWith(
      multiplier: dryMultiplier,
      base: dryBase,
      allowedLength: dryAllowedLength,
      penaltyLastN: dryPenaltyLastN,
    );
    final newPenalty = settings.penalty.copyWith(
      repeat: repeatPenalty,
      frequency: frequencyPenalty,
      presence: presencePenalty,
      lastN: lastNPenalty,
    );
    final newCore = settings.core.copyWith(
      seed: seed,
      minKeep: minKeep,
      temperature: temperature,
      typicalP: typicalP,
      minP: minP,
      topP: topP,
      topK: topK,
    );

    final newMiroStat = settings.mirostat.copyWith(
      mode: mirostat,
      eta: eta,
      tau: tau,
    );

    settings = settings.copyWith(
      withDRY: withDRY,
      withPenalty: withPenalty,
      withTopNSigma: withTopNSigma,
      withXTC: withXTC,
      topNSigma: newTopNSigma,
      contextSize: contextSize,
      mirostat: newMiroStat,
      core: newCore,
      dry: newDRY,
      penalty: newPenalty,
      xtc: newXTC,
      disabled: disabled,
    );
    if (kDebugMode) {
      print('$settings');
    }
    setState();
  }
}

enum InitializationStatus {
  INITIALIZING,
  INITIALIZED,
  STARTING,
  COMPLETED,
  VERIFYING,
  VERIFIED,
  VALIDATING,
  VALIDATED,
  CONFIGURING,
  CONFIGURED,
  FAILURE,
}

typedef ComponentStatus = ({String name, InitializationStatus status});

class InitializationStatusController extends JuneState {
  final Set<ComponentStatus> statuses = <ComponentStatus>{};

  String get message =>
      statuses.isNotEmpty
          ? switch (statuses.first.status) {
            InitializationStatus.INITIALIZING =>
              'Initializing ${statuses.first.name}',
            InitializationStatus.INITIALIZED =>
              'Initialized ${statuses.first.name}',
            InitializationStatus.STARTING => 'Starting ${statuses.first.name}',
            InitializationStatus.COMPLETED =>
              'Completed ${statuses.first.name}',
            InitializationStatus.FAILURE => 'Failed ${statuses.first.name}',
            InitializationStatus.VERIFYING =>  'Verifying ${statuses.first.name}',
            InitializationStatus.VERIFIED =>  'Verified ${statuses.first.name}',
            InitializationStatus.VALIDATING =>  'Validating ${statuses.first.name}',
            InitializationStatus.VALIDATED => 'Validated ${statuses.first.name}',
            InitializationStatus.CONFIGURING => 'Configuring ${statuses.first.name}',
            InitializationStatus.CONFIGURED => 'Configured ${statuses.first.name}',
          }
          : '...';

  void update(ComponentStatus status) {
    statuses.clear();
    statuses.add(status);
    setState();
  }
}
