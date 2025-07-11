part of 'package:llamacpp/llamacpp.dart';

Pointer<Pointer<lcpp_common_chat_msg_t>> convertToLcppCommonChatMsg(
  List<cm.ChatMessage> messages,
) {
  var listOfCommonMsgs = List<Pointer<lcpp_common_chat_msg>>.empty(
    growable: true,
  );
  messages.asMap().forEach((idx, msg) {
    switch (msg) {
      case cm.HumanChatMessage():
        final msgPtr = ffi.calloc<lcpp_common_chat_msg>();
        msgPtr.ref.role = 'user'.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_role = 'user'.length;
        final content = msg.content;
        switch (content) {
          case cm.ChatMessageContentText():
            msgPtr.ref.content = content.text.toNativeUtf8().cast<Char>();
            msgPtr.ref.n_content = content.text.length;
            break;
          case cm.ChatMessageContentImage():
            final contentPart = ffi.calloc<lcpp_common_chat_msg_content_part>();
            msgPtr.ref.content_parts = ffi
                .calloc<Pointer<lcpp_common_chat_msg_content_part>>(1);
            if (content.mimeType != null) {
              contentPart.ref.type =
                  content.mimeType!.toNativeUtf8().cast<Char>();
              contentPart.ref.n_type = content.mimeType!.length;
            } else {
              contentPart.ref.type = ''.toNativeUtf8().cast<Char>();
              ;
              contentPart.ref.n_type = 0;
            }
            contentPart.ref.text = content.data.toNativeUtf8().cast<Char>();
            contentPart.ref.n_text = content.data.length;
            msgPtr.ref.content_parts[0] = contentPart;
            msgPtr.ref.n_content_parts = 1;
          case cm.ChatMessageContentMultiModal():
            if (kDebugMode) {
              print('HumanChatMessage::ChatMessageContentMultiModal');
            }
            if (content.parts.isNotEmpty) {
              msgPtr.ref.content_parts = ffi
                  .calloc<Pointer<lcpp_common_chat_msg_content_part>>(
                    content.parts.length,
                  );
              var listOfContentParts =
                  List<Pointer<lcpp_common_chat_msg_content_part>>.empty(
                    growable: true,
                  );
              for (final part in content.parts) {
                switch (part) {
                  case cm.ChatMessageContentText():
                    if (kDebugMode) {
                      print(
                        'ChatMessageContentMultiModal::ChatMessageContentText',
                      );
                    }
                    final contextPart =
                        ffi.calloc<lcpp_common_chat_msg_content_part>();
                    contextPart.ref.text =
                        part.text.toNativeUtf8().cast<Char>();
                    contextPart.ref.n_text = part.text.length;
                    listOfContentParts.add(contextPart);
                  case cm.ChatMessageContentImage():
                    if (kDebugMode) {
                      print(
                        'ChatMessageContentMultiModal::ChatMessageContentImage',
                      );
                    }
                    final contextPart =
                        ffi.calloc<lcpp_common_chat_msg_content_part>();
                    if (part.mimeType != null) {
                      contextPart.ref.type =
                          part.mimeType!.toNativeUtf8().cast<Char>();
                      contextPart.ref.n_type = part.mimeType!.length;
                    } else {
                      contextPart.ref.type = ''.toNativeUtf8().cast<Char>();
                      contextPart.ref.n_type = 0;
                    }
                    contextPart.ref.text =
                        part.data.toNativeUtf8().cast<Char>();
                    contextPart.ref.n_text = part.data.length;
                    listOfContentParts.add(contextPart);

                  case cm.ChatMessageContentMultiModal():
                    // final _context_part = ffi.calloc<lcpp_common_chat_msg_content_part>();
                    // _context_part.ref.type = "".toNativeUtf8().cast<ffi.Char>();
                    // _context_part.ref.n_type = 0;
                    // _context_part.ref.text =
                    //     "".toNativeUtf8().cast<ffi.Char>();
                    // _context_part.ref.n_text = "".length;
                    // _list_content_parts.add(_context_part);
                    break;
                }
              }
              listOfContentParts.asMap().forEach((idx, value) {
                if (kDebugMode) {
                  print('_list_content_parts[$idx]');
                }
                msgPtr.ref.content_parts[idx] = value;
              });
            }
        }
        listOfCommonMsgs.add(msgPtr);
      case cm.AIChatMessage():
        if (kDebugMode) {
          print('AIChatMessage()');
        }
        final msgPtr = ffi.calloc<lcpp_common_chat_msg>();
        msgPtr.ref.role = 'assistant'.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_role = 'assistant'.length;
        msgPtr.ref.content = msg.content.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_content = msg.content.length;
        if (msg.toolCalls.isNotEmpty) {
          msgPtr.ref.tool_calls = ffi
              .calloc<Pointer<lcpp_common_chat_tool_call>>(
                msg.toolCalls.length,
              );
          var listOfToolCalls = List<Pointer<lcpp_common_chat_tool_call>>.empty(
            growable: true,
          );
          for (final part in msg.toolCalls) {
            final toolCall = ffi.calloc<lcpp_common_chat_tool_call>();
            toolCall.ref.name = part.name.toNativeUtf8().cast<Char>();
            toolCall.ref.n_name = part.name.length;
            final json = const JsonEncoder().convert(part.arguments);
            toolCall.ref.arguments = json.toNativeUtf8().cast<Char>();
            toolCall.ref.n_arguments = json.length;
            toolCall.ref.id = part.id.toNativeUtf8().cast<Char>();
            toolCall.ref.n_id = part.id.length;
            listOfToolCalls.add(toolCall);
          }
          listOfToolCalls.asMap().forEach((idx, value) {
            if (kDebugMode) {
              print('_list_tool_calls[$idx]');
            }
            msgPtr.ref.tool_calls[idx] = value;
          });
        }
        listOfCommonMsgs.add(msgPtr);
      case cm.ToolChatMessage():
        if (kDebugMode) {
          print('ToolChatMessage()');
        }
        final msgPtr = ffi.calloc<lcpp_common_chat_msg>();
        msgPtr.ref.role = 'tool'.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_role = 'tool'.length;
        msgPtr.ref.tool_call_id = msg.toolCallId.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_tool_call_id = msg.toolCallId.length;
        msgPtr.ref.content = msg.content.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_content = msg.content.length;
        listOfCommonMsgs.add(msgPtr);
      case cm.SystemChatMessage():
        if (kDebugMode) {
          print('SystemChatMessage()');
        }
        final msgPtr = ffi.calloc<lcpp_common_chat_msg>();
        msgPtr.ref.role = 'system'.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_role = 'system'.length;
        msgPtr.ref.content = msg.content.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_content = msg.content.length;
        listOfCommonMsgs.add(msgPtr);
      case cm.CustomChatMessage():
        if (kDebugMode) {
          print('CustomChatMessage()');
        }
        final msgPtr = ffi.calloc<lcpp_common_chat_msg>();
        msgPtr.ref.role = msg.role.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_role = msg.role.length;
        msgPtr.ref.content = msg.content.toNativeUtf8().cast<Char>();
        msgPtr.ref.n_content = msg.content.length;
        listOfCommonMsgs.add(msgPtr);
    }
  });
  final msgs = ffi.calloc<Pointer<lcpp_common_chat_msg_t>>(messages.length);
  listOfCommonMsgs.asMap().forEach((idx, value) {
    msgs[idx] = value;
  });
  return msgs;
}

