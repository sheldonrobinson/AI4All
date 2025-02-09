// Copyright (c) 2025, Konnek

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle, AssetManifest, PlatformException;
import "dart:io";
import 'package:large_file_handler/large_file_handler.dart';

Future<String> copyAssetOnMobile(String src) async {

  final Directory directory = await getApplicationDocumentsDirectory();

  final parts = src.split('/');

  final modelFileRelPath = p.joinAll(parts);

  final modelFileAbsPath = p.join(directory.path, modelFileRelPath);

  final localfile = src.substring('assets/'.length);

  final dst = p.dirname(modelFileAbsPath);

  bool exists = await Directory(dst).exists();
  if (!exists) {
    if (kDebugMode) {
      print('copyAssetFile:create $dst');
    }
    await Directory(dst).create(recursive: true);
  }

  exists = await File(modelFileAbsPath).exists();
  if (!exists) {
    try {
      Stream<int> progressStream = LargeFileHandler()
          .copyAssetToLocalStorageWithProgress(
        assetName: src,
        targetPath: localfile,
      );
      progressStream.listen(
            (progress) {
          if (kDebugMode) {
            print('copied number of models: $progress');
          }
        },
        onDone: () {
          if (kDebugMode) {
            print('File copied successfully to $localfile');
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print('Failed to copy asset: $error');
          }
        },
      );
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('Failed to copy asset: ${e.message}');
      }
    }
  }
  return Future.value(modelFileAbsPath);
}

// Copy the asset file from src to dst.
// If dst already exists, then just skip the copy
Future<String> copyAssetFile(String src, [String? dst]) async {
  if (kDebugMode) {
    print('copyAssetFile($src)');
  }
  final parts = src.split('/');
  final srcFormated = p.joinAll(parts);
  if (dst == null) {
    final Directory directory = await getApplicationSupportDirectory();
    if (kDebugMode) {
      print('copyAssetFile: directory=$directory');
    }
    final dirname = p.dirname(srcFormated);

    dst ??= p.join(directory.path, dirname);
  }
  if (kDebugMode) {
    print('copyAssetFile: dst=$dst');
  }

  bool exists = await Directory(dst).exists();
  if (!exists) {
    if (kDebugMode) {
      print('copyAssetFile:create $dst');
    }
    await Directory(dst).create(recursive: true);
  }

  final target = p.join(dst, p.basename(srcFormated));
  if (kDebugMode) {
    print('copyAssetFile: target=$target');
  }
  exists = await File(target).exists();

  final data = rootBundle.load(src).then<String>((value) async {
    final completer = Completer<String>();
    final newLength = value.lengthInBytes;
    if (!exists || File(target).lengthSync() != newLength) {

      final bytes = value.buffer.asUint8List(
        value.offsetInBytes,
        value.lengthInBytes,
      );

      await File(target).writeAsBytes(bytes).whenComplete(() {
        completer.complete(target);
      });
    } else {
      completer.complete(target);
    }
    return completer.future;
  });

  return data;
}

Float32List convertBytesToFloat32(Uint8List bytes, [endian = Endian.little]) {
  final values = Float32List(bytes.length ~/ 2);

  final data = ByteData.view(bytes.buffer);

  for (var i = 0; i < bytes.length; i += 2) {
    int short = data.getInt16(i, endian);
    values[i ~/ 2] = short / 32678.0;
  }

  return values;
}

// https://stackoverflow.com/questions/68862225/flutter-how-to-get-all-files-from-assets-folder-in-one-list
Future<List<String>> getAllAssetFiles() async {
  if (kDebugMode) {
    print('getAllAssetFiles()');
  }
  final AssetManifest assetManifest = await AssetManifest.loadFromAssetBundle(
    rootBundle,
  );
  final List<String> assets = assetManifest.listAssets();
  if (kDebugMode) {
    print('getAllAssetFiles:=> $assets');
  }
  return assets;
}

String stripLeadingDirectory(String src, {int n = 1}) {
  return p.joinAll(p.split(src).sublist(n));
}

Future<void> copyAllAssetFiles() async {
  if (kDebugMode) {
    print('copyAllAssetFiles()');
  }
  final allFiles = await getAllAssetFiles();
  final Directory directory = await getApplicationSupportDirectory();
  if (kDebugMode) {
    print('copyAllAssetFiles: directory=$directory');
  }
  for (final src in allFiles) {
    final dst = p.dirname(stripLeadingDirectory(src));
    await copyAssetFile(src, p.join(directory.path, dst));
  }
  if (kDebugMode) {
    print('copyAllAssetFiles:=> void');
  }
}

String topLevelDirectory(String src, {int n = 1}) {
  return p.joinAll(p.split(src).sublist(0, n));
}

Future<String> absoluteApplicationSupportPath(String? relpath) async {
  final Directory directory = await getApplicationSupportDirectory();
  if (kDebugMode) {
    print('AppDir relpath: null  := ${p.join(directory.path, null)}');
    print('AppDir relpath: ${relpath} := ${p.join(directory.path, relpath)}');
  }
  return p.join(directory.path, relpath);
}

Future<String> copyAssetDirectory(String dir, [String? dst]) async {
  if (kDebugMode) {
    print('copyAssetDirectory($dir)');
  }
  final srcdir = dir.endsWith('/') ? dir : '$dir/';
  if (kDebugMode) {
    print('copyAssetDirectory: srcdir=$srcdir');
  }
  if (dst == null) {
    final Directory directory = await getApplicationSupportDirectory();
    if (kDebugMode) {
      print('copyAssetDirectory: directory=$directory');
    }
    dst ??= p.join(directory.path, srcdir);
  }
  if (kDebugMode) {
    print('copyAssetDirectory: dst=$dst');
  }
  final target = dst;
  if (kDebugMode) {
    print('copyAssetDirectory: target=$target');
  }
  bool exists = await Directory(target).exists();
  if (!exists) {
    if (kDebugMode) {
      print('copyAssetDirectory: create $target');
    }
    await Directory(target).create(recursive: true);
  }
  final allFiles = await getAllAssetFiles();
  for (final src in allFiles) {
    if (src.startsWith(srcdir)) {
      if (kDebugMode) {
        print('copyAssetDirectory: copying $src');
      }
      dst = p.dirname(src.substring(srcdir.length));
      final filedir = p.join(target, dst);
      if (kDebugMode) {
        print('copyAssetDirectory: filedir:=$filedir');
      }
      exists = await Directory(filedir).exists();
      if (!exists) {
        if (kDebugMode) {
          print('copyAssetDirectory: creating filedir:=$filedir');
        }
        await Directory(filedir).create(recursive: true);
      }
      await copyAssetFile(src, filedir);
    }
  }
  if (kDebugMode) {
    print('copyAssetDirectory:=> $target');
  }
  return target;
}
