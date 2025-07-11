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
import 'package:unnu_aux/unnu_aux.dart';
import 'package:unnu_shared/unnu_shared.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../../unnu_ai_model.dart';

enum UnnuQueryFragmentType {
  CHAT_HISTORY,
  CURRENT_INFO,
  USER_QUERY,
  OTHER;
}

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
  GPT(
    familyName: 'GPT',
    logo: 'Noto Serif',
    style: FontStyle.normal,
    weight: FontWeight.normal,
    text: 'Noto Sans',
  ),
  Seed(
    familyName: 'Seed',
    logo: 'Noto Serif',
    style: FontStyle.normal,
    weight: FontWeight.normal,
    text: 'Noto Sans',
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

  static ModelFamily modelFamilyFromName(String name) {
    final modelFilename = name.toLowerCase();
    if (modelFilename.startsWith(RegExp('llama', caseSensitive: false))) {
      return ModelFamily.Llama;
    } else if (modelFilename.startsWith(RegExp('phi|microsoft', caseSensitive: false))) {
      return ModelFamily.Phi;
    } else if (modelFilename.startsWith(
      RegExp('gemma', caseSensitive: false),
    )) {
      return ModelFamily.Gemma;
    } else if (modelFilename.startsWith(
          RegExp('qwen|qwq', caseSensitive: false),
        ) ) {
      return ModelFamily.Qwen;
    } else if (modelFilename.startsWith(
      RegExp('granite', caseSensitive: false),
    )) {
      return ModelFamily.Granite;
    } else if (modelFilename.startsWith(
      RegExp('deepseek', caseSensitive: false),
    )) {
      return ModelFamily.DeepSeek;
    } else if (modelFilename.startsWith(
      RegExp('mistral|magistral', caseSensitive: false),
    )) {
      return ModelFamily.Mistral;
    } else if (modelFilename.startsWith(
      RegExp('ernie', caseSensitive: false),
    )) {
      return ModelFamily.Ernie;
    } else if (modelFilename.startsWith(
      RegExp('gpt', caseSensitive: false),
    )) {
      return ModelFamily.GPT;
    } else if (modelFilename.startsWith(
      RegExp('seed', caseSensitive: false),
    )) {
      return ModelFamily.Seed;
    } else {
      return ModelFamily.Other;
    }
  }
}

@immutable
class LlmMetaInfo {
  final String version;
  final String sizeLabel;
  final String encoding;
  final String type;
  final String filePath;
  final String nameInNamingConvention;
  final String shard;
  final int nCtx;

  final int _parameterCount;
  final int _numberOfExperts;
  final ModelFamily _modelFamily;
  LlmMetaInfo({
    required this.filePath,
    required this.nameInNamingConvention,
    required this.version,
    required this.sizeLabel,
    required this.encoding,
    required this.type,
    required this.shard,
    required this.nCtx,
  }) : _parameterCount = LlmMetaInfo.numberOfParmeters(sizeLabel),
       _numberOfExperts = LlmMetaInfo.countOfExperts(sizeLabel),
       _modelFamily = ModelFamily.modelFamilyFromName(nameInNamingConvention);

  Map<int, double> get vram =>
      vRamSize(nCtx, inferenceScheme: encoding.isNotEmpty ? encoding : 'Q8');

  int get numberOfExperts => _numberOfExperts;

  int get parameters => _parameterCount;

  ModelFamily get modelFamily => _modelFamily;

  // ReasoningContext get reasoningContext => _reasoningContextFromInfo();
  static const log1024 = 6.9314718055994530941723212145818;

