import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:june/june.dart';
import 'package:llamacpp/llamacpp.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:unnu_ai_model/unnu_ai_model.dart';
import 'package:unnu_aux/unnu_aux.dart';
import 'package:unnu_know/unnu_know.dart';
import 'package:unnu_ragl/unnu_ragl.dart';
import 'package:unnu_shared/unnu_shared.dart';
import 'package:unnu_widgets/unnu_widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

Future<void> loadConfiguration() async {
  final configurationController = June.getState(
    ConfigurationController.new,
  );
  await configurationController.read();
}

Future<void> registerModels() async {
  final configurationController = June.getState(
    ConfigurationController.new,
  );

  final llmProviderController = June.getState(LLMProviderController.new);

  configurationController.config.models.forEach(
        (key, value) async =>
    await llmProviderController.hydrateModelSettings(value),
  );

  const uuid = Uuid();
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final fileResources = manifest.listAssets().firstWhere(
    (value) => value.endsWith('.gguf'),
  );
  final pkgInfo = await PackageInfo.fromPlatform();

  final uri =
      Uri(
        scheme: 'appbundle',
        host: pkgInfo.packageName,
        path: fileResources,
        queryParameters: <String, String>{
          'version': pkgInfo.version,
        },
      ).toString();
  final defaultSettings = UnnuModelSettings(
    uri: uri,
    id: uuid.v4(),
    location: fileResources,
    path: '',
    type: 'gguf.file',
    sha: '',
  );
  final appModel = configurationController.config.models.putIfAbsent(
    uri,
    () => defaultSettings,
  );

  final prefs = await SharedPreferences.getInstance();

  final activeModel =
      configurationController.config.models[prefs.getString('model.active') ??
          uri] ??
      appModel;
  final details =
      activeModel.path.isEmpty
          ? await llmProviderController.hydrateModelSettings(activeModel)
          : await UnnuModelDetails.trySettings(activeModel);

  llmProviderController
    ..activeModel = llmProviderController.activeModel.copyWith(
      uri: uri,
      info: details.info,
      specifications: details.specifications,
      contextParams: ContextParams.defaultParams().copyWith(
        nCtx: details.specifications.n_ctx,
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
        nGpuLayers: details.specifications.n_layers ?? 99,
        splitMode: lcpp_split_mode.LCPP_SPLIT_MODE_LAYER,
        mainGPU: 0,
        useMmap: true,
        useMlock: true,
      ),
    )
    ..setState();
}

Future<void> registerEmbedding(String? kbFileName) async {
  final directory = await getApplicationSupportDirectory();

  final dstDir = p.joinAll([
    directory.path,
    'assets',
    'models',
    'embedding',
    'granite-embedding-107m-multilingual-ct2-int8',
  ]);

  const modelDir =
      'assets/models/embedding/granite-embedding-107m-multilingual-ct2-int8';

  final dst =
      Platform.isAndroid || Platform.isIOS
          ? await copyAssetDirectoryMobile(modelDir)
          : await copyAssetDirectory(modelDir, dstDir);

  RagLite.configure(dst);

  final doc = await File(
    p.join(dst, 'properties.yaml'),
  ).readAsString().then(loadYaml);
  final properties = doc as YamlMap;

  RagLite.instance.enableParagraphChunking(
    (properties['paragraph_chunking'] ?? true) as bool,
  );
  RagLite.instance.setChunkSize(
    (properties['chunk_size'] ?? properties['embedding_size'] ?? 1024) as int,
  );
  RagLite.instance.setEmbeddingSize(
    (properties['embedding_size'] ?? 384) as int,
  );

  final k = (properties['result_limit'] ?? 1) as int;
  RagLite.instance.setResultSize(
    k,
  );

  UnnuKnow.instance.limit = k;

  RagLite.instance.setPoolingType(
    (properties['pooling_type'] ?? 0) as int,
  );

  var dbUrl = '';
  if (kbFileName != null) {
    final filePath = await absoluteApplicationSupportPath(kbFileName);
    dbUrl += filePath;
  } else {
    dbUrl += 'file:kbase?mode=memory&cache=shared';
  }
  RagLite.setup(kb: dbUrl);

  final settingsController = June.getState(
    ChatSettingsController.new,
  );

  final filePath = await absoluteApplicationSupportPath('conversations.yml');
  if(File(filePath).existsSync()) {
    await settingsController.load(filePath);
  }

  UnnuKnow.instance.init();
}

Future<void> registerChatDatabase(String? dbFileName) async {
  sqflite_ffi.sqfliteFfiInit();
  final factory =
      Platform.isAndroid ||
              Platform.isIOS ||
              Platform.isFuchsia ||
              Platform.isMacOS
          ? getDatabaseFactorySqflite(sqflite.databaseFactory)
          : getDatabaseFactorySqflite(sqflite_ffi.databaseFactoryFfi);

  var dbUrl = '';
  if (dbFileName != null) {
    final filePath = await absoluteApplicationSupportPath(dbFileName);
    dbUrl += filePath;
  } else {
    dbUrl += 'file:chatdb?mode=memory&cache=shared';
  }

  final database = await factory.openDatabase(dbUrl);

  final _ = June.getState(
    StreamingMessageController.new,
  )
  ..setChatController(SembastChatController(database));
}
