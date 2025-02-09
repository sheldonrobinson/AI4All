// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as m;

import 'package:byte_converter/byte_converter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:june/june.dart';
import 'package:langchain/langchain.dart';
import 'package:llamacpp/llamacpp.dart';
import 'package:path/path.dart' as p;
import 'package:unnu_shared/unnu_shared.dart';

import '../../unnu_ai_model.dart';

enum ModelFamily {
  Llama(
    familyName: 'Llama',
    logo: 'Octarine',
    style: FontStyle.normal,
    weight: FontWeight.bold,
    text: 'Pitagon Sans Text',
  ),
  Gemma(
    familyName: 'Gemma',
    logo: 'Proletarsk',
    style: FontStyle.normal,
    weight: FontWeight.normal,
    text: 'Pitagon Serif',
  ),
  Phi(
    familyName: 'Phi',
    logo: 'Segoe UI This',
    style: FontStyle.normal,
    weight: FontWeight.normal,
    text: 'Roboto',
  ),
  Qwen(
    familyName: 'Qwen',
    logo: 'Jellee Roman',
    style: FontStyle.normal,
    weight: FontWeight.normal,
    text: 'Poppins',
  ),
  Granite(
    familyName: 'Granite',
    logo: 'IBM Logo',
    style: FontStyle.normal,
    weight: FontWeight.normal,
    text: 'IBM Plex Sans',
  ),
  DeepSeek(
    familyName: 'DeepSeek',
    logo: 'Good Timing Rg',
    style: FontStyle.normal,
    weight: FontWeight.normal,
    text: 'Poppins',
  ),
  Mistral(
    familyName: 'Mistral',
    logo: 'Home Video',
    style: FontStyle.normal,
    weight: FontWeight.bold,
    text: 'IBM Plex Sans',
  ),
  Ernie(
    familyName: 'ERNIE',
    logo: 'Trek',
    style: FontStyle.normal,
    weight: FontWeight.bold,
    text: 'Poppins',
  ),
  Other(
    familyName: 'Other',
    logo: 'Noto Serif',
    style: FontStyle.normal,
    weight: FontWeight.normal,
    text: 'Noto Sans',
  );

  const ModelFamily({
    required this.familyName,
    required this.logo,
    required this.style,
    required this.weight,
    required this.text,
  });
  final String familyName;
  final String logo;
  final FontStyle style;
  final FontWeight weight;
  final String text;

  //  TextTheme textTheme(BuildContext context) {
  //    return buildTextTheme(context, this.text);
  //  }

  static ModelFamily modelFamilyFromFilename(String name) {
    final modelFilename = name.toLowerCase();
    if (modelFilename.startsWith(RegExp(r'llama', caseSensitive: false))) {
      return ModelFamily.Llama;
    } else if (modelFilename.startsWith(RegExp(r'phi', caseSensitive: false)) ||
        modelFilename.startsWith(RegExp(r'microsoft', caseSensitive: false))) {
      return ModelFamily.Phi;
    } else if (modelFilename.startsWith(
      RegExp(r'gemma', caseSensitive: false),
    )) {
      return ModelFamily.Gemma;
    } else if (modelFilename.startsWith(
          RegExp(r'qwen', caseSensitive: false),
        ) ||
        modelFilename.startsWith(RegExp(r'qwq', caseSensitive: false))) {
      return ModelFamily.Qwen;
    } else if (modelFilename.startsWith(
      RegExp(r'granite', caseSensitive: false),
    )) {
      return ModelFamily.Granite;
    } else if (modelFilename.startsWith(
      RegExp(r'deepseek', caseSensitive: false),
    )) {
      return ModelFamily.DeepSeek;
    } else if (modelFilename.startsWith(
      RegExp(r'mistral', caseSensitive: false),
    )) {
      return ModelFamily.Mistral;
    } else if (modelFilename.startsWith(
      RegExp(r'ernie', caseSensitive: false),
    )) {
      return ModelFamily.Ernie;
    } else {
      return ModelFamily.Other;
    }
  }
}