extension _PromptValueToLlamaCppChatMessagesExtension on PromptValue {
  Pointer<Pointer<lcpp_common_chat_msg_t>> toNative() {
    final messages = toChatMessages();
    return convertToLcppCommonChatMsg(messages);
  }
}

extension _ChatMessageToLlamaCppChatMessagesExtension on List<cm.ChatMessage> {
  Pointer<Pointer<lcpp_common_chat_msg_t>> toNative() {
    return convertToLcppCommonChatMsg(this);
  }
}

extension _FreeLlamaCppChatMessagesExtension
    on Pointer<Pointer<lcpp_common_chat_msg_t>> {
  void free(int length) {
    for (var i = 0; i < length; i++) {
      final msg = this[i];
      if (msg.ref.content != nullptr) {
        ffi.calloc.free(msg.ref.content);
      }
      if (msg.ref.role != nullptr) {
        ffi.calloc.free(msg.ref.role);
      }
      if (msg.ref.tool_call_id != nullptr) {
        ffi.calloc.free(msg.ref.tool_call_id);
      }
      if (msg.ref.n_content_parts > 0 && msg.ref.content_parts != nullptr) {
        for (var j = 0; j < msg.ref.n_content_parts; j++) {
          final part = msg.ref.content_parts[j];
          if (part.ref.text != nullptr) {
            ffi.calloc.free(part.ref.text);
          }
          if (part.ref.type != nullptr) {
            ffi.calloc.free(part.ref.type);
          }
        }
        ffi.calloc.free(msg.ref.content_parts);
      }
      if (msg.ref.n_tool_calls > 0 && msg.ref.tool_calls != nullptr) {
        for (var j = 0; j < msg.ref.n_tool_calls; j++) {
          final part = msg.ref.tool_calls[j];
          if (part.ref.name != nullptr) {
            ffi.calloc.free(part.ref.name);
          }
          if (part.ref.arguments != nullptr) {
            ffi.calloc.free(part.ref.arguments);
          }
          if (part.ref.id != nullptr) {
            ffi.calloc.free(part.ref.id);
          }
        }
        ffi.calloc.free(msg.ref.tool_calls);
      }
      ffi.calloc.free(msg);
    }
    ffi.calloc.free(this);
  }
}

/// A longer lived native function, which occupies the thread calling it.
///
/// Do not call these kind of native functions in the main isolate. They will
/// block Dart execution. This will cause dropped frames in Flutter applications.
/// Instead, call these native functions on a separate isolate.
///
/// Modify this to suit your own use case. Example use cases:
///
/// 1. Reuse a single isolate for various different kinds of requests.
/// 2. Use multiple helper isolates for parallel execution.
const String _libName = 'llamacpp';

/// The dynamic library in which the symbols for [UnnuCognitiveEnvironmentBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

class LlamaCppModelInfo {
  LlamaCppModelInfo({
    required this.architecture,
    required this.quantization_version,
    required this.alignment,
    required this.gguf_version,
    this.file_type,
    this.name,
    this.author,
    this.version,
    this.organization,
    this.basename,
    this.finetune,
    this.description,
    this.size_label,
    this.license,
    this.license_link,
    this.url,
    this.doi,
    this.uuid,
    this.repo_url,
    this.n_ctx,
    this.n_embd,
    this.n_layers,
    this.n_ff,
    this.use_parallel_residual,
    this.n_experts,
    this.n_experts_used,
    this.n_head,
    this.attn_head_kv,
    this.attn_alibi_bias,
    this.attn_layer_norm_eps,
    this.attn_layer_norm_rms_eps,
    this.attn_key_len,
    this.attn_value_len,
    this.rope_dim,
    this.rope_freq_base,
    this.rope_scaling_type,
    this.rope_scaling_factor,
    this.rope_orig_ctx,
    this.split_count,
    this.split_tensor_count,
  });

  factory LlamaCppModelInfo.fromNative(lcpp_model_info info) {
    return LlamaCppModelInfo(
      architecture:
          info.n_architecture > 0
              ? info.architecture.cast<ffi.Utf8>().toDartString(
                length: info.n_architecture,
              )
              : '',
      alignment: info.alignment,
      gguf_version: info.gguf_version,
      quantization_version: info.quantization_version,
      version:
          info.n_version > 0
              ? info.version.cast<ffi.Utf8>().toDartString(
                length: info.n_version,
              )
              : null,
      file_type: info.file_type != -1 ? info.file_type : null,
      description:
          info.n_description > 0
              ? info.description.cast<ffi.Utf8>().toDartString(
                length: info.n_description,
              )
              : null,
      author:
          info.n_author > 0
              ? info.author.cast<ffi.Utf8>().toDartString(length: info.n_author)
              : null,
      basename:
          info.n_basename > 0
              ? info.basename.cast<ffi.Utf8>().toDartString(
                length: info.n_basename,
              )
              : null,
      doi:
          info.n_doi > 0
              ? info.doi.cast<ffi.Utf8>().toDartString(length: info.n_doi)
              : null,
      finetune:
          info.n_finetune > 0
              ? info.finetune.cast<ffi.Utf8>().toDartString(
                length: info.n_finetune,
              )
              : null,
      license:
          info.n_license > 0
              ? info.license.cast<ffi.Utf8>().toDartString(
                length: info.n_license,
              )
              : null,
      license_link:
          info.n_license_link > 0
              ? info.license_link.cast<ffi.Utf8>().toDartString(
                length: info.n_license_link,
              )
              : null,
      name:
          info.n_name > 0
              ? info.name.cast<ffi.Utf8>().toDartString(length: info.n_name)
              : null,
      organization:
          info.n_organization > 0
              ? info.organization.cast<ffi.Utf8>().toDartString(
                length: info.n_organization,
              )
              : null,
      size_label:
          info.n_size_label > 0
              ? info.size_label.cast<ffi.Utf8>().toDartString(
                length: info.n_size_label,
              )
              : null,
      url:
          info.n_url > 0
              ? info.url.cast<ffi.Utf8>().toDartString(length: info.n_url)
              : null,
      uuid:
          info.n_uuid > 0
              ? info.uuid.cast<ffi.Utf8>().toDartString(length: info.n_uuid)
              : null,
      repo_url:
          info.n_repo_url > 0
              ? info.repo_url.cast<ffi.Utf8>().toDartString(
                length: info.n_repo_url,
              )
              : null,
      use_parallel_residual: info.use_parallel_residual > 0,
      n_ctx: info.context_length > 0 ? info.context_length : null,
      n_layers: info.block_count > 0 ? info.block_count : null,
      n_embd: info.embedding_length > 0 ? info.embedding_length : null,
      n_experts: info.expert_count > 0 ? info.expert_count : null,
      n_experts_used:
          info.expert_used_count > 0 ? info.expert_used_count : null,
      n_ff: info.feed_forward_length > 0 ? info.feed_forward_length : null,

      n_head: info.attention_head_count > 0 ? info.attention_head_count : null,
      attn_head_kv:
          info.attention_head_count_kv > 0
              ? info.attention_head_count_kv
              : null,
      attn_alibi_bias:
          info.attention_max_alibi_bias > 0
              ? info.attention_max_alibi_bias
              : null,
      attn_layer_norm_eps:
          info.attention_layer_norm_epsilon > 0
              ? info.attention_layer_norm_epsilon
              : null,
      attn_layer_norm_rms_eps:
          info.attention_layer_norm_rms_epsilon > 0
              ? info.attention_layer_norm_rms_epsilon
              : null,
      attn_key_len:
          info.attention_key_length > 0 ? info.attention_key_length : null,
      attn_value_len:
          info.attention_value_length > 0 ? info.attention_value_length : null,
      rope_dim:
          info.rope_dimension_count > 0 ? info.rope_dimension_count : null,
      rope_freq_base: info.rope_freq_base > 0 ? info.rope_freq_base : null,
      rope_scaling_factor:
          info.rope_scaling_factor > 0 ? info.rope_scaling_factor : null,
      rope_scaling_type:
          info.n_rope_scaling_type > 0
              ? info.rope_scaling_type.cast<ffi.Utf8>().toDartString(
                length: info.n_rope_scaling_type,
              )
              : null,
      rope_orig_ctx:
          info.rope_original_context_length > 0
              ? info.rope_original_context_length
              : null,
      split_count: info.split_count > 0 ? info.split_count : null,
      split_tensor_count:
          info.split_tensor_count > 0 ? info.split_tensor_count : null,
    );
  }

