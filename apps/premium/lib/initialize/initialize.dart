import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:june/june.dart';
import 'package:llamacpp/llamacpp.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:serious_python/serious_python.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:unnu_ai_model/unnu_ai_model.dart';
import 'package:unnu_aux/unnu_aux.dart';
import 'package:unnu_common/unnu_common.dart';
import 'package:unnu_dxl/unnu_dxl.dart';
import 'package:unnu_know/unnu_know.dart';
import 'package:unnu_mi5/unnu_mi5.dart';
import 'package:unnu_ragl/unnu_ragl.dart';
import 'package:unnu_sap/unnu_asr.dart';
import 'package:unnu_sap/unnu_tts.dart';
import 'package:unnu_shared/unnu_shared.dart';
import 'package:unnu_speech/unnu_speech.dart';
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
  if (File(filePath).existsSync()) {
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
  )..setChatController(SembastChatController(database));
}

Future<void> registerWebSearchService() async {
  // final envVars = {
  //   'SIMPLEXNG_APP_NAME': 'SearXNG',
  //   'SIMPLEXNG_APP_AUTHOR': 'Konnek Inc',
  //   'SEARXNG_PORT': '11888',
  //   'SEARXNG_HOST': '127.0.0.1',
  // };
  // final app_path = await SeriousPython.run('app/app.zip');

  // print("Starting searxng $app_path");

  final toolsController = June.getState(
    McpToolsController.new,
  );
  await toolsController.insert(Uri.http('127.0.0.1:11888', '/mcp'));
}