enum LlmResource {
  Unspecified(-1),
  AssetBundle(0),
  LocalFile(1),
  RemoteFile(2),
  AppStore(3),
  Web(4);

  final int value;

  const LlmResource(this.value);

  static LlmResource fromValue(int value) => switch (value) {
    -1 => Unspecified,
    0 => AssetBundle,
    1 => LocalFile,
    2 => RemoteFile,
    3 => AppStore,
    4 => Web,
    _ => throw ArgumentError('Unknown value for LlmResourceLocation: $value'),
  };
}

class LlmMetaInfo {
  String baseName;
  String version;
  String sizeLabel;
  String encoding;
  String type;
  String fileName;
  Uri uri;
  String filePath;
  String nameInNamingConvention;
  String shard;
  LlmResource location;
  int parameterCount;
  int numberOfExperts;
  LlmMetaInfo({
    required this.baseName,
    required this.version,
    required this.sizeLabel,
    required this.encoding,
    required this.type,
    required this.fileName,
    required this.uri,
    required this.filePath,
    required this.nameInNamingConvention,
    required this.shard,
    required this.location,
    required this.parameterCount,
    required this.numberOfExperts,
  });

  double get vram => vRamSize();

  ModelFamily get modelFamily => ModelFamily.modelFamilyFromFilename(baseName);

  ReasoningContext get reasoningContext => _reasoningContextFromInfo();
  static const log1024 = 6.9314718055994530941723212145818;

  String vRamAsHumanReadable() {
    final bytes = vram;
    final order = (m.log(bytes) / log1024).floor();
    final converter = ByteConverter(bytes);
    switch (order) {
      case 0:
        return converter.toHumanReadable(SizeUnit.B, precision: 0);
      case 1:
        return converter.toHumanReadable(SizeUnit.KB, precision: 1);
      case 2:
        return converter.toHumanReadable(SizeUnit.MB, precision: 1);
      case 3:
        return converter.toHumanReadable(SizeUnit.GB, precision: 1);
      default:
        return converter.toHumanReadable(SizeUnit.TB, precision: 1);
    }
  }

  static int numberOfParmeters(String sizelabel) {
    final segments = sizelabel.split('x');
    final paramCount = segments.last;
    final mult =
        paramCount.length > 1
            ? paramCount.substring(paramCount.length - 1).toUpperCase()
            : '';
    final numParams = double.parse(
      paramCount.length > 1
          ? paramCount.substring(0, paramCount.length - 1)
          : '0.0',
    );
    switch (mult) {
      case 'K':
        return (numParams * 1024).ceil();
      case 'M':
        return (numParams * 1024 * 1024).ceil();
      case 'B':
        return (numParams * 1024 * 1024 * 1024).ceil();
      case 'T':
        return (numParams * 1024 * 1024 * 1024 * 1024).ceil();
      default:
        return numParams.ceil();
    }
  }

  static double kvCacheQuantFactor(String encoding) {
    final scheme = encoding.toUpperCase();
    if (scheme.startsWith('F32')) {
      return 4.0;
    } else if (scheme.startsWith('F16')) {
      return 2.0;
    } else if (scheme.startsWith('Q8')) {
      return 1.0;
    } else if (scheme.startsWith('Q6')) {
      return 0.75;
    } else if (scheme.startsWith('Q5')) {
      return 0.625;
    } else if (scheme.startsWith('Q4')) {
      return 0.5;
    } else if (scheme.startsWith('Q3')) {
      return 0.375;
    } else if (scheme.startsWith('Q2')) {
      return 0.25;
    } else if (scheme.startsWith('AWQ')) {
      return 0.35;
    } else if (scheme.startsWith('GPTQ')) {
      return 0.4;
    }
    return 1.0;
  }