  String vRamAsHumanReadable() {
    final bytes = vram.values.reduce(m.max);
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
    final numParams =
        double.tryParse(
          paramCount.length > 1
              ? paramCount.substring(0, paramCount.length - 1)
              : '0.0',
        ) ??
        0.0;
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

  static int countOfExperts(String sizeLabel, {int? experts}) {
    final segments = sizeLabel.split('x');
    final nMoE = segments.length > 1 ? segments.first : '1';
    return int.tryParse(nMoE) ?? experts ?? 1;
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
    } else if (scheme.startsWith('Q4') || scheme.startsWith('IQ4')) {
      return 0.5;
    } else if (scheme.startsWith('Q3') || scheme.startsWith('IQ3')) {
      return 0.375;
    } else if (scheme.startsWith('Q2') || scheme.startsWith('IQ2')) {
      return 0.25;
    } else if (scheme.startsWith('MXFP4')) {
      return 0.5;
    } else if (scheme.startsWith('AWQ')) {
      return 0.35;
    } else if (scheme.startsWith('GPTQ')) {
      return 0.4;
    }
    return 1.0;
  }

  Map<int, double> vRamSize(int n_Ctx, {String inferenceScheme = 'Q8'}) {
    final mappings = <int, double>{};
    final last = (m.max(m.log(n_Ctx) / m.ln2, 11) + 1).toInt();
    const alpha_2048 = 0.2;
    const overHead = 1.1;
    final totalParams = _numberOfExperts * _parameterCount;
    final kvFactor = kvCacheQuantFactor(encoding);
    final kvInference = kvCacheQuantFactor(inferenceScheme);
    for (var i = 11; i < last; i++) {
      final idx = m.pow(2, i) as int;
      final kvScale = (idx / 2048) * 1.1 * kvInference;
      final requiredMem =
          overHead * totalParams * (kvFactor + alpha_2048 * kvScale);
      mappings[idx] = requiredMem;
    }

    return mappings;
  }

  // ReasoningContext _reasoningContextFromInfo() {
  //   final name = nameInNamingConvention.toLowerCase();
  //   switch (modelFamily) {
  //     case ModelFamily.Llama:
  //       return (reasoning: false, startTag: null, endTag: null);
  //     case ModelFamily.Gemma:
  //       return (reasoning: false, startTag: null, endTag: null);
  //     case ModelFamily.Phi:
  //       return name.contains(RegExp('reasoning', caseSensitive: false))
  //           ? (reasoning: true, startTag: '<think>', endTag: '</think>')
  //           : (reasoning: false, startTag: null, endTag: null);
  //     case ModelFamily.Qwen:
  //       return name.startsWith(RegExp(r'qwen3', caseSensitive: false)) ||
  //               name.startsWith(RegExp('qwq', caseSensitive: false))
  //           ? (reasoning: true, startTag: '<think>', endTag: '</think>')
  //           : (reasoning: false, startTag: null, endTag: null);
  //     case ModelFamily.Granite:
  //       return (reasoning: true, startTag: '<think>', endTag: "</think>");
  //     case ModelFamily.Ernie:
  //       return (reasoning: false, startTag: '<think>', endTag: '</think>');
  //     case ModelFamily.DeepSeek:
  //       return (reasoning: true, startTag: '<think>', endTag: "</think>");
  //     case ModelFamily.Mistral:
  //       return (reasoning: false, startTag: null, endTag: null);
  //     case ModelFamily.GPT:
  //       return (reasoning: false, startTag: null, endTag: null);
  //     case ModelFamily.Seed:
  //       return (reasoning: true, startTag: '<think>', endTag: "</think>");
  //     case ModelFamily.Other:
  //       return (reasoning: false, startTag: null, endTag: null);
  //   }
  // }

  LlmMetaInfo copyWith({
    String? filePath,
    String? nameInNamingConvention,
    String? version,
    String? sizeLabel,
    String? encoding,
    String? type,
    String? shard,
    int? nCtx,
  }) {
    return LlmMetaInfo(
      filePath: filePath ?? this.filePath,
      nameInNamingConvention:
          nameInNamingConvention ?? this.nameInNamingConvention,
      version: version ?? this.version,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      encoding: encoding ?? this.encoding,
      type: type ?? this.type,
      shard: shard ?? this.shard,
      nCtx: nCtx ?? this.nCtx,
    );
  }