Future<void> runInitializaton(Completer<bool> completer) async {
  final statusController = June.getState(InitializationStatusController.new);
  statusController.update((
    name: 'Subsystems',
    status: InitializationStatus.INITIALIZING,
  ));

  final dbCompleter = Completer<bool>();

  final unnuttsInitCompleter = Completer<bool>();
  final unnuasrInitCompleter = Completer<bool>();
  final unnullamaInitCompleter = Completer<bool>();
  final unnudxlInitCompleter = Completer<bool>();
  final unnuragInitCompleter = Completer<bool>();
  final modelRegisteredCompleter = Completer<bool>();
  final modelLoadingCompleter = Completer<bool>();
  final startSearXNGCompleter = Completer<bool>();

  Future<void> dbInit(Completer<bool> _completer) async {
    statusController.update((
      name: 'Chatbot',
      status: InitializationStatus.INITIALIZING,
    ));
    await registerChatDatabase('chat.db');
    _completer.complete(true);
  }

  Future<void> UnnuTtsInit(Completer<bool> _completer) async {
    UnnuTts.init();
    _completer.complete(true);
    statusController.update((
      name: 'TTS',
      status: InitializationStatus.VERIFIED,
    ));
  }

  Future<void> UnnuAsrInit(Completer<bool> _completer) async {
    UnnuAsr.init();
    _completer.complete(true);
    statusController.update((
      name: 'ASR',
      status: InitializationStatus.VERIFIED,
    ));
  }

  Future<void> LlamaCppInit(Completer<bool> _completer) async {
    LlamaCpp.initialize();
    _completer.complete(true);
    statusController.update((
      name: 'AI',
      status: InitializationStatus.VERIFIED,
    ));
  }

  Future<void> UnnuDxlInit(Completer<bool> _completer) async {
    UnnuDxl.init();
    _completer.complete(true);
    statusController.update((
      name: 'DXL',
      status: InitializationStatus.VERIFIED,
    ));
  }

  Future<void> UnnuRAGInit(Completer<bool> _completer) async {
    RagLite.init();
    _completer.complete(true);
    statusController.update((
      name: 'RAG',
      status: InitializationStatus.VERIFIED,
    ));
  }

  // Helper to create and insert the message, ensuring it only happens once.
  Future<void> loadInitialModel(Completer<bool> completer) async {
    final chatSessionController = June.getState(
      ChatSessionController.new,
    );
    final llmProviderController = June.getState(
      LLMProviderController.new,
    );

    final streamingMessageController = June.getState(
      StreamingMessageController.new,
    );

    final ret = await ModelUtils.switchModel(
      UnnuModelDetails(
        info: llmProviderController.activeModel.info,
        specifications: llmProviderController.activeModel.specifications,
      ),
    );
    if (ret == 0) {
      await chatSessionController.newChat();
      await streamingMessageController.newChat();
    }
    completer.complete(true);
  }

  Future<void> startSearXNG(Completer<bool> completer) async {
    statusController.update((
      name: 'Web Search Agent (takes awhile ...)',
      status: InitializationStatus.STARTING,
    ));
    await registerWebSearchService();
    completer.complete(true);
  }

  unawaited(dbInit(dbCompleter));
  unawaited(UnnuTtsInit(unnuttsInitCompleter));
  unawaited(UnnuAsrInit(unnuasrInitCompleter));
  unawaited(LlamaCppInit(unnullamaInitCompleter));
  unawaited(UnnuDxlInit(unnudxlInitCompleter));
  unawaited(UnnuRAGInit(unnuragInitCompleter));
  unawaited(startSearXNG(startSearXNGCompleter));

  await unnuttsInitCompleter.future.whenComplete(
    () async {
      statusController.update((
        name: 'TTS (please wait, takes awhile ...)',
        status: InitializationStatus.CONFIGURING,
      ));
      await UnnuTts.configure(await getOfflineTtsConfig());
      statusController.update((
        name: 'TTS',
        status: InitializationStatus.CONFIGURED,
      ));
    },
  );

  await unnuasrInitCompleter.future.whenComplete(
    () async {
      statusController.update((
        name: 'ASR (also takes awhile ...)',
        status: InitializationStatus.CONFIGURING,
      ));
      await UnnuAsr.configure(
        getOnlineRecognizerConfig(await getOnlineModelConfig()),
        await getVadModelConfig(),
        OnlinePunctuationConfig(
          model: await getOnlinePunctuationModelConfig(),
        ),
      );
      statusController.update((
        name: 'ASR',
        status: InitializationStatus.CONFIGURED,
      ));
    },
  );

  await unnullamaInitCompleter.future.whenComplete(
    () async {
      statusController.update((
        name: 'AI',
        status: InitializationStatus.CONFIGURING,
      ));
      await loadConfiguration();
      statusController.update((
        name: 'AI',
        status: InitializationStatus.VALIDATING,
      ));
      await registerModels();
      modelRegisteredCompleter.complete(true);
      ;
    },
  );

  await unnuragInitCompleter.future.whenComplete(
    () async {
      statusController.update((
        name: 'RAG (may momentarily pause ...)',
        status: InitializationStatus.INITIALIZING,
      ));
      await registerEmbedding('kbase.db');
      statusController.update((
        name: 'RAG',
        status: InitializationStatus.INITIALIZED,
      ));
    },
  );

  await Future.wait(
    [
      dbCompleter.future,
      modelRegisteredCompleter.future,
    ],
    cleanUp: (successValue) => modelLoadingCompleter.complete(false),
  ).whenComplete(
    () async {
      statusController.update((
        name: 'AI (takes very long time ...)',
        status: InitializationStatus.STARTING,
      ));
      await loadInitialModel(modelLoadingCompleter);
    },
  );

  await Future.wait(
    [
      unnuttsInitCompleter.future,
      unnuasrInitCompleter.future,
      unnudxlInitCompleter.future,
      unnuragInitCompleter.future,
      modelLoadingCompleter.future,
      startSearXNGCompleter.future,
    ],
    cleanUp: (successValue) => completer.complete(true),
  ).whenComplete(
    () {
      statusController.update((
        name: 'Application (finishing up takes awhile ...)',
        status: InitializationStatus.STARTING,
      ));
      completer.complete(true);
      statusController.update((
        name: '...',
        status: InitializationStatus.STARTING,
      ));
    },
  );
}
