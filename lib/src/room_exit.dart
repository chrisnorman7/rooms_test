import 'dart:math';

import 'package:flutter_audio_games/flutter_audio_games.dart';
import 'package:rooms_test/rooms_test.dart';

/// An exit between two rooms.
///
/// Instances of this class can be used with any of [RoomObject]'s `on*`
/// methods.
class RoomExit {
  /// Create an instance.
  const RoomExit({required this.setRoom, this.useSound});

  /// The function to call to change to a new room.
  final void Function(RoomWidgetBuilderState state, Point<int> coordinates)
  setRoom;

  /// The sound to play when this exit is used.
  final Sound? useSound;

  /// Use this exit.
  void use(final RoomWidgetBuilderState state, final Point<int> coordinates) {
    final sound = useSound;
    if (sound != null) {
      state.context.playSound(sound);
    }
    setRoom(state, coordinates);
  }
}