  factory LlamaCppModelInfo.fromMap(Map<String, dynamic> map) {
    return LlamaCppModelInfo(
      architecture: (map['architecture'] ?? '') as String,
      quantization_version: (map['quantization_version'] ?? 0) as int,
      alignment: (map['alignment'] ?? 0) as int,
      gguf_version: (map['gguf_version'] ?? 0) as int,
      file_type: (map['file_type'] ?? 0) as int,
      name: map['name'] != null ? map['name'] as String : null,
      author: map['author'] != null ? map['author'] as String : null,
      version: map['version'] != null ? map['version'] as String : null,
      organization:
          map['organization'] != null ? map['organization'] as String : null,
      basename: map['basename'] != null ? map['basename'] as String : null,
      finetune: map['finetune'] != null ? map['finetune'] as String : null,
      description:
          map['description'] != null ? map['description'] as String : null,
      size_label:
          map['size_label'] != null ? map['size_label'] as String : null,
      license: map['license'] != null ? map['license'] as String : null,
      license_link:
          map['license_link'] != null ? map['license_link'] as String : null,
      url: map['url'] != null ? map['url'] as String : null,
      doi: map['doi'] != null ? map['doi'] as String : null,
      uuid: map['uuid'] != null ? map['uuid'] as String : null,
      repo_url: map['repo_url'] != null ? map['repo_url'] as String : null,
      n_ctx: map['n_ctx'] != null ? map['n_ctx'] as int : null,
      n_embd: map['n_embd'] != null ? map['n_embd'] as int : null,
      n_layers: map['n_layers'] != null ? map['n_layers'] as int : null,
      n_ff: map['n_ff'] != null ? map['n_ff'] as int : null,
      use_parallel_residual:
          map['use_parallel_residual'] != null
              ? map['use_parallel_residual'] as bool
              : null,
      n_experts: map['n_experts'] != null ? map['n_experts'] as int : null,
      n_experts_used:
          map['n_experts_used'] != null ? map['n_experts_used'] as int : null,
      n_head: map['n_head'] != null ? map['n_head'] as int : null,
      attn_head_kv:
          map['attn_head_kv'] != null ? map['attn_head_kv'] as int : null,
      attn_alibi_bias:
          map['attn_alibi_bias'] != null
              ? map['attn_alibi_bias'] as double
              : null,
      attn_layer_norm_eps:
          map['attn_layer_norm_eps'] != null
              ? map['attn_layer_norm_eps'] as double
              : null,
      attn_layer_norm_rms_eps:
          map['attn_layer_norm_rms_eps'] != null
              ? map['attn_layer_norm_rms_eps'] as double
              : null,
      attn_key_len:
          map['attn_key_len'] != null ? map['attn_key_len'] as int : null,
      attn_value_len:
          map['attn_value_len'] != null ? map['attn_value_len'] as int : null,
      rope_dim: map['rope_dim'] != null ? map['rope_dim'] as int : null,
      rope_freq_base:
          map['rope_freq_base'] != null
              ? map['rope_freq_base'] as double
              : null,
      rope_scaling_type:
          map['rope_scaling_type'] != null
              ? map['rope_scaling_type'] as String
              : null,
      rope_scaling_factor:
          map['rope_scaling_factor'] != null
              ? map['rope_scaling_factor'] as double
              : null,
      rope_orig_ctx:
          map['rope_orig_ctx'] != null ? map['rope_orig_ctx'] as int : null,
      split_count:
          map['split_count'] != null ? map['split_count'] as int : null,
      split_tensor_count:
          map['split_tensor_count'] != null
              ? map['split_tensor_count'] as int
              : null,
    );
  }

  factory LlamaCppModelInfo.fromJson(String source) =>
      LlamaCppModelInfo.fromMap(json.decode(source) as Map<String, dynamic>);
  // required
  String architecture;
  int quantization_version;
  int alignment;
  int gguf_version;

  int? file_type;
  // metadata
  String? name;
  String? author;
  String? version;
  String? organization;
  String? basename;
  String? finetune;
  String? description;
  String? size_label;
  String? license;
  String? license_link;
  String? url;
  String? doi;
  String? uuid;
  String? repo_url;

  // LLM
  int? n_ctx; // n_ctx
  int? n_embd; // n_embd
  int? n_layers; // n_gpu_layers
  int? n_ff; // n_ff
  bool? use_parallel_residual;
  int? n_experts;
  int? n_experts_used;

  // Attention
  int? n_head; //n_head

  int? attn_head_kv; // d_head
  double? attn_alibi_bias;
  double? attn_layer_norm_eps;
  double? attn_layer_norm_rms_eps;
  int? attn_key_len; // d_k
  int? attn_value_len; // d_v

  // ROPE
  int? rope_dim;
  double? rope_freq_base;
  //Scaling
  String? rope_scaling_type;
  double? rope_scaling_factor;
  int? rope_orig_ctx;
  // Split
  int? split_count;
  int? split_tensor_count;

