import 'dart:math';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:flutter/foundation.dart';
import 'package:markdown/markdown.dart';
import 'package:remove_emoji/remove_emoji.dart';

typedef Voice = ({int sid, double speed});


enum ResponseSegmentType { Context, Thinking, Answer }

final class Oratory {
  final ResponseSegmentType type;
  final String text;
  const Oratory(this.type, this.text);
}

typedef ThinkingTags = ({String start_tag, String end_tag});

typedef ReasoningContext = ({bool reasoning, String? startTag, String? endTag});

final class Dialoguizer {
  // static final String pattern = '(?<=[(?!Dr.|Mr.|Ms.|Mr.)(.!?)*])\s+';
  /*final RegExp separators = RegExp(
    r'[.!?]+\s+',
    caseSensitive: false,
    multiLine: true,
    unicode: true,
  );*/
  Pattern separators;
  final StringBuffer fragment = StringBuffer();
  bool _startOfThought = false;
  bool _startOfAnswer = false;
  final removeEmoji = RemoveEmoji();

  final bool reasoning;
  final ThinkingTags? tags;
  Dialoguizer({
    required this.separators,
    required this.reasoning,
    ThinkingTags? thinking,
  }) : tags =
           thinking ??
           (reasoning ? (start_tag: '<think>', end_tag: '</think>') : null);

  ResponseSegmentType _responseStatus = ResponseSegmentType.Context;

  List<Oratory> _tokenizeSentences(String text) {
    fragment.write(text);
    List<String> fragments = [];

    String paragraph = fragment.toString().splitMapJoin(
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
      if (paragraph.contains(tags!.start_tag) &&
          _responseStatus == ResponseSegmentType.Context) {
        _responseStatus = ResponseSegmentType.Thinking;
        _startOfThought = true;
      }
      if (paragraph.contains(tags!.end_tag)) {
        _responseStatus = ResponseSegmentType.Answer;
        _startOfAnswer = true;
      }
    } else {
      _responseStatus = ResponseSegmentType.Answer;
      _startOfThought = true;
      _startOfThought = true;
    }
    fragment.clear();
    List<Oratory> sentences = [];
    int j = max(fragments.length - 1, 0);
    for (int i = 0; i < j; i++) {
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
      fragment.write(fragments[i]);
    }
    return sentences;
  }

  Oratory reset() {
    final last =
        fragment.isNotEmpty
            ? Oratory(
              _responseStatus,
              BeautifulSoup(
                markdownToHtml(fragment.toString()),
              ).body!.p!.text.replaceAll('**', ''),
            )
            : Oratory(ResponseSegmentType.Answer, '');
    fragment.clear();
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
    Map<String, String> parts = <String, String>{};
    String context = "";
    String thought = "";
    String parsed = text;
    if (_startOfThought) {
      _startOfThought = false;
      words = parsed.split(tags!.start_tag);
      words = words.map(
        (value) =>
            value.replaceAll(RegExp(tags!.start_tag, caseSensitive: true), ''),
      );
      if (words.length > 1) {
        context = words.first;
        parsed = words.last;
      }
    }
    if (_startOfAnswer) {
      _startOfAnswer = false;
      words = parsed.split(tags!.end_tag);
      words = words.map(
        (value) =>
            value.replaceAll(RegExp(tags!.end_tag, caseSensitive: true), ''),
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
    final _tags = tags ?? (start_tag: '', end_tag: '');
    final parseThoughts =
        _tags.start_tag.isNotEmpty && _tags.end_tag.isNotEmpty;
    String parsed = text;
    if (parseThoughts) {
      final segments = text.split(_tags.start_tag);
      if (segments.length > 1) {
        parts['context'] = segments.first.replaceAll(
          RegExp(_tags.start_tag, caseSensitive: true),
          '',
        );
        parsed = segments.last.replaceAll(
          RegExp(_tags.start_tag, caseSensitive: true),
          '',
        );
      }
      final answer = parsed.split(_tags.end_tag);
      if (answer.length > 1) {
        parts['thought'] = answer.first.replaceAll(
          RegExp(_tags.end_tag, caseSensitive: true),
          '',
        );
        parsed = answer.last.replaceAll(
          RegExp(_tags.end_tag, caseSensitive: true),
          '',
        );
      }
    }
    parts['response'] = parsed;
    return parts;
  }
}