  static LlmMetaInfo empty() {
    return LlmMetaInfo(
      version: '',
      sizeLabel: '',
      encoding: '',
      type: '',
      shard: '',
      filePath: '',
      nameInNamingConvention: '',
      nCtx: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'version': version,
      'sizeLabel': sizeLabel,
      'encoding': encoding,
      'type': type,
      'filePath': filePath,
      'nameInNamingConvention': nameInNamingConvention,
      'shard': shard,
      'nCtx': nCtx,
    };
  }

  factory LlmMetaInfo.fromMap(Map<String, dynamic> map) {
    return LlmMetaInfo(
      version: (map['version'] ?? '') as String,
      sizeLabel: (map['sizeLabel'] ?? '') as String,
      encoding: (map['encoding'] ?? '') as String,
      type: (map['type'] ?? '') as String,
      filePath: (map['filePath'] ?? '') as String,
      nameInNamingConvention: (map['nameInNamingConvention'] ?? '') as String,
      shard: (map['shard'] ?? '') as String,
      nCtx: (map['nCtx'] ?? 0) as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory LlmMetaInfo.fromJson(String source) =>
      LlmMetaInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LlmMetaInfo(filePath: $filePath, nameInNamingConvention: $nameInNamingConvention, version: $version, sizeLabel: $sizeLabel, encoding: $encoding, type: $type, shard: $shard, nCtx: $nCtx)';
  }

  @override
  bool operator ==(covariant LlmMetaInfo other) {
    if (identical(this, other)) return true;

    return other.version == version &&
        other.sizeLabel == sizeLabel &&
        other.encoding == encoding &&
        other.type == type &&
        other.filePath == filePath &&
        other.nameInNamingConvention == nameInNamingConvention &&
        other.shard == shard &&
        other.nCtx == nCtx;
  }

  @override
  int get hashCode {
    return version.hashCode ^
        sizeLabel.hashCode ^
        encoding.hashCode ^
        type.hashCode ^
        filePath.hashCode ^
        nameInNamingConvention.hashCode ^
        shard.hashCode ^
        nCtx.hashCode;
  }
}

@immutable
class LLMProviderVM {
  final ContextParams contextParams;
  final LlamaCppParams lcppParams;
  final LlmMetaInfo info;
  final LlamaCppModelInfo specifications;
  final String uri;
  LLMProviderVM({
    required this.uri,
    required this.contextParams,
    required this.lcppParams,
    required this.info,
    required this.specifications,
  });

  LLMProviderVM copyWith({
    String? uri,
    ContextParams? contextParams,
    LlamaCppParams? lcppParams,
    LlmMetaInfo? info,
    LlamaCppModelInfo? specifications,
  }) {
    return LLMProviderVM(
      uri: uri ?? this.uri,
      contextParams: contextParams ?? this.contextParams,
      lcppParams: lcppParams ?? this.lcppParams,
      info: info ?? this.info,
      specifications: specifications ?? this.specifications,
    );
  }

  static LLMProviderVM getDefaults() {
    return LLMProviderVM(
      uri: '',
      info: LlmMetaInfo.empty(),
      specifications: LlamaCppModelInfo.empty(),
      contextParams: ContextParams.defaultParams(),
      lcppParams: LlamaCppParams.defaultParams(),
    );
  }

  @override
  String toString() {
    return 'LLMProviderVM(uri: $uri, contextParams: $contextParams, lcppParams: $lcppParams, info: $info, specifications: $specifications)';
  }

  @override
  bool operator ==(covariant LLMProviderVM other) {
    if (identical(this, other)) return true;

    return other.uri == uri &&
        other.contextParams == contextParams &&
        other.lcppParams == lcppParams &&
        other.info == info &&
        other.specifications == specifications;
  }

  @override
  int get hashCode {
    return uri.hashCode ^
        contextParams.hashCode ^
        lcppParams.hashCode ^
        info.hashCode ^
        specifications.hashCode;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uri': uri,
      'contextParams': contextParams.toMap(),
      'lcppParams': lcppParams.toMap(),
      'info': info.toMap(),
      'specifications': specifications.toMap(),
    };
  }