  static LlamaCppModelInfo empty() {
    return LlamaCppModelInfo(
      architecture: '',
      gguf_version: 0,
      quantization_version: 0,
      alignment: 0,
      file_type: 0,
      version: null,
      name: null,
      author: null,
      basename: null,
      size_label: null,
      description: null,
      doi: null,
      uuid: null,
      license: null,
      license_link: null,
      organization: null,
      repo_url: null,
      url: null,
      finetune: null,
      n_ctx: null,
      n_embd: null,
      n_ff: null,
      n_layers: null,
      n_head: null,
      n_experts: null,
      n_experts_used: null,
      use_parallel_residual: null,
      attn_head_kv: null,
      attn_alibi_bias: null,
      attn_layer_norm_rms_eps: null,
      attn_layer_norm_eps: null,
      attn_key_len: null,
      attn_value_len: null,
      rope_dim: null,
      rope_freq_base: null,
      rope_scaling_factor: null,
      rope_scaling_type: null,
      rope_orig_ctx: null,
      split_count: null,
      split_tensor_count: null,
    );
  }

  LlamaCppModelInfo copyWith({
    String? architecture,
    int? quantization_version,
    int? alignment,
    int? gguf_version,
    int? file_type,
    String? name,
    String? author,
    String? version,
    String? organization,
    String? basename,
    String? finetune,
    String? description,
    String? size_label,
    String? license,
    String? license_link,
    String? url,
    String? doi,
    String? uuid,
    String? repo_url,
    int? n_ctx,
    int? n_embd,
    int? n_layers,
    int? n_ff,
    bool? use_parallel_residual,
    int? n_experts,
    int? n_experts_used,
    int? n_head,
    int? attn_head_kv,
    double? attn_alibi_bias,
    double? attn_layer_norm_eps,
    double? attn_layer_norm_rms_eps,
    int? attn_key_len,
    int? attn_value_len,
    int? rope_dim,
    double? rope_freq_base,
    String? rope_scaling_type,
    double? rope_scaling_factor,
    int? rope_orig_ctx,
    int? split_count,
    int? split_tensor_count,
  }) {
    return LlamaCppModelInfo(
      architecture: architecture ?? this.architecture,
      quantization_version: quantization_version ?? this.quantization_version,
      alignment: alignment ?? this.alignment,
      gguf_version: gguf_version ?? this.gguf_version,
      file_type: file_type ?? this.file_type,
      name: name ?? this.name,
      author: author ?? this.author,
      version: version ?? this.version,
      organization: organization ?? this.organization,
      basename: basename ?? this.basename,
      finetune: finetune ?? this.finetune,
      description: description ?? this.description,
      size_label: size_label ?? this.size_label,
      license: license ?? this.license,
      license_link: license_link ?? this.license_link,
      url: url ?? this.url,
      doi: doi ?? this.doi,
      uuid: uuid ?? this.uuid,
      repo_url: repo_url ?? this.repo_url,
      n_ctx: n_ctx ?? this.n_ctx,
      n_embd: n_embd ?? this.n_embd,
      n_layers: n_layers ?? this.n_layers,
      n_ff: n_ff ?? this.n_ff,
      use_parallel_residual:
          use_parallel_residual ?? this.use_parallel_residual,
      n_experts: n_experts ?? this.n_experts,
      n_experts_used: n_experts_used ?? this.n_experts_used,
      n_head: n_head ?? this.n_head,
      attn_head_kv: attn_head_kv ?? this.attn_head_kv,
      attn_alibi_bias: attn_alibi_bias ?? this.attn_alibi_bias,
      attn_layer_norm_eps: attn_layer_norm_eps ?? this.attn_layer_norm_eps,
      attn_layer_norm_rms_eps:
          attn_layer_norm_rms_eps ?? this.attn_layer_norm_rms_eps,
      attn_key_len: attn_key_len ?? this.attn_key_len,
      attn_value_len: attn_value_len ?? this.attn_value_len,
      rope_dim: rope_dim ?? this.rope_dim,
      rope_freq_base: rope_freq_base ?? this.rope_freq_base,
      rope_scaling_type: rope_scaling_type ?? this.rope_scaling_type,
      rope_scaling_factor: rope_scaling_factor ?? this.rope_scaling_factor,
      rope_orig_ctx: rope_orig_ctx ?? this.rope_orig_ctx,
      split_count: split_count ?? this.split_count,
      split_tensor_count: split_tensor_count ?? this.split_tensor_count,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    result.addAll({'architecture': architecture});
    result.addAll({'quantization_version': quantization_version});
    result.addAll({'alignment': alignment});
    result.addAll({'gguf_version': gguf_version});
    if (file_type != null) {
      result.addAll({'file_type': file_type});
    }
    if (name != null) {
      result.addAll({'name': name});
    }
    if (author != null) {
      result.addAll({'author': author});
    }
    if (version != null) {
      result.addAll({'version': version});
    }
    if (organization != null) {
      result.addAll({'organization': organization});
    }
    if (basename != null) {
      result.addAll({'basename': basename});
    }
    if (finetune != null) {
      result.addAll({'finetune': finetune});
    }
    if (description != null) {
      result.addAll({'description': description});
    }
    if (size_label != null) {
      result.addAll({'size_label': size_label});
    }
    if (license != null) {
      result.addAll({'license': license});
    }
    if (license_link != null) {
      result.addAll({'license_link': license_link});
    }
    if (url != null) {
      result.addAll({'url': url});
    }
    if (doi != null) {
      result.addAll({'doi': doi});
    }
    if (uuid != null) {
      result.addAll({'uuid': uuid});
    }
    if (repo_url != null) {
      result.addAll({'repo_url': repo_url});
    }
    if (n_ctx != null) {
      result.addAll({'n_ctx': n_ctx});
    }
    if (n_embd != null) {
      result.addAll({'n_embd': n_embd});
    }
    if (n_layers != null) {
      result.addAll({'n_layers': n_layers});
    }
    if (n_ff != null) {
      result.addAll({'n_ff': n_ff});
    }
    if (use_parallel_residual != null) {
      result.addAll({'use_parallel_residual': use_parallel_residual});
    }
    if (n_experts != null) {
      result.addAll({'n_experts': n_experts});
    }
    if (n_experts_used != null) {
      result.addAll({'n_experts_used': n_experts_used});
    }
    if (n_head != null) {
      result.addAll({'n_head': n_head});
    }
    if (attn_head_kv != null) {
      result.addAll({'attn_head_kv': attn_head_kv});
    }
    if (attn_alibi_bias != null) {
      result.addAll({'attn_alibi_bias': attn_alibi_bias});
    }
    if (attn_layer_norm_eps != null) {
      result.addAll({'attn_layer_norm_eps': attn_layer_norm_eps});
    }
    if (attn_layer_norm_rms_eps != null) {
      result.addAll({'attn_layer_norm_rms_eps': attn_layer_norm_rms_eps});
    }
    if (attn_key_len != null) {
      result.addAll({'attn_key_len': attn_key_len});
    }
    if (attn_value_len != null) {
      result.addAll({'attn_value_len': attn_value_len});
    }
    if (rope_dim != null) {
      result.addAll({'rope_dim': rope_dim});
    }
    if (rope_freq_base != null) {
      result.addAll({'rope_freq_base': rope_freq_base});
    }
    if (rope_scaling_type != null) {
      result.addAll({'rope_scaling_type': rope_scaling_type});
    }
    if (rope_scaling_factor != null) {
      result.addAll({'rope_scaling_factor': rope_scaling_factor});
    }
    if (rope_orig_ctx != null) {
      result.addAll({'rope_orig_ctx': rope_orig_ctx});
    }
    if (split_count != null) {
      result.addAll({'split_count': split_count});
    }
    if (split_tensor_count != null) {
      result.addAll({'split_tensor_count': split_tensor_count});
    }

    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LlamaCppModelInfo &&
        other.architecture == architecture &&
        other.quantization_version == quantization_version &&
        other.alignment == alignment &&
        other.gguf_version == gguf_version &&
        other.file_type == file_type &&
        other.name == name &&
        other.author == author &&
        other.version == version &&
        other.organization == organization &&
        other.basename == basename &&
        other.finetune == finetune &&
        other.description == description &&
        other.size_label == size_label &&
        other.license == license &&
        other.license_link == license_link &&
        other.url == url &&
        other.doi == doi &&
        other.uuid == uuid &&
        other.repo_url == repo_url &&
        other.n_ctx == n_ctx &&
        other.n_embd == n_embd &&
        other.n_layers == n_layers &&
        other.n_ff == n_ff &&
        other.use_parallel_residual == use_parallel_residual &&
        other.n_experts == n_experts &&
        other.n_experts_used == n_experts_used &&
        other.n_head == n_head &&
        other.attn_head_kv == attn_head_kv &&
        other.attn_alibi_bias == attn_alibi_bias &&
        other.attn_layer_norm_eps == attn_layer_norm_eps &&
        other.attn_layer_norm_rms_eps == attn_layer_norm_rms_eps &&
        other.attn_key_len == attn_key_len &&
        other.attn_value_len == attn_value_len &&
        other.rope_dim == rope_dim &&
        other.rope_freq_base == rope_freq_base &&
        other.rope_scaling_type == rope_scaling_type &&
        other.rope_scaling_factor == rope_scaling_factor &&
        other.rope_orig_ctx == rope_orig_ctx &&
        other.split_count == split_count &&
        other.split_tensor_count == split_tensor_count;
  }

  @override
  int get hashCode {
    return architecture.hashCode ^
        quantization_version.hashCode ^
        alignment.hashCode ^
        gguf_version.hashCode ^
        file_type.hashCode ^
        name.hashCode ^
        author.hashCode ^
        version.hashCode ^
        organization.hashCode ^
        basename.hashCode ^
        finetune.hashCode ^
        description.hashCode ^
        size_label.hashCode ^
        license.hashCode ^
        license_link.hashCode ^
        url.hashCode ^
        doi.hashCode ^
        uuid.hashCode ^
        repo_url.hashCode ^
        n_ctx.hashCode ^
        n_embd.hashCode ^
        n_layers.hashCode ^
        n_ff.hashCode ^
        use_parallel_residual.hashCode ^
        n_experts.hashCode ^
        n_experts_used.hashCode ^
        n_head.hashCode ^
        attn_head_kv.hashCode ^
        attn_alibi_bias.hashCode ^
        attn_layer_norm_eps.hashCode ^
        attn_layer_norm_rms_eps.hashCode ^
        attn_key_len.hashCode ^
        attn_value_len.hashCode ^
        rope_dim.hashCode ^
        rope_freq_base.hashCode ^
        rope_scaling_type.hashCode ^
        rope_scaling_factor.hashCode ^
        rope_orig_ctx.hashCode ^
        split_count.hashCode ^
        split_tensor_count.hashCode;
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'LlamaCppModelInfo(architecture: $architecture, quantization_version: $quantization_version, alignment: $alignment, gguf_version: $gguf_version, file_type: $file_type, name: $name, author: $author, version: $version, organization: $organization, basename: $basename, finetune: $finetune, description: $description, size_label: $size_label, license: $license, license_link: $license_link, url: $url, doi: $doi, uuid: $uuid, repo_url: $repo_url, n_ctx: $n_ctx, n_embd: $n_embd, n_layers: $n_layers, n_ff: $n_ff, use_parallel_residual: $use_parallel_residual, n_experts: $n_experts, n_experts_used: $n_experts_used, n_head: $n_head, attn_head_kv: $attn_head_kv, attn_alibi_bias: $attn_alibi_bias, attn_layer_norm_eps: $attn_layer_norm_eps, attn_layer_rms_eps: $attn_layer_norm_rms_eps, attn_key_len: $attn_key_len, attn_value_len: $attn_value_len, rope_dimension_count: $rope_dim, rope_freq_base: $rope_freq_base, rope_scaling_type: $rope_scaling_type, rope_scaling_factor: $rope_scaling_factor, rope_orig_ctx: $rope_orig_ctx, split_count: $split_count, split_tensor_count: $split_tensor_count)';
  }
}

enum LlamaCppEndianness {
  UNSPECIFIED,
  BIG,
  LITTLE,
  UNKNOWN,
}

class LlamaCppGpuInfo {
  String vendor;
  String device_name;
  int memory;
  int frequency;
  LlamaCppGpuInfo({
    required this.vendor,
    required this.device_name,
    required this.memory,
    required this.frequency,
  });

