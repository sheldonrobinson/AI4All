///
enum TranscriptType {
  START(0),
  CHUNK(1),
  PARTIAL(2),
  FINAL(3),
  END(4);

  final int value;
  const TranscriptType(this.value);

  static TranscriptType fromValue(int value) => switch (value) {
    0 => START,
    1 => CHUNK,
    2 => PARTIAL,
    3 => FINAL,
    4 => END,
    _ =>
    throw ArgumentError('Unknown value for TranscriptType: $value'),
  };
}

/// Transcript type.
typedef Transcript = ({String text, TranscriptType type});