  factory LLMProviderVM.fromMap(Map<String, dynamic> map) {
    return LLMProviderVM(
      uri: (map['uri'] ?? '') as String,
      contextParams: ContextParams.fromMap(
        map['contextParams'] as Map<String, dynamic>,
      ),
      lcppParams: LlamaCppParams.fromMap(
        map['lcppParams'] as Map<String, dynamic>,
      ),
      info: LlmMetaInfo.fromMap(map['info'] as Map<String, dynamic>),
      specifications: LlamaCppModelInfo.fromMap(
        map['specifications'] as Map<String, dynamic>,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory LLMProviderVM.fromJson(String source) =>
      LLMProviderVM.fromMap(json.decode(source) as Map<String, dynamic>);
}

@immutable
class UnnuModelDetails {
  final LlmMetaInfo info;
  final LlamaCppModelInfo specifications;
  UnnuModelDetails({
    required this.info,
    required this.specifications,
  });

  static UnnuModelDetails? tryParse(String yaml) {
    final settings = loadYaml(yaml);
    final info = LlmMetaInfo(
      type: (settings['type'] ?? '') as String,
      filePath: (settings['path'] ?? '') as String,
      sizeLabel: (settings['size_label'] ?? '') as String,
      nameInNamingConvention: (settings['name'] ?? '') as String,
      encoding: (settings['quantization_scheme'] ?? '') as String,
      version: (settings['version'] ?? '') as String,
      nCtx: (settings['n_ctx'] ?? 2048) as int,
      shard: (settings['shard'] ?? '') as String,
    );
    final specifications = LlamaCppModelInfo(
      architecture: (settings['architecture'] ?? '') as String,
      quantization_version: (settings['quantization_version'] ?? 0) as int,
      alignment: (settings['alignment'] ?? 0) as int,
      gguf_version: (settings['gguf_version'] ?? 0) as int,
      file_type:
          settings['file_type'] != null ? settings['file_type'] as int : null,
      name:
          settings['model_name'] != null
              ? settings['model_name'] as String
              : null,
      author: settings['author'] != null ? settings['author'] as String : null,
      version:
          settings['model_version'] != null
              ? settings['model_version'] as String
              : null,
      organization:
          settings['organization'] != null
              ? settings['organization'] as String
              : null,
      basename:
          settings['basename'] != null ? settings['basename'] as String : null,
      finetune:
          settings['finetune'] != null ? settings['finetune'] as String : null,
      description:
          settings['description'] != null
              ? settings['description'] as String
              : null,
      size_label:
          settings['size_label'] != null
              ? settings['size_label'] as String
              : null,
      license:
          settings['license'] != null ? settings['license'] as String : null,
      license_link:
          settings['license_link'] != null
              ? settings['license_link'] as String
              : null,
      url: settings['url'] != null ? settings['url'] as String : null,
      doi: settings['doi'] != null ? settings['doi'] as String : null,
      uuid: settings['uuid'] != null ? settings['uuid'] as String : null,
      repo_url:
          settings['repo_url'] != null ? settings['repo_url'] as String : null,
      n_ctx: settings['n_ctx'] != null ? settings['n_ctx'] as int : null,
      n_embd: settings['n_embd'] != null ? settings['n_embd'] as int : null,
      n_layers:
          settings['n_layers'] != null ? settings['n_layers'] as int : null,
      n_ff: settings['n_ff'] != null ? settings['n_ff'] as int : null,
      use_parallel_residual:
          settings['use_parallel_residual'] != null
              ? settings['use_parallel_residual'] as bool
              : null,
      n_experts:
          settings['n_experts'] != null ? settings['n_experts'] as int : null,
      n_experts_used:
          settings['n_experts_used'] != null
              ? settings['n_experts_used'] as int
              : null,
      n_head: settings['n_head'] != null ? settings['n_head'] as int : null,
      attn_head_kv:
          settings['attn_head_kv'] != null
              ? settings['attn_head_kv'] as int
              : null,
      attn_alibi_bias:
          settings['attn_alibi_bias'] != null
              ? settings['attn_alibi_bias'] as double
              : null,
      attn_layer_norm_eps:
          settings['attn_layer_norm_eps'] != null
              ? settings['attn_layer_norm_eps'] as double
              : null,
      attn_layer_norm_rms_eps:
          settings['attn_layer_norm_rms_eps'] != null
              ? settings['attn_layer_norm_rms_eps'] as double
              : null,
      attn_key_len:
          settings['attn_key_len'] != null
              ? settings['attn_key_len'] as int
              : null,
      attn_value_len:
          settings['attn_value_len'] != null
              ? settings['attn_value_len'] as int
              : null,
      rope_dim:
          settings['rope_dim'] != null ? settings['rope_dim'] as int : null,
      rope_freq_base:
          settings['rope_freq_base'] != null
              ? settings['rope_freq_base'] as double
              : null,
      rope_scaling_type:
          settings['rope_scaling_type'] != null
              ? settings['rope_scaling_type'] as String
              : null,
      rope_scaling_factor:
          settings['rope_scaling_factor'] != null
              ? settings['rope_scaling_factor'] as double
              : null,
      rope_orig_ctx:
          settings['rope_orig_ctx'] != null
              ? settings['rope_orig_ctx'] as int
              : null,
      split_count:
          settings['split_count'] != null
              ? settings['split_count'] as int
              : null,
      split_tensor_count:
          settings['split_tensor_count'] != null
              ? settings['split_tensor_count'] as int
              : null,
    );
    return UnnuModelDetails(info: info, specifications: specifications);
  }

  static Future<UnnuModelDetails> trySettings(
    UnnuModelSettings settings,
  ) async {
    final file = File(settings.path);
    if (file.existsSync()) {
      final yaml = await file.readAsString();
      return UnnuModelDetails.tryParse(yaml) ??
          UnnuModelDetails(
            info: LlmMetaInfo.empty(),
            specifications: LlamaCppModelInfo.empty(),
          );
    }
    return UnnuModelDetails(
      info: LlmMetaInfo.empty(),
      specifications: LlamaCppModelInfo.empty(),
    );
  }

  Map<String, dynamic> toYaml() {
    final yaml = <String, dynamic>{
      'path': info.filePath,
      'name': info.nameInNamingConvention,
      'version': info.version,
      'size_label': info.sizeLabel,
      'architecture': specifications.architecture,
      'alignment': specifications.alignment,
      'gguf_version': specifications.gguf_version,
      'quantization_version': specifications.quantization_version,
      'n_ctx': specifications.n_ctx ?? 2048,
      'n_layers': specifications.n_layers ?? 99,
    };
    if (info.type.isNotEmpty) {
      yaml['type'] = info.type;
    }
    if (info.shard.isNotEmpty) {
      yaml['shard'] = info.shard;
    }
    if (info.encoding.isNotEmpty) {
      yaml['quantization_scheme'] = info.encoding;
    }
    if (specifications.file_type != null) {
      yaml['file_type'] = specifications.file_type!;
    }
    if (specifications.name != null) {
      yaml['model_name'] = specifications.name!;
    }
    if (specifications.version != null) {
      yaml['model_version'] = specifications.version!;
    }
    if (specifications.author != null) {
      yaml['author'] = specifications.author!;
    }
    if (specifications.organization != null) {
      yaml['organization'] = specifications.organization!;
    }
    if (specifications.description != null) {
      yaml['description'] = specifications.description!;
    }
    if (specifications.uuid != null) {
      yaml['uuid'] = specifications.uuid!;
    }
    if (specifications.license != null) {
      yaml['license'] = specifications.license!;
    }
    if (specifications.license_link != null) {
      yaml['license_link'] = specifications.license_link!;
    }
    if (specifications.n_embd != null) {
      yaml['n_embd'] = specifications.n_embd!;
    }
    if (specifications.finetune != null) {
      yaml['finetune'] = specifications.finetune!;
    }
    if (specifications.n_ff != null) {
      yaml['n_ff'] = specifications.n_ff!;
    }
    if (specifications.n_head != null) {
      yaml['n_head'] = specifications.n_head!;
    }
    if (specifications.n_experts != null) {
      yaml['n_experts'] = specifications.n_experts!;
    }
    if (specifications.n_experts_used != null) {
      yaml['n_used_experts'] = specifications.n_experts_used!;
    }
    if (specifications.attn_head_kv != null) {
      yaml['attn_head_kv'] = specifications.attn_head_kv!;
    }

    if (specifications.attn_alibi_bias != null) {
      yaml['attn_alibi_bias'] = specifications.attn_alibi_bias!;
    }
    if (specifications.attn_layer_norm_eps != null) {
      yaml['attn_layer_norm_eps'] = specifications.attn_layer_norm_eps!;
    }
    if (specifications.attn_layer_norm_rms_eps != null) {
      yaml['attn_layer_norm_rms_eps'] = specifications.attn_layer_norm_rms_eps!;
    }
    if (specifications.attn_key_len != null) {
      yaml['attn_key_len'] = specifications.attn_key_len!;
    }
    if (specifications.attn_value_len != null) {
      yaml['attn_value_len'] = specifications.attn_value_len!;
    }
    if (specifications.rope_dim != null) {
      yaml['rope_dim'] = specifications.rope_dim!;
    }
    if (specifications.rope_freq_base != null) {
      yaml['rope_freq_base'] = specifications.rope_freq_base!;
    }
    if (specifications.rope_scaling_type != null) {
      yaml['rope_scaling_type'] = specifications.rope_scaling_type!;
    }
    if (specifications.rope_scaling_factor != null) {
      yaml['rope_scaling_factor'] = specifications.rope_scaling_factor!;
    }
    if (specifications.rope_orig_ctx != null) {
      yaml['rope_orig_ctx'] = specifications.rope_orig_ctx!;
    }
    if (specifications.split_count != null) {
      yaml['split_count'] = specifications.split_count!;
    }
    if (specifications.split_tensor_count != null) {
      yaml['split_tensor_count'] = specifications.split_tensor_count!;
    }
    return yaml;
  }

  UnnuModelDetails copyWith({
    LlmMetaInfo? info,
    LlamaCppModelInfo? specifications,
  }) {
    return UnnuModelDetails(
      info: info ?? this.info,
      specifications: specifications ?? this.specifications,
    );
  }

  Map<String, dynamic> toMap() {
    final result =
        <String, dynamic>{}..addAll({
          'info': info.toMap(),
          'specifications': specifications.toMap(),
        });
    return result;
  }

  factory UnnuModelDetails.fromMap(Map<String, dynamic> map) {
    return UnnuModelDetails(
      info: LlmMetaInfo.fromMap(map['info'] as Map<String, dynamic>),
      specifications: LlamaCppModelInfo.fromMap(
        map['specifications'] as Map<String, dynamic>,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory UnnuModelDetails.fromJson(String source) =>
      UnnuModelDetails.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'UnnuModelDetails(info: $info, specifications: $specifications)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UnnuModelDetails &&
        other.info == info &&
        other.specifications == specifications;
  }

  @override
  int get hashCode => info.hashCode ^ specifications.hashCode;
}

typedef ModelFileWithDetails = ({String uri, UnnuModelDetails details});

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

  String currentSettings = '';

  LlamaCppProvider llm = LlamaCppProvider(
    contextParams: ContextParams(),
    lcppParams: const LlamaCppParams(),
  );

  final Map<String, UnnuModelDetails> _modelRegistry =
      <String, UnnuModelDetails>{};

  List<UnnuModelDetails> get models => UnmodifiableListView(
    _modelRegistry.values.where((value) => value.info.filePath.isNotEmpty),
  );

  Stream<LLMResult> get responses => llm.model.responses;

  void stop() {
    llm.model.stop();
  }

  void cancel() {
    llm.model.cancel();
  }

  static UnnuModelDetails inspect(String modelPath) {
    var metaInfo = LlmMetaInfo.empty();
    final info = LlamaCpp.modelInfo(modelPath);

    metaInfo = metaInfo.copyWith(
      filePath: modelPath,
    );

    final segments = p.basename(modelPath).split('-');
    var idxVersion = -1;
    var idxSizeLabel = -1;
    var idxSemVer = -1;
    var idx = 0;
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
        info.version ??
        (idxVersion == -1
            ? idxSemVer != -1
                ? 'v${segments[idxSemVer]}'
                : 'v1.0'
            : segments[idxVersion]);
    final sizeLabel =
        info.size_label ?? (idxSizeLabel == -1 ? '0' : segments[idxSizeLabel]);
    final experts =
        info.n_experts ??
        LlmMetaInfo.countOfExperts(info.size_label ?? sizeLabel);
    final sizeParts = sizeLabel.split('x');
    final szLabel =
        experts > 1
            ? '${experts}x${sizeParts.last.toUpperCase()}'
            : sizeLabel.toUpperCase();
    metaInfo = metaInfo.copyWith(
      sizeLabel: info.size_label ?? szLabel,
      version: versionString,
    );

    for (int i = 0; i < idxSizeLabel; i++) {
      if (!(i == idxVersion || i == idxSemVer)) {
        if (i != 0) {
          toNameConvention.write(' ');
        }
        toNameConvention.write(segments[i]);
      }
    }
    toNameConvention
      ..write('-')
      ..write(szLabel);
    final baseName = (info.basename ?? toNameConvention.toString()).replaceAll(
      '_',
      ' ',
    );
    toNameConvention
      ..clear()
      ..write(baseName);

    final partialName = toNameConvention.toString();

    for (var i = idxSizeLabel + 1; i < segments.length; i++) {
      toNameConvention
        ..clear()
        ..write(partialName);
      for (var j = idxSizeLabel + 1; j < segments.length; j++) {
        if (i == j) {
          if (versionString.isNotEmpty) {
            toNameConvention
              ..write('-')
              ..write(versionString);
          }
        }
        if (!(j == idxVersion || j == idxSemVer)) {
          toNameConvention
            ..write('-')
            ..write(segments[j]);
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
      metaInfo = metaInfo.copyWith(
        nameInNamingConvention: nameInConversation,
      );
    }
    return UnnuModelDetails(info: metaInfo, specifications: info);
  }

  static Future<UnnuModelDetails> load(String path) async {
    File file = File(path);
    if (file.existsSync()) {
      String yaml = await file.readAsString();
      return UnnuModelDetails.tryParse(yaml) ??
          UnnuModelDetails(
            info: LlmMetaInfo.empty(),
            specifications: LlamaCppModelInfo.empty(),
          );
    }
    return UnnuModelDetails(
      info: LlmMetaInfo.empty(),
      specifications: LlamaCppModelInfo.empty(),
    );
  }

  Future<UnnuModelDetails> hydrateModelSettings(
    UnnuModelSettings settings,
  ) async {
    final configurationController = June.getState(
      ConfigurationController.new,
    );
    final uri = Uri.parse(settings.uri);
    final localPath = switch (uri.scheme) {
      'appbundle' =>
        settings.path.isNotEmpty
            ? settings.path
            : Platform.isAndroid || Platform.isIOS
            ? await copyAssetOnMobile(settings.location)
            : await copyAssetFile(settings.location),
      'appstore' => '',
      'playstore' => '',
      'msstore' => '',
      'file' => settings.location,
      'http' => settings.location,
      'https' => settings.location,
      _ => '',
    };

    final details =
        settings.path.isEmpty ? inspect(localPath) : await load(settings.path);
    if (settings.path.isEmpty) {
      final sha = UnnuAux.hashPath(localPath);
      final yaml = details.toYaml();
      yaml['id'] = settings.id;
      yaml['sha'] = sha;

      // Convert jsonValue to YAML
      final yamlEditor = YamlEditor('');
      final jsonString = json.encode(yaml);
      final jsonValue = json.decode(jsonString);
      yamlEditor.update([], jsonValue);
      final llmSettingPath = await ConfigurationController.store(
        uri: Uri.file(
          p.join('models', '${settings.id}.yml'),
          windows: Platform.isWindows,
        ),
        document: loadYamlDocument(yamlEditor.toString()),
      );
      configurationController.config.models[settings.uri] =
          (configurationController.config.models[settings.uri] ?? settings)
              .copyWith(
                path: llmSettingPath,
                sha: UnnuAux.hashPath(llmSettingPath),
              );
    }
    register(details);
    return details;
  }

  void register(UnnuModelDetails details) {
    _modelRegistry[details.info.nameInNamingConvention] = details;
  }

  void unregister(UnnuModelDetails details) {
    _modelRegistry.remove(details.info.nameInNamingConvention);
  }

  void reset() {
    llm.model.reset();
    setState();
  }

  Stream<double> switchModel(UnnuModelDetails details) async* {
    if (kDebugMode) {
      print('switchModel(LlmMetaInfo) info = $details');
    }

    if (kDebugMode) {
      print('activeModel newInfo = $activeModel');
    }
    if (details.info.filePath.isNotEmpty) {
      final machInfo = LlamaCpp.machineInfo();
      final numCtx = details.info.vRamSize(
        details.specifications.n_ctx ?? details.info.nCtx,
      );
      final smallCtx = numCtx.keys.reduce(m.min);
      final largeCtx = numCtx.entries
          .where(
            (element) => element.value <= machInfo.blkmax_vram,
          )
          .map(
            (e) => e.key,
          )
          .reduce(m.max);
      // machInfo.blkmax_vram = 0 implies only iGPU available
      activeModel = activeModel.copyWith(
        info: details.info,
        specifications: details.specifications,
        contextParams: ContextParams.defaultParams().copyWith(
          nCtx: machInfo.blkmax_vram > 0.0 ? largeCtx : smallCtx,
          ropeFrequencyBase: details.specifications.rope_freq_base,
          ropeFrequencyScale: details.specifications.rope_scaling_factor,
          ropeScalingType: RopeScalingType.fromString(
            details.specifications.rope_scaling_type ??
                RopeScalingType.unspecified.name,
          ),
          yarnOriginalContext: details.specifications.rope_orig_ctx,
        ),
        lcppParams: LlamaCppParams.defaultParams().copyWith(
          modelPath: details.info.filePath,
          nGpuLayers:
              (details.specifications.n_layers ?? 97) +
              (details.specifications.n_head ?? 2),
          splitMode:
              numCtx[largeCtx]! >= machInfo.blkmax_vram &&
                      machInfo.blkmax_vram > 0.0
                  ? lcpp_split_mode.LCPP_SPLIT_MODE_LAYER
                  : lcpp_split_mode.LCPP_SPLIT_MODE_NONE,
          mainGPU: 0,
          useMmap: true,
          useMlock: true,
          expertsOffLoad:
              (numCtx[smallCtx]!.toInt() > machInfo.total_vram) &&
              machInfo.blkmax_vram > 0,
        ),
      );
      final reasoning = activeModel.lcppParams.reasoning;
      llm = LlamaCppProvider(
        contextParams: activeModel.contextParams,
        lcppParams: activeModel.lcppParams,
        samplingParams: LlamaCppSamplingParams.defaultParams().copyWith(
          topK: reasoning.reasoning ? 20 : 40,
          topP: 0.95,
          temperature: reasoning.reasoning ? 0.6 : 0.8,
          minP: reasoning.reasoning ? 0.0 : 0.05,
          penaltyPresent: reasoning.reasoning ? 1.5 : 0.8,
        ),
        defaultOptions: LcppOptions(
          model: activeModel.info.nameInNamingConvention,
        ),
      );
      setState();
    }
    final progress = llm.model.reconfigure();
    yield* progress;
  }

  @override
  void dispose() {
    llm.model.destroy();
    super.dispose();
  }

  String get name => activeModel.info.nameInNamingConvention;

  String get modelPath => activeModel.info.filePath;

  String get description => activeModel.info.nameInNamingConvention;

  String get type => llm.modelType;

  // ReasoningContext get reasoningContext => activeModel.info.;
}
