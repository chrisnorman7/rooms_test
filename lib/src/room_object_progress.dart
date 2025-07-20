import 'package:rooms_test/rooms_test.dart';

/// The progress of a [RoomObject] through its steps.
class RoomObjectProgress {
  /// Create an instance.
  RoomObjectProgress({required this.lastMoved, required this.currentStep});

  /// The time the object last moved.
  DateTime lastMoved;

  /// The index of the current step.
  int currentStep;
}
