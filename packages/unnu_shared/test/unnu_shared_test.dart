import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:unnu_shared/unnu_shared.dart';
import 'package:unnu_shared/src/utils/utils.dart';

void main() {
  test('convert Bytes To Float32', () {
    final bytes = Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0]);
    final values = convertBytesToFloat32(bytes);
    expect(values, Float32List.fromList([0.0, 0.0, 0.0, 0.0]));
  });
}