  double vRamSize({String inferenceScheme = 'Q8', int nCtx = 16384}) {
    final alpha_2048 = 0.2;
    final overHead = 1.1;
    final totalParams = numberOfExperts * parameterCount;
    final kvFactor = kvCacheQuantFactor(encoding);
    final kvInference = kvCacheQuantFactor(inferenceScheme);
    final kvScale = (nCtx / 2048) * 1.1 * kvInference;
    final requiredMem =
        overHead * totalParams * (kvFactor + alpha_2048 * kvScale);
    return requiredMem;
  }

  static int countOfExperts(String sizelabel) {
    final segments = sizelabel.split('x');
    final expertsCount = segments.length > 1 ? segments.first : '1';
    return int.parse(expertsCount);
  }

  ReasoningContext _reasoningContextFromInfo() {
    final name = baseName.toLowerCase();
    switch (modelFamily) {
      case ModelFamily.Llama:
        return (reasoning: false, startTag: null, endTag: null);
      case ModelFamily.Gemma:
        return (reasoning: false, startTag: null, endTag: null);
      case ModelFamily.Phi:
        return name.contains(RegExp(r'reasoning', caseSensitive: false))
            ? (reasoning: true, startTag: "<think>", endTag: "</think>")
            : (reasoning: false, startTag: null, endTag: null);
      case ModelFamily.Qwen:
        return name.startsWith(RegExp(r'qwen3', caseSensitive: false)) ||
                name.startsWith(RegExp(r'qwq', caseSensitive: false))
            ? (reasoning: true, startTag: "<think>", endTag: "</think>")
            : (reasoning: false, startTag: null, endTag: null);
      case ModelFamily.Granite:
        return (reasoning: false, startTag: "<think>", endTag: "</think>");
      case ModelFamily.Ernie:
        return (reasoning: false, startTag: "<think>", endTag: "</think>");
      case ModelFamily.DeepSeek:
        return name.startsWith(RegExp(r'deepseek-r', caseSensitive: false))
            ? (reasoning: true, startTag: "<think>", endTag: "</think>")
            : (reasoning: false, startTag: null, endTag: null);
      case ModelFamily.Mistral:
        return (reasoning: false, startTag: null, endTag: null);
      case ModelFamily.Other:
        return (reasoning: false, startTag: null, endTag: null);
    }
  }

  LlmMetaInfo copyWith({
    String? baseName,
    String? version,
    String? sizeLabel,
    String? encoding,
    String? type,
    String? fileName,
    Uri? uri,
    String? filePath,
    String? nameInNamingConvention,
    String? shard,
    LlmResource? location,
    int? parameterCount,
    int? numberOfExperts,
  }) {
    return LlmMetaInfo(
      baseName: baseName ?? this.baseName,
      version: version ?? this.version,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      encoding: encoding ?? this.encoding,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      uri: uri ?? this.uri,
      filePath: filePath ?? this.filePath,
      nameInNamingConvention:
          nameInNamingConvention ?? this.nameInNamingConvention,
      shard: shard ?? this.shard,
      location: location ?? this.location,
      parameterCount: parameterCount ?? this.parameterCount,
      numberOfExperts: numberOfExperts ?? this.numberOfExperts,
    );
  }

