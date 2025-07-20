import 'dart:math';

import 'package:flutter_audio_games/flutter_audio_games.dart';
import 'package:rooms_test/rooms_test.dart';

/// The type of a function on a [RoomSurface].
typedef RoomSurfaceCallback =
    void Function(RoomWidgetBuilderState state, Point<int> coordinates);

/// A surface in a room.
class RoomSurface {
  /// Create an instance.
  RoomSurface({
    required this.start,
    required this.width,
    required this.depth,
    required this.footstepSoundNames,
    this.movementSpeed = const Duration(milliseconds: 400),
    this.onWall,
    this.onEnter,
    this.onExit,
  });

  /// The start coordinates of this surface.
  final Point<int> start;

  /// The width of this surface.
  final int width;

  /// The depth of this surface.
  final int depth;

  /// The end coordinates of this room.
  Point<int> get end => Point(start.x + width, start.y + depth);

  /// The names of the footstep sounds for this room.
  final List<String> footstepSoundNames;

  /// The footstep sounds for this room.
  List<Sound> get footstepSounds => footstepSoundNames
      .map((final name) => name.asSound(destroy: true))
      .toList();

  /// How fast the player can move on this surface.
  final Duration movementSpeed;

  /// The function to call when the player walks into a wall on this surface.
  ///
  /// A wall is defined as a piece of room where no surfaces have been laid.
  /// The provided coordinates are the coordinates of the wall, not the player.
  final RoomSurfaceCallback? onWall;

  /// The function to call when the player enters this surface.
  final RoomSurfaceCallback? onEnter;

  /// The function to call when the player leaves this surface.
  final RoomSurfaceCallback? onExit;

  /// Returns `true` if `this` surface covers [coordinates].
  bool isCovering(final Point<int> coordinates) =>
      coordinates.x >= start.x &&
      coordinates.x <= end.x &&
      coordinates.y >= start.y &&
      coordinates.y <= end.y;

  /// The coordinates which lie to the north of the northwest corner of this
  /// surface.
  Point<int> get north => Point(start.x, end.y + 1);

  /// The coordinates which lie to the east of the southeast corner of this
  /// surface.
  Point<int> get east => Point(end.x + 1, start.y);

  /// The coordinates which lie to the south of the southwest corner of this
  /// surface.
  Point<int> get south => Point(start.x, start.y - 1);

  /// The coordinates which lie to the west of the southwest corner of this
  /// surface.
  Point<int> get west => Point(start.x - 1, start.y);
}
