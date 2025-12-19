import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import 'package:june/june.dart';
import 'package:mcp_dart/mcp_dart.dart' as mcp_dart;
import 'package:uuid/uuid.dart';

// typedef McpClientImpl = ({mcp_dart.Client client, mcp_dart.Transport transport});

class ToolId {
  final String name;
  final String reference_id;
  ToolId({required this.name, required this.reference_id});

  ToolId copyWith({String? name, String? reference_id}) {
    return ToolId(
      name: name ?? this.name,
      reference_id: reference_id ?? this.reference_id,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'name': name});
    result.addAll({'reference_id': reference_id});

    return result;
  }

  factory ToolId.fromMap(Map<String, dynamic> map) {
    return ToolId(name: map['name'] ?? '', reference_id: map['reference_id'] ?? '');
  }

  String toJson() => json.encode(toMap());

  factory ToolId.fromJson(String source) => ToolId.fromMap(json.decode(source));

  @override
  String toString() => 'ToolId(name: $name, reference_id: $reference_id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ToolId &&
        other.name == name &&
        other.reference_id == reference_id;
  }

  @override
  int get hashCode => name.hashCode ^ reference_id.hashCode;
}

class ActiveTool {
  final ToolId tool;
  final String id;
  ActiveTool({
    required this.tool,
    required this.id,
  });
  

  ActiveTool copyWith({
    ToolId? tool,
    String? id,
  }) {
    return ActiveTool(
      tool: tool ?? this.tool,
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
  
    result.addAll({'tool': tool.toMap()});
    result.addAll({'id': id});
  
    return result;
  }

  factory ActiveTool.fromMap(Map<String, dynamic> map) {
    return ActiveTool(
      tool: ToolId.fromMap(map['tool']),
      id: map['id'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory ActiveTool.fromJson(String source) => ActiveTool.fromMap(json.decode(source));

  @override
  String toString() => 'ActiveTool(tool: $tool, id: $id)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is ActiveTool &&
      other.tool == tool &&
      other.id == id;
  }

  @override
  int get hashCode => tool.hashCode ^ id.hashCode;
}

class McpToolsController extends JuneState {
  final SessionsWithTools = <ActiveTool>{};
  final ClientRegistry = <Uri, mcp_dart.Client>{};
  final ToolRegistry = <ToolId, mcp_dart.Tool>{};
  final sessionId = Uuid().v4();

  Future<void> insert(Uri uri) async {
    if (!ClientRegistry.containsKey(uri)) {
      final mcpClient = mcp_dart.Client(
        mcp_dart.Implementation(name: uri.toString(), version: '1.0.0'),
      );
      final mcpServertransport = mcp_dart.StreamableHttpClientTransport(uri,
      opts: mcp_dart.StreamableHttpClientTransportOptions(
          sessionId: sessionId,
      ));
      mcpServertransport.onerror = (error) {
        print("Transport error for $uri: $error");
      };
      mcpServertransport.onclose = () {
        if (kDebugMode) {
          print("Transport closed for $uri.");
        }
      };

      mcpClient.onerror = (error) {
        if (kDebugMode) {
          print('\x1b[31mClient error for uri: $error\x1b[0m');
        }
      };
      await mcpClient.connect(mcpServertransport);

      ClientRegistry.putIfAbsent(uri, () => mcpClient);
    }
    final client =
        ClientRegistry[uri] ??
        mcp_dart.Client(
          mcp_dart.Implementation(name: uri.toString(), version: '1.0.0'),
        );

    try {
      final toolsResult = await client.listTools();
      for (final tool in toolsResult.tools) {
        final id = ToolId(name: tool.name, reference_id: uri.toString());
        ToolRegistry.putIfAbsent(id, () => tool);
        if (kDebugMode) {
          print('  - $id: ${tool.description}');
        }
      }
    } on Exception catch (error) {
      if (kDebugMode) {
        print('Tools not supported by this server $uri ($error)');
      }
    }
    setState();
  }

  Future<void> register(Uri uri, String toolName, String referenceId) async{
    if(!ClientRegistry.containsKey(uri)){
      await insert(uri);
    }
    final id = ToolId(name: toolName, reference_id: uri.toString());
    if(ToolRegistry.containsKey(id)){
      SessionsWithTools.add(ActiveTool(tool: id, id: referenceId));
    }
    setState();
  }

  Future<void> registerAll(List<ToolId> listOfTools, String referenceId) async{
    for(final tool in listOfTools){
      final uri = Uri.tryParse(tool.reference_id) ?? Uri();
      if(!uri.hasEmptyPath){
        await register(uri,tool.name, referenceId);
      }
    }
    setState();
  }

  Future<void> registerLocal(String referenceId) async{
    for(final tool in ToolRegistry.keys){
      final uri = Uri.tryParse(tool.reference_id) ?? Uri();
      if(uri.host == "localhost" || uri.host == "127.0.0.1"){
        SessionsWithTools.add(ActiveTool(tool: tool, id: referenceId));
      }
    }
  }

  Future<void> unregisterAll(List<ToolId> listOfTools, String referenceId) async{
    for(final tool in listOfTools){
      final uri = Uri.tryParse(tool.reference_id) ?? Uri();
      if(!uri.hasEmptyPath){
        await unregister(uri,tool.name, referenceId);
      }
    }
  }

  Future<void> unregister(Uri uri, String toolName, String referenceId) async {
    final id = ToolId(name: toolName, reference_id: uri.toString());
    SessionsWithTools.remove(ActiveTool(tool: id, id: referenceId));
    setState();
  }

  Future<void> remove(Uri uri) async {
    final val = uri.toString();
    final entries = ToolRegistry.entries.where((element) => element.key.reference_id == val).map((e) => e.key,).toSet();
    ToolRegistry.removeWhere((key, value) => entries.contains(key),);
    SessionsWithTools.removeWhere((element) => entries.contains(element.tool),);
    final client = ClientRegistry[uri]??
        mcp_dart.Client(
          mcp_dart.Implementation(name: uri.toString(), version: '1.0.0'),
        );
    await client.close();
    ClientRegistry.remove(uri);
    setState();
  }

  Future<void> closeAll() async {
    for (final impl in ClientRegistry.values) {
      await impl.close();
    }
    ClientRegistry.clear();
    ToolRegistry.clear();
    SessionsWithTools.clear();
  }

  Map<String, List<ActiveTool>> get actives =>  groupBy<ActiveTool, String>(SessionsWithTools, (entry) => entry.id);

  Map<Uri, List<ToolId>> get tools => groupBy<ToolId, Uri>(ToolRegistry.keys, (entry) => Uri.tryParse(entry.reference_id) ?? Uri());
}