  static LlmMetaInfo empty() {
    return LlmMetaInfo(
      baseName: '',
      version: '',
      sizeLabel: '',
      encoding: '',
      type: '',
      shard: '',
      fileName: '',
      uri: Uri(),
      filePath: '',
      nameInNamingConvention: '',
      location: LlmResource.Unspecified,
      parameterCount: 0,
      numberOfExperts: 0,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({
      'baseName': baseName,
      'version': version,
      'sizeLabel': sizeLabel,
      'encoding': encoding,
      'type': type,
      'fileName': fileName,
      'uri': uri.toString(),
      'filePath': filePath,
      'nameInNamingConvention': nameInNamingConvention,
      'shard': shard,
      'location': location.value,
      'parameterCount': parameterCount,
      'numberOfExperts': numberOfExperts,
    });

    return result;
  }

  factory LlmMetaInfo.fromMap(Map<String, dynamic> map) {
    return LlmMetaInfo(
      baseName: map['baseName'] ?? '',
      version: map['version'] ?? '',
      sizeLabel: map['sizeLabel'] ?? '',
      encoding: map['encoding'] ?? '',
      type: map['type'] ?? '',
      fileName: map['fileName'] ?? '',
      uri: map.containsKey('uri') ? Uri.parse(map['uri'] ?? '') : Uri(),
      filePath: map['filePath'] ?? '',
      nameInNamingConvention: map['nameInNamingConvention'] ?? '',
      shard: map['shard'] ?? '',
      location: LlmResource.fromValue(
        map['location'] ?? LlmResource.Unspecified.value,
      ),
      parameterCount: (map['parameterCount'] ?? 0) as int,
      numberOfExperts: (map['numberOfExperts'] ?? 0) as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory LlmMetaInfo.fromJson(String source) =>
      LlmMetaInfo.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LlmMetaInfo(baseName: $baseName, version: $version, sizeLabel: $sizeLabel, encoding: $encoding, type: $type, fileName: $fileName, uri: $uri, filePath: $filePath, nameInNamingConvention: $nameInNamingConvention, shard: $shard, location: $location, parameterCount: $parameterCount, numberOfExperts: $numberOfExperts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LlmMetaInfo &&
        other.baseName == baseName &&
        other.version == version &&
        other.sizeLabel == sizeLabel &&
        other.encoding == encoding &&
        other.type == type &&
        other.fileName == fileName &&
        other.uri == uri &&
        other.filePath == filePath &&
        other.nameInNamingConvention == nameInNamingConvention &&
        other.shard == shard &&
        other.location == location;
  }

  @override
  int get hashCode {
    return baseName.hashCode ^
        version.hashCode ^
        sizeLabel.hashCode ^
        encoding.hashCode ^
        type.hashCode ^
        fileName.hashCode ^
        uri.hashCode ^
        filePath.hashCode ^
        nameInNamingConvention.hashCode ^
        shard.hashCode ^
        location.hashCode;
  }
}

class LLMProviderVM {
  LlamaCppProvider llm;
  LlmMetaInfo info;
  LLMProviderVM({required this.llm, required this.info});

  LLMProviderVM copyWith({LlamaCppProvider? llm, LlmMetaInfo? info}) {
    return LLMProviderVM(llm: llm ?? this.llm, info: info ?? this.info);
  }

  static LLMProviderVM getDefaults() {
    return LLMProviderVM(llm: LlamaCppProvider(), info: LlmMetaInfo.empty());
  }

  @override
  String toString() => 'LLMProviderVM(llm: $llm, info: $info)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LLMProviderVM && other.llm == llm && other.info == info;
  }

  @override
  int get hashCode => llm.hashCode ^ info.hashCode;

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'llm': llm});
    result.addAll({'info': info.toMap()});

    return result;
  }

  factory LLMProviderVM.fromMap(Map<String, dynamic> map) {
    return LLMProviderVM(
      llm: map['llm'],
      info: LlmMetaInfo.fromMap(map['info']),
    );
  }

  String toJson() => json.encode(toMap());

  factory LLMProviderVM.fromJson(String source) =>
      LLMProviderVM.fromMap(json.decode(source));
}

class LLMProviderController extends JuneState {
  static final filenameConvention = RegExp(
    r'^(?<BaseName>[A-Za-z0-9\s]*(?:-(?:[A-Za-z\s][A-Za-z0-9\s]*|[0-9\s]*))*)-(?:(?<SizeLabel>(?:\d+x)?(?:\d+\.)?\d+[A-Za-z](?:-[A-Za-z]+(\d+\.)?\d+[A-Za-z]+)?)(?:-(?<FineTune>[A-Za-z0-9\s-]+))?)?-(?<Version>v\d+(?:\.\d+)*)(?:-(?<Encoding>(?!LoRA|vocab)[\w_]+))?(?:-(?<Type>LoRA|vocab))?(?:-(?<Shard>\d{5}-of-\d{5}))?\.gguf$',
    unicode: true,
    caseSensitive: false,
  );

