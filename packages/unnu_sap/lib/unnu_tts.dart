library unnu_tts;

import 'dart:ffi';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';

import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/foundation.dart';
import 'package:unnu_sap/src/tts/bindings.dart';

import 'src/common/models.dart';

export 'src/common/models.dart'
    show
        OfflineTtsVitsModelConfig,
        OfflineTtsMatchaModelConfig,
        OfflineTtsKokoroModelConfig,
        OfflineTtsModelConfig,
        OfflineTtsConfig;

part 'src/tts/unnu_tts.dart';