  LlamaCppGpuInfo copyWith({
    String? vendor,
    String? device_name,
    int? memory,
    int? frequency,
  }) {
    return LlamaCppGpuInfo(
      vendor: vendor ?? this.vendor,
      device_name: device_name ?? this.device_name,
      memory: memory ?? this.memory,
      frequency: frequency ?? this.frequency,
    );
  }

  @override
  String toString() {
    return 'LlamaCppGpuInfo(vendor: $vendor, device_name: $device_name, memory: $memory, frequency: $frequency)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LlamaCppGpuInfo &&
        other.vendor == vendor &&
        other.device_name == device_name &&
        other.memory == memory &&
        other.frequency == frequency;
  }

  @override
  int get hashCode {
    return vendor.hashCode ^
        device_name.hashCode ^
        memory.hashCode ^
        frequency.hashCode;
  }
}

class LlamaCppMachineInfo {
  String os_name;
  String os_version;
  String full_name;

  String vendor_id;
  String processor_name;
  String chipset_vendor;
  String micro_arch;
  LlamaCppEndianness endianess;
  int frequency;
  int num_cores;
  int num_processors;
  int num_clusters;

  int physical_mem;
  int virtual_mem;

  int total_vram;
  int blkmax_vram;

  List<LlamaCppGpuInfo> gpus;
  LlamaCppMachineInfo({
    required this.os_name,
    required this.os_version,
    required this.full_name,
    required this.vendor_id,
    required this.processor_name,
    required this.chipset_vendor,
    required this.micro_arch,
    required this.endianess,
    required this.frequency,
    required this.num_cores,
    required this.num_processors,
    required this.num_clusters,
    required this.physical_mem,
    required this.virtual_mem,
    required this.total_vram,
    required this.blkmax_vram,
    required this.gpus,
  });