  static final sizeLabelMatcher = RegExp(
    r'(?<SizeLabel>(?:\d+x)?(?:\d+\.)?\d+[A-Za-z](?:-[A-Za-z]+(\d+\.)?\d+[A-Za-z]+)?)',
    unicode: false,
    caseSensitive: false,
  );

  static final versionMatcher = RegExp(
    r'(?<Version>v\d+(?:\.\d+)*)',
    unicode: false,
    caseSensitive: true,
  );

  static final semVerMatcher = RegExp(r'^[1-9]+\.[1-9]\d*$', unicode: false);

  LLMProviderVM activeModel = LLMProviderVM.getDefaults();

  final Map<String, LlmMetaInfo> _modelRegistry = <String, LlmMetaInfo>{};

  List<LlmMetaInfo> get models => UnmodifiableListView(
    _modelRegistry.values.where((value) => !value.uri.hasEmptyPath),
  );

  Stream<LLMResult> get responses => activeModel.llm.model.responses;

  void stop() {
    activeModel.llm.model.stop();
  }

  void cancel() {
    activeModel.llm.model.cancel();
  }

  static LlmMetaInfo parse(String modelPath) {
    LlmMetaInfo metaInfo = LlmMetaInfo.empty();
    final filePath = Uri.file(modelPath, windows: Platform.isWindows);
    final modelFileName = p.basename(modelPath);
    metaInfo = metaInfo.copyWith(
      uri: filePath,
      filePath: modelPath,
      fileName: modelFileName,
    );
    final segments = modelFileName.split('-');
    int idxVersion = -1;
    int idxSizeLabel = -1;
    int idxSemVer = -1;
    int idx = 0;
    for (var part in segments) {
      if (versionMatcher.hasMatch(part) && idxVersion == -1) {
        idxVersion = idx;
      } else if (sizeLabelMatcher.hasMatch(part) && idxSizeLabel == -1) {
        idxSizeLabel = idx;
      } else if (semVerMatcher.hasMatch(part) && idxSemVer == -1) {
        idxSemVer = idx;
      }
      idx++;
      if (idxSizeLabel == -1 || idxVersion == -1) {
        continue;
      } else {
        break;
      }
    }
    idx = 0;
    final toNameConvention = StringBuffer();
    final versionString =
        idxVersion == -1
            ? idxSemVer != -1
                ? 'v${segments[idxSemVer]}'
                : 'v1.0'
            : segments[idxVersion];
    ;
    final sizeLabel = idxSizeLabel == -1 ? '0' : segments[idxSizeLabel];
    final experts = LlmMetaInfo.countOfExperts(sizeLabel);
    final sizeParts = sizeLabel.split('x');
    final szLabel =
        experts > 1
            ? '${sizeParts.first}x${sizeParts.last.toUpperCase()}'
            : sizeLabel.toUpperCase();
    metaInfo = metaInfo.copyWith(
      sizeLabel: szLabel,
      version: versionString,
      parameterCount: LlmMetaInfo.numberOfParmeters(sizeLabel),
      numberOfExperts: LlmMetaInfo.countOfExperts(sizeLabel),
    );

    for (int i = 0; i < idxSizeLabel; i++) {
      if (!(i == idxVersion || i == idxSemVer)) {
        if (i != 0) {
          toNameConvention.write(' ');
        }
        toNameConvention.write(segments[i]);
      }
    }
    final baseName = toNameConvention.toString().replaceAll('_', ' ');
    metaInfo = metaInfo.copyWith(baseName: baseName);
    toNameConvention.clear();
    toNameConvention.write(baseName);
    toNameConvention.write('-');
    toNameConvention.write(szLabel);

    final partialName = toNameConvention.toString();

    for (int i = idxSizeLabel + 1; i < segments.length; i++) {
      toNameConvention.clear();
      toNameConvention.write(partialName);
      for (int j = idxSizeLabel + 1; j < segments.length; j++) {
        if (i == j) {
          toNameConvention.write('-');
          toNameConvention.write(versionString);
        }
        if (j != idxVersion) {
          toNameConvention.write('-');
          toNameConvention.write(segments[j]);
        }
      }
      final tempName = toNameConvention.toString();
      if (filenameConvention.hasMatch(tempName)) {
        break;
      }
    }

    final nameInConversation = toNameConvention.toString();

    if (filenameConvention.hasMatch(nameInConversation)) {
      final matches = filenameConvention.firstMatch(nameInConversation);
      final encoding = matches?.namedGroup('Encoding');
      if (encoding != null) {
        final encodingInConvention = encoding.toUpperCase();
        final updated = nameInConversation.replaceFirst(
          encoding,
          encodingInConvention,
        );
        metaInfo = metaInfo.copyWith(
          encoding: encodingInConvention,
          nameInNamingConvention: updated,
        );
      } else {
        metaInfo = metaInfo.copyWith(
          nameInNamingConvention: nameInConversation,
        );
      }
      metaInfo = metaInfo.copyWith(
        type: matches?.namedGroup('Type'),
        shard: matches?.namedGroup('Shard'),
      );
    } else {
      metaInfo = metaInfo.copyWith(nameInNamingConvention: nameInConversation);
    }
    return metaInfo;
  }

