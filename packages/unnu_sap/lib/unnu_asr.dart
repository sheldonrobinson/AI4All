library unnu_asr;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart' as ffi;
import 'package:flutter/foundation.dart';
import 'package:unnu_sap/src/asr/bindings.dart';

import 'src/common/models.dart';
import 'src/common/types.dart';

export 'src/common/types.dart' show TranscriptType, Transcript;

export 'src/common/models.dart'
    show
        FeatureConfig,
        OnlineTransducerModelConfig,
        OnlineParaformerModelConfig,
        OnlineZipformer2CtcModelConfig,
        OnlineModelConfig,
        OnlineCtcFstDecoderConfig,
        OnlineRecognizerConfig,
        SileroVadModelConfig,
        VadModelConfig,
        OnlinePunctuationModelConfig,
        OnlinePunctuationConfig;

part 'src/asr/unnu_asr.dart';