  @override
  String toString() {
    return 'LlamaCppMachineInfo(os_name: $os_name, os_version: $os_version, full_name: $full_name, vendor_id: $vendor_id, processor_name: $processor_name, chipset_vendor: $chipset_vendor, microarchitecture: $micro_arch, endianess: $endianess, frequency: $frequency, num_cores: $num_cores, num_processors: $num_processors, num_clusters: $num_clusters, physical_mem: $physical_mem, virtual_mem: $virtual_mem, total_vram: $total_vram, blkmax_vram: $blkmax_vram, gpus: $gpus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is LlamaCppMachineInfo &&
        other.os_name == os_name &&
        other.os_version == os_version &&
        other.full_name == full_name &&
        other.vendor_id == vendor_id &&
        other.processor_name == processor_name &&
        other.chipset_vendor == chipset_vendor &&
        other.micro_arch == micro_arch &&
        other.endianess == endianess &&
        other.frequency == frequency &&
        other.num_cores == num_cores &&
        other.num_processors == num_processors &&
        other.num_clusters == num_clusters &&
        other.physical_mem == physical_mem &&
        other.virtual_mem == virtual_mem &&
        other.total_vram == total_vram &&
        other.blkmax_vram == blkmax_vram &&
        listEquals(other.gpus, gpus);
  }

  @override
  int get hashCode {
    return os_name.hashCode ^
        os_version.hashCode ^
        full_name.hashCode ^
        vendor_id.hashCode ^
        processor_name.hashCode ^
        chipset_vendor.hashCode ^
        micro_arch.hashCode ^
        endianess.hashCode ^
        frequency.hashCode ^
        num_cores.hashCode ^
        num_processors.hashCode ^
        num_clusters.hashCode ^
        physical_mem.hashCode ^
        virtual_mem.hashCode ^
        total_vram.hashCode ^
        blkmax_vram.hashCode ^
        gpus.hashCode;
  }
}

/// A class that implements the Llama interface and provides functionality
/// for loading and interacting with a Llama model, context, and sampler.
///
/// The class initializes the model, context, and sampler based on the provided
/// parameters and allows for prompting the model with chat messages.
///
/// The class also provides methods to stop the current operation and free
/// the allocated resources.
///
/// Example usage:
/// ```dart
/// final lcpp = Lcpp(
///   modelParams: ModelParams(...),
///   contextParams: ContextParams(...),
///   lcppParams: LcppParams(...)
/// );
///
/// final responseStream = prompt([...]);
/// responseStream.listen((response) {
///   print(response);
/// });
/// ```
///
/// Properties:
/// - `modelParams`: Sets the model parameters and initializes the model.
/// - `contextParams`: Sets the context parameters and initializes the context.
/// - `lcppParams`: Sets the common params.
///
/// Methods:
/// - `prompt(List<ChatMessage> messages, {bool streaming = true})`: Prompts the model with the given chat messages and returns a stream of responses.
/// - `stop()`: Stops the current operation.
/// - `free()`: Frees the allocated resources.
class LlamaCpp {
  /// A class that initializes and manages a native Llama model.
  ///
  /// The [LlamaCpp] constructor requires [ModelParams] and optionally accepts
  /// [ContextParams] and [LlamaCppParams]. It initializes the model by loading
  /// the necessary backends and calling the `_initModel` method.
  ///
  /// Example usage:
  /// ```dart
  /// final llamaNative = LlamaNative(
  ///   modelParams: ModelParams(...),
  ///   contextParams: ContextParams(...),
  ///   samplingParams: SamplingParams(...),
  /// );
  /// ```
  ///
  /// Parameters:
  /// - [contextParams]: Optional parameters for the context configuration. Defaults to an empty [ContextParams] object.
  /// - [lcppParams]: Optional parameters for the sampling configuration. Defaults to an empty [LlamaCppParams] object.
  LlamaCpp({
    ContextParams? contextParams,
    LlamaCppParams lcppParams = const LlamaCppParams(),
  }) : _contextParams = contextParams ?? ContextParams(),
       _lcppParams = lcppParams {
    init();
  }
  // static final  LlamaCppBindings llamacpp =  LlamaCppBindings(_lib ??= _dylib);

  static DynamicLibrary? _lib;

  static void init() {
    _lib ??= _dylib;
  }

  static DynamicLibrary get lib {
    init();
    return _lib!;
  }

  ContextParams _contextParams;
  LlamaCppParams _lcppParams;

  set contextParams(ContextParams contextParams) {
    _contextParams = contextParams;
  }

  set lcppParams(LlamaCppParams lcppParams) {
    _lcppParams = lcppParams;
  }

  final StreamController<LLMResult> _responseController =
      StreamController.broadcast(
        sync: false,
      );

  Stream<LLMResult> get responses => _responseController.stream;

  static LlamaCppModelInfo modelInfo(String gguf) {
    final model_path = gguf.toNativeUtf8().cast<Char>();
    final lcpp_model_info = lcpp_get_model_info(model_path);
    final info = LlamaCppModelInfo.fromNative(lcpp_model_info.ref);
    lcpp_free_model_info(lcpp_model_info);
    return info;
  }