  static LlmMetaInfo asLlMetaInfo(String modelPath, {LlmResource? resource}) {
    final info = LLMProviderController.parse(
      modelPath,
    ).copyWith(location: resource);
    // register(info);
    return info;
  }

  LlmMetaInfo register(LlmMetaInfo info) {
    return _modelRegistry[info.nameInNamingConvention] = info;
  }

  LlmMetaInfo? unregister(LlmMetaInfo info) {
    return _modelRegistry.remove(info.nameInNamingConvention);
  }

  void delist(String modelPath) {
    LlmMetaInfo info = LLMProviderController.parse(modelPath);
    unregister(info);
  }

  void reset() {
    activeModel.llm.model.reset();
    setState();
  }

  Stream<double> switchModel(LlmMetaInfo info) async* {
    if (kDebugMode) {
      print('switchModel(LlmMetaInfo) info = $info');
    }
    final fileLocation =
        info.location == LlmResource.AssetBundle
            ? info.filePath.isEmpty
                ? (
                  Platform.isAndroid || Platform.isIOS
                      ? await copyAssetOnMobile(info.uri.path)
                      : await copyAssetFile(info.uri.path),
                  true,
                )
                : (info.filePath, false)
            : info.location == LlmResource.LocalFile
            ? (info.filePath, false)
            : (info.uri.path, false);

    final params = LlamaCppParams.defaultParams().copyWith(
      modelPath: fileLocation.$1,
      splitMode: lcpp_split_mode.LCPP_SPLIT_MODE_LAYER,
      mainGPU: 0,
      nGpuLayers: 127,
      useMmap: true,
      useMlock: true,
    );

    if (kDebugMode) {
      print('activeModel oldInfo = $activeModel');
    }
    activeModel.llm.close();
    final newInfo = info.copyWith(filePath: fileLocation.$1);
    activeModel = activeModel.copyWith(
      llm: LlamaCppProvider(
        contextParams: ContextParams.defaultParams().copyWith(nCtx: 16384),
        lcppParams: params,
        defaultOptions: LcppOptions(model: newInfo.baseName),
      ),
      info: newInfo,
    );
    if (fileLocation.$2) {
      unregister(info);
    }
    register(newInfo);
    setState();
    if (kDebugMode) {
      print('activeModel newInfo = $activeModel');
    }
    final progress = activeModel.llm.model.reconfigure();
    yield* progress;
  }

  @override
  void dispose() {
    activeModel.llm.model.destroy();
    super.dispose();
  }

  String get name => activeModel.info.baseName;

  String get modelPath => activeModel.info.filePath;

  String get description => activeModel.info.nameInNamingConvention;

  String get type => activeModel.llm.modelType;

  ReasoningContext get reasoningContext => activeModel.info.reasoningContext;
}
