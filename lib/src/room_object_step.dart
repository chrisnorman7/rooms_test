import 'dart:math';

import 'package:rooms_test/rooms_test.dart';

/// A step for a [RoomObject] to move.
class RoomObjectStep {
  /// Create an instance.
  const RoomObjectStep({
    required this.onStep,
    this.delay = const Duration(seconds: 2),
  });

  /// How long to wait before this move occurs.
  final Duration delay;

  /// A function to be called when this step is taken.
  final void Function(
    RoomScreenState state,
    RoomObject object,
    Point<int> coordinates,
  )
  onStep;
}
