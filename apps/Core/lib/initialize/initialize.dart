import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:june/june.dart';
import 'package:sembast/sembast_io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unnu_ai_model/unnu_ai_model.dart';
import 'package:unnu_shared/unnu_shared.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:unnu_widgets/unnu_widgets.dart';

Future<void> registerModels() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final fileResources = manifest.listAssets().where(
    (value) => value.endsWith('.gguf'),
  );

  final prefs = await SharedPreferences.getInstance();

  final String modelRegistry = prefs.getString('model.registry') ?? '';

  final List<dynamic> registryJsonList =
      modelRegistry.isNotEmpty
          ? jsonDecode(modelRegistry) as List<dynamic>
          : <dynamic>[];

  final registryJson = registryJsonList.map((element)=> LlmMetaInfo.fromJson(element as String));

  final registry = <String, LlmMetaInfo>{};

  for (var model in registryJson) {
    registry[model.nameInNamingConvention] = model;
  }
  final llmProviderController = June.getState(()=>LLMProviderController());
  for (LlmMetaInfo info in registry.values) {
    llmProviderController.register(info);
  }

  for (var model in fileResources) {
    if (kDebugMode) {
      print('model in rootBundle :=$model');
    }
    final info = LLMProviderController.asLlMetaInfo(
      model,
      resource: LlmResource.AssetBundle,
    );
    if (!registry.containsKey(info.nameInNamingConvention)) {
      llmProviderController.register(info);
    }
  }

  final String activeModel = prefs.getString('model.active') ?? '';

  final modelInfo = LlmMetaInfo.fromMap(
    activeModel.isNotEmpty
        ? jsonDecode(activeModel) as Map<String, dynamic>
        : <String, dynamic>{},
  );

  if (modelInfo.filePath.isEmpty) {
    final sysModels =
        llmProviderController.models
            .where((value) => value.location == LlmResource.AssetBundle)
            .toList();
    sysModels.sort((a, b) => a.vram.compareTo(b.vram));
    llmProviderController.activeModel = llmProviderController.activeModel
        .copyWith(info: sysModels.first);
  } else {
    llmProviderController.activeModel = llmProviderController.activeModel
        .copyWith(info: modelInfo);
  }
  llmProviderController.setState();
}

Future<void> registerChatDatabase(String? dbFileName) async {
  sqflite_ffi.sqfliteFfiInit();
  final DatabaseFactory factory =
      Platform.isAndroid ||
              Platform.isIOS ||
              Platform.isFuchsia ||
              Platform.isMacOS
          ? getDatabaseFactorySqflite(sqflite.databaseFactory)
          : getDatabaseFactorySqflite(sqflite_ffi.databaseFactoryFfi);

  String dbUrl = '';
  if (dbFileName != null) {
    final filePath = await absoluteApplicationSupportPath(dbFileName);
    dbUrl += filePath;
  } else {
    dbUrl += 'file:chatdb?mode=memory&cache=shared';
  }

  final database = await factory.openDatabase(dbUrl);

  final streamingMessageController = June.getState(() => StreamingMessageController());
  streamingMessageController.setChatController(SembastChatController(database));
}