  static LlamaCppMachineInfo machineInfo() {
    final lcpp_mach_info = lcpp_get_machine_info();

    final blkmax_vram = lcpp_mach_info.ref.blkmax_vram;
    final total_vram = lcpp_mach_info.ref.total_vram;
    final sysInfoPtr = lcpp_mach_info.ref.sysinfo;
    final system_full_name =
        sysInfoPtr.ref.n_full_name > 0
            ? sysInfoPtr.ref.full_name.cast<ffi.Utf8>().toDartString(
              length: sysInfoPtr.ref.n_full_name,
            )
            : '';
    final os_name =
        sysInfoPtr.ref.n_os_name > 0
            ? sysInfoPtr.ref.os_name.cast<ffi.Utf8>().toDartString(
              length: sysInfoPtr.ref.n_os_name,
            )
            : '';

    final os_version =
        sysInfoPtr.ref.n_os_version > 0
            ? sysInfoPtr.ref.os_version.cast<ffi.Utf8>().toDartString(
              length: sysInfoPtr.ref.n_os_version,
            )
            : '';

    final cpuInfoPtr = lcpp_mach_info.ref.cpuinfo;
    final endianness = switch (cpuInfoPtr.ref.endianess) {
      lcpp_cpu_endianess.LCPP_CPU_ENDIANESS_UNSPECIFIED =>
        LlamaCppEndianness.UNSPECIFIED,
      lcpp_cpu_endianess.LCPP_CPU_ENDIANESS_BIG => LlamaCppEndianness.BIG,
      lcpp_cpu_endianess.LCPP_CPU_ENDIANESS_LITTLE => LlamaCppEndianness.LITTLE,
      lcpp_cpu_endianess.LCPP_CPU_ENDIANESS_UNKNOWN =>
        LlamaCppEndianness.UNKNOWN,
    };

    final processor_name =
        cpuInfoPtr.ref.n_processor_name > 0
            ? cpuInfoPtr.ref.processor_name.cast<ffi.Utf8>().toDartString(
              length: cpuInfoPtr.ref.n_processor_name,
            )
            : '';

    final chipset_vendor =
        cpuInfoPtr.ref.n_chipset_vendor > 0
            ? cpuInfoPtr.ref.chipset_vendor.cast<ffi.Utf8>().toDartString(
              length: cpuInfoPtr.ref.n_chipset_vendor,
            )
            : '';

    final vendor_id =
        cpuInfoPtr.ref.n_vendor_id > 0
            ? cpuInfoPtr.ref.vendor_id.cast<ffi.Utf8>().toDartString(
              length: cpuInfoPtr.ref.n_vendor_id,
            )
            : '';

    final uarch =
        cpuInfoPtr.ref.n_uarch > 0
            ? cpuInfoPtr.ref.uarch.cast<ffi.Utf8>().toDartString(
              length: cpuInfoPtr.ref.n_uarch,
            )
            : '';

    final num_processors = cpuInfoPtr.ref.num_processors;
    final num_cores = cpuInfoPtr.ref.num_cores;
    final num_clusters = cpuInfoPtr.ref.num_clusters;
    final freq = cpuInfoPtr.ref.frequency;

    final memInfoPtr = lcpp_mach_info.ref.meminfo;

    final phys_mem = memInfoPtr.ref.physical_mem;
    final virt_mem = memInfoPtr.ref.virtual_mem;
    final n_gpu = lcpp_mach_info.ref.n_gpuinfo;

    final gpus = <LlamaCppGpuInfo>[];
    final gpu_infos = lcpp_mach_info.ref.gpuinfo;
    for (int i = 0; i < n_gpu; i++) {
      final g_freq = gpu_infos[i].ref.frequency;
      final g_mem = gpu_infos[i].ref.memory;
      final gpu_vendor =
          gpu_infos[i].ref.n_vendor > 0
              ? gpu_infos[i].ref.vendor.cast<ffi.Utf8>().toDartString(
                length: gpu_infos[i].ref.n_vendor,
              )
              : '';
      final gpu_name =
          gpu_infos[i].ref.n_device_name > 0
              ? gpu_infos[i].ref.device_name.cast<ffi.Utf8>().toDartString(
                length: gpu_infos[i].ref.n_device_name,
              )
              : '';
      gpus.add(
        LlamaCppGpuInfo(
          vendor: gpu_vendor,
          device_name: gpu_name,
          memory: g_mem,
          frequency: g_freq,
        ),
      );
    }
    final info = LlamaCppMachineInfo(
      os_name: os_name,
      os_version: os_version,
      full_name: system_full_name,
      vendor_id: vendor_id,
      processor_name: processor_name,
      chipset_vendor: chipset_vendor,
      micro_arch: uarch,
      endianess: endianness,
      frequency: freq,
      num_cores: num_cores,
      num_processors: num_processors,
      num_clusters: num_clusters,
      physical_mem: phys_mem,
      virtual_mem: virt_mem,
      total_vram: total_vram,
      blkmax_vram: blkmax_vram,
      gpus: gpus,
    );

    lcpp_free_machine_info(lcpp_mach_info);
    return info;
  }

  Stream<double> reconfigure() async* {
    final contextParams = _contextParams.toNative();
    final lcppParams = _lcppParams.toNative();
    final completer = Completer();

    NativeCallable<LppProgressCallbackFunction>? nativeProgressCallable;

    final responseStreamController = StreamController<double>.broadcast(
      onListen: () {
        lcpp_reconfigure(contextParams, lcppParams);
      },
      onCancel: () {
        if (nativeProgressCallable != null) {
          nativeProgressCallable!.close();
          lcpp_unset_model_load_progress_callback();
          nativeProgressCallable = null;
        }
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );

    void onProgressCallback(Pointer<LcppFloatStruct_t> response) {
      try {
        final progress = response.ref.value;
        responseStreamController.add(progress);
        if (progress >= 1.0 || progress < 0.0) {
          if (!responseStreamController.isClosed) {
            responseStreamController.close();
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        }
      } finally {
        lcpp_free_float(response);
      }
    }

    nativeProgressCallable =
        NativeCallable<LppProgressCallbackFunction>.listener(
          onProgressCallback,
        );

    lcpp_set_model_load_progress_callback(
      nativeProgressCallable!.nativeFunction,
    );
    yield* responseStreamController.stream;

    if (completer.isCompleted) {
      if (!responseStreamController.isClosed) {
        await responseStreamController.close();
      }
    }
  }

  Stream<LLMResult> prompt(
    LlamaCppSamplingParams params,
    PromptValue messages, {
    bool streaming = true,
  }) async* {
    final chatMessages = messages.toChatMessages();
    final commonChatMessages = chatMessages.toNative();
    final idPrefix = DateTime.now().millisecondsSinceEpoch.toString();
    int tokenCount = 0;

    NativeCallable<LppTokenStreamCallbackFunction>? nativeNewTokenCallable;

    final responseStreamController =
        StreamController<LLMResult>.broadcast(
          onCancel: () {
            if (streaming) {
              if (nativeNewTokenCallable != null) {
                nativeNewTokenCallable!.close();
                lcpp_unset_token_stream_callback();
                nativeNewTokenCallable = null;
              }
            }
          },
          sync: true,
        );

    void onNewTokenCallback(Pointer<LcppTextStruct_t> response) {
      try {
        if (streaming) {
          final text = response.ref.text.cast<ffi.Utf8>();
          final output = text.toDartString(length: text.length);

          responseStreamController.add(
            LLMResult(
              id: '$idPrefix.$tokenCount',
              output: output,
              finishReason: FinishReason.unspecified,
              metadata: {
                'message.id': idPrefix,
                'chunk.id': tokenCount,
                'message.type': 'token',
              },
              usage: const LanguageModelUsage(),
              streaming: true,
            ),
          );
        }
      } on FormatException catch (e, s) {
        if (kDebugMode) {
          debugPrintStack(stackTrace: s, label: e.message);
        }
        try {
          final characters = response.ref.text;
          final length = characters.cast<ffi.Utf8>().length;

          final charList = Uint8List.view(
            characters.cast<Uint8>().asTypedList(length).buffer,
            0,
            length,
          );
          final output = utf8.decode(charList.toList(), allowMalformed: true);

          responseStreamController.add(
            LLMResult(
              id: '$idPrefix.$tokenCount',
              output: output,
              finishReason: FinishReason.unspecified,
              metadata: {
                'message.id': idPrefix,
                'chunk.id': tokenCount,
                'message.type': 'token',
              },
              usage: const LanguageModelUsage(),
              streaming: true,
            ),
          );
        } on Exception catch (e, s) {
          if (kDebugMode) {
            debugPrintStack(stackTrace: s);
          }
        }
      } finally {
        tokenCount++;
        lcpp_free_text(response);
      }
    }

    if (streaming) {
      nativeNewTokenCallable =
          NativeCallable<LppTokenStreamCallbackFunction>.listener(
            onNewTokenCallback,
          );

      nativeNewTokenCallable!.keepIsolateAlive = false;

      lcpp_set_token_stream_callback(nativeNewTokenCallable!.nativeFunction);
    }

    LLMResult result;

    NativeCallable<LppChatMessageCallbackFunction>? chatMessageCallable;
    final completer = Completer();

    void chatMessageCallback(Pointer<lcpp_common_chat_msg_t> message) {
      try {
        final Map<String, dynamic> metadata = Map<String, dynamic>();
        metadata['message.id'] = idPrefix;
        metadata['message.type'] = 'response';

        final output =
            message.ref.n_content > 0
                ? message.ref.content.cast<ffi.Utf8>().toDartString(
                  length: message.ref.n_content,
                )
                : '';
        if (message.ref.n_role > 0) {
          metadata['role'] = message.ref.role.cast<ffi.Utf8>().toDartString(
            length: message.ref.n_role,
          );
        }

        if (message.ref.n_reasoning_content > 0) {
          try {
            metadata['reasoning_content'] = message.ref.reasoning_content
                .cast<ffi.Utf8>()
                .toDartString(length: message.ref.n_reasoning_content);
          } on FormatException catch (e, s) {
            debugPrintStack(stackTrace: s, label: e.message);
          }
        }

        if (message.ref.n_tool_name > 0) {
          try {
            metadata['tool_name'] = message.ref.tool_name
                .cast<ffi.Utf8>()
                .toDartString(length: message.ref.n_tool_name);
          } on FormatException catch (e, s) {
            debugPrintStack(stackTrace: s, label: e.message);
          }
        }

        if (message.ref.n_tool_call_id > 0) {
          try {
            metadata['tool_call_id'] = message.ref.tool_call_id
                .cast<ffi.Utf8>()
                .toDartString(length: message.ref.n_tool_call_id);
          } on FormatException catch (e, s) {
            debugPrintStack(stackTrace: s, label: e.message);
          }
        }

        List<Map<String, String>> content_parts =
            List<Map<String, String>>.empty(growable: true);
        if (message.ref.n_content_parts > 0) {
          final contentPartsPtr = message.ref.content_parts;
          for (int i = 0; i < message.ref.n_content_parts; i++) {
            try {
              Map<String, String> _current = {};
              final it = contentPartsPtr + i;
              if (it.value.ref.n_text > 0) {
                _current['text'] = it.value.ref.text
                    .cast<ffi.Utf8>()
                    .toDartString(length: it.value.ref.n_text);
              }
              if (it.value.ref.n_type > 0) {
                _current['type'] = it.value.ref.type
                    .cast<ffi.Utf8>()
                    .toDartString(length: it.value.ref.n_type);
              }
              if (_current.isNotEmpty) {
                content_parts.add(_current);
              }
            } on FormatException catch (e, s) {
              debugPrintStack(stackTrace: s, label: e.message);
            }
          }
        }

        if (content_parts.isNotEmpty) {
          metadata['content_parts'] = content_parts;
        }

        List<Map<String, String>> tool_calls = List<Map<String, String>>.empty(
          growable: true,
        );
        if (message.ref.n_tool_calls > 0) {
          final tool_calls_ptr = message.ref.tool_calls;
          for (int i = 0; i < message.ref.n_tool_calls; i++) {
            try {
              Map<String, String> _current = {};
              final it = tool_calls_ptr + i;
              if (it.value.ref.n_name > 0) {
                _current['name'] = it.value.ref.name
                    .cast<ffi.Utf8>()
                    .toDartString(length: it.value.ref.n_name);
              }
              if (it.value.ref.n_id > 0) {
                _current['id'] = it.value.ref.id.cast<ffi.Utf8>().toDartString(
                  length: it.value.ref.n_id,
                );
              }
              if (it.value.ref.n_arguments > 0) {
                _current['arguments'] = JsonEncoder().convert(
                  it.value.ref.arguments.cast<ffi.Utf8>().toDartString(
                    length: it.value.ref.n_arguments,
                  ),
                );
              }
              if (_current.isNotEmpty) {
                tool_calls.add(_current);
              }
            } on FormatException catch (e, s) {
              debugPrintStack(stackTrace: s, label: e.message);
            }
          }
        }
        if (tool_calls.isNotEmpty) {
          metadata['tool_calls'] = JsonEncoder().convert(tool_calls);
        }

        result = LLMResult(
          id: idPrefix,
          output: output,
          finishReason:
              tool_calls.isNotEmpty
                  ? FinishReason.toolCalls
                  : FinishReason.stop,
          metadata: metadata,
          usage: const LanguageModelUsage(),
          streaming: false,
        );
        responseStreamController.add(result);
        completer.complete();
      } on FormatException catch (e) {
        // eat exceptions
      } finally {
        if (chatMessageCallable != null) {
          chatMessageCallable!.close();
          lcpp_unset_chat_message_callback();
          chatMessageCallable = null;
        }
        lcpp_free_common_chat_msg(message);
        responseStreamController.close();
      }
    }

    chatMessageCallable =
        NativeCallable<LppChatMessageCallbackFunction>.listener(
          chatMessageCallback,
        );

    lcpp_set_chat_message_callback(chatMessageCallable!.nativeFunction);

    lcpp_prompt(params.toNative(), commonChatMessages, chatMessages.length);

    /// Stream of token responses.
    yield* responseStreamController.stream.map((response) {
      if (response.finishReason == FinishReason.stop ||
          response.finishReason == FinishReason.toolCalls) {
        _responseController.add(response);
      }
      return response;
    });

    commonChatMessages.free(chatMessages.length);
  }

  void stop() {
    if (kDebugMode) {
      print('LlamaCpp::stop()');
    }
    lcpp_send_abort_signal(true);
    if (kDebugMode) {
      print('LlamaCpp::stop:>');
    }
  }

  void cancel() {
    if (kDebugMode) {
      print('LlamaCpp::cancel()');
    }
    lcpp_send_cancel_signal(true);
    if (kDebugMode) {
      print('LlamaCpp::cancel:>');
    }
  }

  String detokenize(List<int> tokens, bool special) {
    final input = ffi.malloc<Int>(tokens.length);
    for (int index = 0; index < tokens.length; index++) {
      input[index] = tokens[index];
    }

    final result = ffi.malloc<lcpp_data_pvalue>();

    lcpp_detokenize(input, tokens.length, special, result);

    final text =
        result.ref.found
            ? result.ref.value.cast<ffi.Utf8>().toDartString()
            : '';

    if (result.ref.found) {
      lcpp_native_free(result.ref.value.cast<Void>());
    }

    ffi.malloc.free(input);
    ffi.malloc.free(result);
    return text;
  }

  List<int> tokenize(String text) {
    final input = text.toNativeUtf8();

    final tokens = ffi.malloc<Pointer<llama_token>>();
    int nTokens = lcpp_tokenize(
      input.cast<Char>(),
      input.length,
      true,
      true,
      tokens,
    );

    final result =
        nTokens > 0
            ? tokens.value.asTypedList(nTokens).toList(growable: false)
            : List<int>.empty(growable: false);
    ffi.malloc.free(tokens);
    ffi.calloc.free(input);
    return result;
  }

  void reset() {
    if (kDebugMode) {
      print('LlamaCpp::reset()');
    }
    lcpp_reset();
    if (kDebugMode) {
      print('LlamaCpp::reset:>');
    }
  }

  void unload() {
    if (kDebugMode) {
      print('LlamaCpp::unload()');
    }
    lcpp_unload();
    if (kDebugMode) {
      print('LlamaCpp::unload:>');
    }
  }

  void destroy() {
    lcpp_destroy();
  }
}
